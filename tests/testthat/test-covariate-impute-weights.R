local_edition(3)

test_that("equal weights preserve defaults and named overrides select donors", {
  d <- data.frame(y = c(10, 20, NA), x = c(0, 2, 0), z = c(1, 0, 0))
  for (distance in c("euclidean", "gower")) {
    original <- impute_ml(d, "y", k = 1, distance = distance)
    expect_identical(original$y, c(10, 20, 10))
    for (weights in list(NULL, numeric(0), c(z = 1, x = 1, y = 9))) {
      expect_identical(
        impute_ml(d, "y", k = 1, distance = distance, weights = weights),
        original
      )
    }
    expect_equal(
      impute_ml(d, "y", k = 1, distance = distance, weights = c(z = 9))$y[3],
      20
    )
    # Predictor weights do not weight the mean of the selected neighbors.
    expect_equal(
      impute_ml(d, "y", k = 2, distance = distance, weights = c(z = 9))$y[3],
      15
    )
  }
  # The weight multiplies the squared difference, not the raw difference.
  expect_equal(impute_ml(d, "y", k = 1, weights = c(z = 3))$y[3], 10)
})

test_that("weighted Euclidean distances match hand calculations", {
  deltas <- rbind(c(3, 4), c(0, 2), c(0, 0))
  weights <- c(4, 9)
  expected <- c(sqrt(4 * 9 + 9 * 16), sqrt(9 * 4), 0)
  actual <- PharmaStatsR:::imputation_distances(deltas, "y", weights)
  # A common scale factor preserves the donor ordering.
  expect_equal(actual * sqrt(max(weights)), expected)
})

test_that("weighted Gower averages use only jointly observed predictors", {
  d <- data.frame(x = c(0, 10, 2), group = c("a", NA, "b"))
  prepared <- PharmaStatsR:::prepare_gower_predictors(d)
  expect_equal(
    PharmaStatsR:::gower_imputation_distances(prepared, 1:2, 3, c(1, 3)),
    c((0.2 + 3) / 4, 0.8)
  )
  # Zero weights cannot make otherwise incomparable pairs usable.
  expect_equal(
    PharmaStatsR:::gower_imputation_distances(prepared, 1:2, 3, c(0, 3)),
    c(1, NA_real_)
  )
  d$y <- c(10, 20, NA)
  expect_equal(
    impute_ml(d, "y", k = 1, distance = "gower", weights = c(group = 4))$y[3],
    20
  )
})

test_that("weighted mixed-data distances agree with cluster daisy", {
  skip_if_not_installed("cluster")
  set.seed(42)
  d <- data.frame(
    numeric = rnorm(12), constant = 7,
    nominal = factor(rep(c("a", "b", "c"), 4)),
    character = rep(c("alpha", "beta"), 6),
    binary = rep(c(FALSE, TRUE), 6),
    ordinal = ordered(rep(c("low", "medium", "high"), 4),
      levels = c("low", "medium", "high", "unused")
    )
  )
  for (j in seq_along(d)) {
    d[[j]][j] <- NA
  }
  d[12, ] <- NA
  weights <- c(0.25, 2, 0, 5, 3, 7)
  reference_data <- d
  reference_data$character <- factor(reference_data$character)
  reference_data$binary <- factor(d$binary, levels = c(FALSE, TRUE))
  reference <- as.matrix(cluster::daisy(
    reference_data,
    metric = "gower", weights = weights
  ))
  prepared <- PharmaStatsR:::prepare_gower_predictors(d)
  for (recipient in seq_len(nrow(d))) {
    donors <- setdiff(seq_len(nrow(d)), recipient)
    expect_equal(
      PharmaStatsR:::gower_imputation_distances(
        prepared, donors, recipient, weights
      ),
      unname(reference[donors, recipient]),
      tolerance = 1e-12
    )
  }
})

