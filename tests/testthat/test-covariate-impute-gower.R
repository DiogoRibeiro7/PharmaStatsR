local_edition(3)

test_that("Gower contributions match a hand-calculated mixed-type example", {
  predictors <- data.frame(
    numeric = c(0, 10, 2), nominal = factor(c("a", "b", "a")),
    binary = c(FALSE, TRUE, FALSE),
    ordinal = ordered(c("low", "medium", "high"),
      levels = c("low", "medium", "high")
    )
  )
  prepared <- PharmaStatsR:::prepare_gower_predictors(predictors)
  actual <- PharmaStatsR:::gower_imputation_distances(prepared, 1:2, 3)
  expect_equal(actual, c((0.2 + 0 + 0 + 1) / 4, (0.8 + 1 + 1 + 0.5) / 4))
  d <- data.frame(y = c(10, 20, NA), predictors)
  expect_identical(
    impute_ml(d, "y", k = 1, distance = "gower")$y,
    c(10, 20, 10)
  )
  expect_identical(
    impute_ml(d, "y", k = 2, distance = "gower")$y,
    c(10, 20, 15)
  )
})

test_that("Gower distances agree with an independent mixed-data reference", {
  skip_if_not_installed("cluster")
  set.seed(42)
  predictors <- data.frame(
    numeric = rnorm(12), constant = 7,
    nominal = factor(rep(c("a", "b", "c"), 4)),
    character = rep(c("alpha", "beta"), 6),
    binary = rep(c(FALSE, TRUE), 6),
    ordinal = ordered(rep(c("low", "medium", "high"), 4),
      levels = c("low", "medium", "high", "unused")
    )
  )
  for (j in seq_along(predictors)) {
    predictors[[j]][j] <- NA
  }
  predictors[12, ] <- NA
  reference_data <- predictors
  reference_data$character <- factor(reference_data$character)
  # Nominal coding explicitly requests symmetric logical comparisons.
  reference_data$binary <- factor(
    reference_data$binary,
    levels = c(FALSE, TRUE)
  )
  reference <- as.matrix(cluster::daisy(reference_data, metric = "gower"))
  prepared <- PharmaStatsR:::prepare_gower_predictors(predictors)
  for (recipient in seq_len(nrow(predictors))) {
    donors <- setdiff(seq_len(nrow(predictors)), recipient)
    expect_equal(
      PharmaStatsR:::gower_imputation_distances(prepared, donors, recipient),
      unname(reference[donors, recipient]),
      tolerance = 1e-12
    )
  }
})

test_that("nominal factor ordering does not change Gower donor selection", {
  d <- data.frame(y = c(10, 20, NA), group = factor(c("b", "c", "a")))
  expect_equal(impute_ml(d, "y", k = 1)$y[3], 10)
  expect_equal(impute_ml(d, "y", k = 1, distance = "gower")$y[3], 10)
  d$group <- factor(d$group, levels = c("b", "c", "a"))
  expect_equal(impute_ml(d, "y", k = 1, distance = "euclidean")$y[3], 20)
  expect_equal(impute_ml(d, "y", k = 1, distance = "gower")$y[3], 10)
  d$group <- c("zebra", "apple", "orange")
  expect_equal(impute_ml(d, "y", k = 1, distance = "gower")$y[3], 10)
})

test_that("Gower numeric comparisons are invariant to unit changes", {
  d <- data.frame(y = c(10, 20, NA), x = c(0, 10, 2), z = c(0, 1000, 900))
  for (scale in c(1, 1e6, 1e-200)) {
    scaled <- d
    scaled$x <- scaled$x * scale
    expect_equal(impute_ml(scaled, "y", k = 1, distance = "gower")$y[3], 20)
  }
  extremes <- list(
    c(-1e308, 1e308, 9e307), c(0, 1e-300, 9e-301),
    c(-2147483647L, 2147483647L, 2000000000L)
  )
  for (values in extremes) {
    extreme <- data.frame(y = c(10, 20, NA), x = values)
    expect_equal(impute_ml(extreme, "y", k = 1, distance = "gower")$y[3], 20)
  }
})

test_that("Gower uses ordered levels and symmetric logical matches", {
  d <- data.frame(
    y = c(10, 20, NA),
    stage = ordered(c("low", "medium", "high"),
      levels = c("unused", "low", "medium", "high")
    )
  )
  expect_equal(impute_ml(d, "y", k = 1, distance = "gower")$y[3], 20)
  d$stage <- factor(d$stage, ordered = FALSE)
  expect_equal(impute_ml(d, "y", k = 1, distance = "gower")$y[3], 10)
  d$stage <- c(TRUE, FALSE, FALSE)
  expect_equal(impute_ml(d, "y", k = 1, distance = "gower")$y[3], 20)
})

test_that("missing predictor pairs exclude incomparable donors", {
  d <- data.frame(
    y = c(10, 20, NA_real_, NaN, NA_real_),
    x = c(0, NA, NA, NA, 0), group = c(NA, "a", NA, NA, NA)
  )
  expected <- d
  expected$y[5] <- 10
  expect_warning(
    result <- impute_ml(d, "y", k = 1e20, distance = "gower"),
    "No comparable donors for 'y' in 2 row"
  )
  expect_identical(result, expected)
  expect_identical(d$y, c(10, 20, NA_real_, NaN, NA_real_))
})

test_that("constant and entirely missing Gower predictors are distinct", {
  d <- data.frame(y = c(10, 20, NA), x = 5)
  expect_equal(impute_ml(d, "y", k = 1, distance = "gower")$y[3], 10)
  d$x <- NA_real_
  expect_warning(
    result <- impute_ml(d, "y", distance = "gower"),
    "No comparable donors"
  )
  expect_identical(result, d)
  # A jointly observed constant contributes zero and counts in the average.
  prepared <- PharmaStatsR:::prepare_gower_predictors(
    data.frame(x = c(1, 1, NA), y = c(0, 10, 5))
  )
  expect_equal(
    PharmaStatsR:::gower_imputation_distances(prepared, 2:3, 1), c(0.5, 0.5)
  )
})

test_that("Gower respects explicit predictors and categorical target types", {
  d <- data.frame(
    group = ordered(c("low", NA, "high"), levels = c("low", "medium", "high")),
    x = c(0, 1, 2), excluded = c(Inf, -Inf, NA),
    row.names = c("first", "second", "third")
  )
  expected <- d
  expected$group[2] <- "low"
  expect_identical(
    impute_ml(d, "group", k = 2, predictors = "x", distance = "gower"),
    expected
  )
  d$group <- c(TRUE, NA, FALSE)
  expect_identical(
    impute_ml(d, "group", k = 2, predictors = "x", distance = "gower")$group,
    c(TRUE, TRUE, FALSE)
  )
  expect_error(
    impute_ml(d, "group", predictors = "excluded", distance = "gower"),
    "infinite values"
  )
})

test_that("distance selection preserves defaults and validates its option", {
  d <- data.frame(y = c(1, NA, 3), x = c(1, NA, 2), group = c("a", "b", "a"))
  expect_identical(impute_ml(d, "y"), impute_ml(d, "y", distance = "euclidean"))
  for (distance in list("unknown", 1, NA_character_)) {
    expect_error(impute_ml(d, "y", distance = distance), "arg")
  }
  expect_identical(impute_ml(d, character(0), distance = "gower"), d)
  expect_warning(
    result <- impute_ml(d, "y", predictors = character(0), distance = "gower"),
    "No predictor columns"
  )
  expect_identical(result, d)
})