test_that("relative weights tolerate large and tiny common scales", {
  d <- data.frame(y = c(10, 20, NA), x = c(0, 2, 0), z = c(1, 0, 0))
  for (distance in c("euclidean", "gower")) {
    for (scale in c(1, 1e307, 1e-300)) {
      expect_equal(
        impute_ml(d, "y", 1,
          distance = distance,
          weights = c(x = 1, z = 9) * scale
        )$y[3],
        20
      )
    }
  }
  # A tiny weight is still meaningful if it is the only available comparison.
  prepared <- PharmaStatsR:::prepare_gower_predictors(
    data.frame(x = c(0, 10, 2), group = c(NA, "b", "a"))
  )
  expect_equal(
    PharmaStatsR:::gower_imputation_distances(
      prepared, 1:2, 3, c(1e-300, 1e300)
    ),
    c(0.2, 1)
  )
  d <- data.frame(y = c(10, 20, NA), x = c(1e300, 1e299, 0), z = 0)
  expect_equal(
    impute_ml(d, "y", 1, weights = c(x = 1e-300, z = 1e300))$y[3], 20
  )
})

test_that("zero-weight predictors are excluded before value validation", {
  d <- data.frame(y = c(10, 20, NA), x = c(0, 10, 0), ignored = Inf)
  d$notes <- I(list(1, "b", NULL))
  expected <- d
  expected$y[3] <- 10
  for (distance in c("euclidean", "gower")) {
    expect_identical(
      impute_ml(d, "y", 1,
        distance = distance,
        weights = c(ignored = 0, notes = 0)
      ),
      expected
    )
    expect_warning(
      result <- impute_ml(d, "y",
        distance = distance,
        weights = c(x = 0, ignored = 0, notes = 0)
      ),
      "No predictor columns available for 'y'"
    )
    expect_identical(result, d)
    expect_identical(
      impute_ml(expected, "y",
        distance = distance,
        weights = c(x = 0, ignored = 0, notes = 0)
      ),
      expected
    )
  }
})

test_that("weights match literal names and exclude each current target", {
  d <- data.frame(
    a = c(10, 20, NA), b = c(0, NA, 2), x = c(0, 10, 0),
    row.names = c("first", "second", "third")
  )
  names(d) <- c("target value", "other + target", "body mass")
  original <- d
  expected <- d
  expected[[1]][3] <- 10
  expected[[2]][2] <- 0
  weights <- c("body mass" = 2, "other + target" = 5, "target value" = 0)
  for (distance in c("euclidean", "gower")) {
    for (targets in list(names(d)[1:2], names(d)[2:1])) {
      expect_identical(
        impute_ml(d, targets, 1,
          predictors = rev(names(d)),
          distance = distance, weights = weights
        ),
        expected
      )
    }
    # A weight on the target itself must not change the neighbor comparison.
    single <- d[c(1, 3)]
    result <- impute_ml(single, names(d)[1], 1,
      distance = distance,
      weights = c("target value" = 1e308, "body mass" = 1)
    )
    expect_identical(result, expected[c(1, 3)])
  }
  expect_identical(d, original)
})

test_that("weighted selection preserves categorical targets and mode ties", {
  d <- data.frame(
    y = factor(c("a", "b", NA), levels = c("a", "b", "unused")),
    x = c(0, 2, 0), z = c(1, 0, 0)
  )
  expected <- d
  expected$y[3] <- "b"
  for (distance in c("euclidean", "gower")) {
    for (k in c(1, 2)) {
      expect_identical(
        impute_ml(d, "y", k, distance = distance, weights = c(z = 9)),
        expected
      )
    }
  }
})

test_that("invalid weights fail even when imputation is unnecessary", {
  d <- data.frame(y = 1:3, x = 4:6, z = 7:9)
  invalid <- list(
    c(x = -1), c(x = Inf), c(x = NA_real_), c(x = NaN),
    c(x = TRUE), c(x = "1"), c(x = 1 + 1i), list(x = 1),
    matrix(1), character(0)
  )
  for (weights in invalid) {
    expect_error(
      impute_ml(d, "y", weights = weights),
      "numeric vector of finite, nonnegative values"
    )
  }
  invalid_names <- list(
    1, c(x = 1, x = 2), c(x = 1, 2),
    stats::setNames(1, NA_character_)
  )
  for (weights in invalid_names) {
    expect_error(
      impute_ml(d, "y", weights = weights),
      "unique, nonmissing, nonempty predictor names"
    )
  }
  expect_error(
    impute_ml(d, "y", weights = c(unknown = 1)),
    "unselected predictors: unknown"
  )
  expect_error(
    impute_ml(d, "y", predictors = "x", weights = c(z = 1)),
    "unselected predictors: z"
  )
  expect_error(impute_ml(d, character(0), weights = c(x = -1)), "nonnegative")
  expect_identical(impute_ml(d[FALSE, ], "y", weights = c(x = 2)), d[FALSE, ])
})
