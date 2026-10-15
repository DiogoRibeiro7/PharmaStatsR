local_edition(3)

library(testthat)

make_lasso_data <- function() {
  set.seed(123)
  data.frame(
    DV = rnorm(100),
    x1 = rnorm(100),
    x2 = rnorm(100)
  )
}

# When no covariates provided ---------------------------------------------

test_that("returns empty when no covariates", {
  base_data <- make_lasso_data()
  res <- screen_covariates_lasso(base_data, "DV", character(0))
  expect_equal(res, character(0))
})

# Signal in x1 -------------------------------------------------------------

test_that("selects covariate with signal", {
  base_data <- make_lasso_data()
  signal_data <- base_data
  signal_data$DV <- 2 * signal_data$x1 + rnorm(100)
  selected <- screen_covariates_lasso(signal_data, "DV", c("x1", "x2"))
  expect_equal(selected, "x1")
})

# NA handling --------------------------------------------------------------

test_that("handles NA values", {
  base_data <- make_lasso_data()
  signal_data <- base_data
  signal_data$DV <- 2 * signal_data$x1 + rnorm(100)
  data_na <- signal_data
  indices <- sample(1:100, 10)
  data_na$x1[indices] <- NA
  selected_na <- screen_covariates_lasso(data_na, "DV", c("x1", "x2"))
  expect_equal(selected_na, "x1")
})

make_grouped_lasso_data <- function() {
  set.seed(710)
  subjects <- rep(sprintf("S%02d", 1:15), times = rep(2:4, 5))
  d <- data.frame(
    SubjectID = subjects,
    x1 = rnorm(length(subjects)),
    x2 = rnorm(length(subjects))
  )
  d$DV <- 3 * d$x1 + rnorm(nrow(d), sd = 0.5)
  d
}

test_that("random folds preserve subjects and are reproducible", {
  d <- make_grouped_lasso_data()
  calls <- list()
  original_cv <- glmnet::cv.glmnet
  local_mocked_bindings(
    cv.glmnet = function(x, y, ...) {
      calls[[length(calls) + 1L]] <<- list(...)
      original_cv(x, y, ...)
    },
    .package = "glmnet"
  )

  set.seed(81)
  selected <- screen_covariates_lasso(
    d, "DV", c("x1", "x2"),
    id = "SubjectID", nfolds = 5
  )
  set.seed(81)
  repeated <- screen_covariates_lasso(
    d, "DV", c("x1", "x2"),
    id = "SubjectID", nfolds = 5
  )
  expect_identical(selected, repeated)
  expect_true("x1" %in% selected)
  expect_identical(calls[[1]]$foldid, calls[[2]]$foldid)
  folds <- calls[[1]]$foldid
  subject_folds <- split(folds, d$SubjectID)
  expect_true(all(vapply(subject_folds, function(x) {
    length(unique(x)) == 1L
  }, logical(1))))
  expect_equal(sort(unique(folds)), 1:5)
  expect_equal(as.integer(table(folds[!duplicated(d$SubjectID)])), rep(3L, 5))

  # Fold construction also supports factor identifiers with unused levels.
  d$SubjectID <- factor(d$SubjectID, levels = c(unique(d$SubjectID), "unused"))
  set.seed(81)
  screen_covariates_lasso(
    d, "DV", c("x1", "x2"),
    id = "SubjectID", nfolds = 5
  )
  expect_identical(calls[[1]]$foldid, calls[[3]]$foldid)
})

test_that("supplied folds stay aligned with complete-case observations", {
  d <- make_grouped_lasso_data()
  unit <- match(d$SubjectID, unique(d$SubjectID))
  supplied <- rep(c(10L, 20L, 30L, 40L, 50L), length.out = 15)[unit]
  d$x1[supplied == 20L] <- NA_real_ # Remove an entire validation fold.
  d$DV[1] <- NA_real_
  d$SubjectID[1] <- NA_character_ # Ignored with its incomplete model row.
  keep <- complete.cases(d[c("DV", "x1", "x2")])
  captured <- NULL
  original_cv <- glmnet::cv.glmnet
  local_mocked_bindings(
    cv.glmnet = function(x, y, ...) {
      captured <<- list(x = x, y = y, args = list(...))
      original_cv(x, y, ...)
    },
    .package = "glmnet"
  )

  set.seed(19)
  rng_before <- .Random.seed
  selected <- screen_covariates_lasso(
    d, "DV", c("x1", "x2"),
    id = "SubjectID", foldid = supplied,
    nfolds = 2 # Explicit folds take precedence over nfolds.
  )
  expect_identical(.Random.seed, rng_before)
  expect_identical(captured$y, d$DV[keep])
  expect_equal(captured$x, as.matrix(d[keep, c("x1", "x2")]))
  expect_equal(
    captured$args$foldid,
    unname(c(`10` = 1L, `30` = 2L, `40` = 3L, `50` = 4L)[
      as.character(supplied[keep])
    ])
  )
  expect_true("x1" %in% selected)
})

test_that("row-level default matches the original glmnet call", {
  d <- make_lasso_data()
  d$DV <- 2 * d$x1 + rnorm(nrow(d))
  set.seed(87)
  expected <- glmnet::cv.glmnet(as.matrix(d[c("x1", "x2")]), d$DV, alpha = 0.5)
  coefs <- stats::coef(expected, s = "lambda.min")
  selected <- setdiff(rownames(coefs)[coefs[, 1] != 0], "(Intercept)")

  set.seed(87)
  expect_identical(
    screen_covariates_lasso(d, "DV", c("x1", "x2"), 0.5),
    selected
  )
})

test_that("custom folds cannot split a subject or disappear after filtering", {
  d <- make_grouped_lasso_data()
  expect_error(
    screen_covariates_lasso(
      d, "DV", c("x1", "x2"),
      id = "SubjectID",
      foldid = rep(1:3, length.out = nrow(d))
    ),
    "each retained subject in a single fold"
  )
  folds <- rep(1:3, each = nrow(d) / 3)
  d$x1[folds == 3L] <- NA_real_
  expect_error(
    screen_covariates_lasso(d, "DV", c("x1", "x2"), foldid = folds),
    "at least three nonempty folds"
  )
})

test_that("fold counts and original-row labels are validated", {
  d <- make_grouped_lasso_data()
  for (nfolds in list(2, 3.5, NA_real_, Inf, c(3, 4), "5")) {
    expect_error(
      screen_covariates_lasso(d, "DV", c("x1", "x2"), nfolds = nfolds),
      "`nfolds` must be an integer",
      fixed = TRUE
    )
  }
  expect_error(
    screen_covariates_lasso(
      d, "DV", c("x1", "x2"),
      id = "SubjectID", nfolds = 16
    ),
    "exceeds the number of retained subjects or rows"
  )
  for (folds in list(
    1:3, rep(NA_real_, nrow(d)), rep(1.5, nrow(d)),
    rep(0, nrow(d)), rep(Inf, nrow(d)), rep("1", nrow(d))
  )) {
    expect_error(
      screen_covariates_lasso(d, "DV", c("x1", "x2"), foldid = folds),
      "one positive integer per original data row"
    )
  }
  expect_error(
    screen_covariates_lasso(d, "DV", c("x1", "x2"), id = "missing"),
    "`id` must name a subject",
    fixed = TRUE
  )
  d$SubjectID[1] <- NA_character_
  expect_error(
    screen_covariates_lasso(d, "DV", c("x1", "x2"), id = "SubjectID"),
    "nonmissing vector on retained rows"
  )

  d <- make_grouped_lasso_data()
  d$SubjectID <- I(cbind(d$SubjectID, d$SubjectID))
  expect_error(
    screen_covariates_lasso(d, "DV", c("x1", "x2"), id = "SubjectID"),
    "nonmissing vector on retained rows"
  )
})

test_that("fold counts use only subjects with complete-case observations", {
  d <- make_grouped_lasso_data()
  d$x1[!d$SubjectID %in% c("S01", "S02")] <- NA_real_
  expect_error(
    screen_covariates_lasso(
      d, "DV", c("x1", "x2"),
      id = "SubjectID", nfolds = 3
    ),
    "exceeds the number of retained subjects or rows"
  )
})

test_that("invalid model inputs fail before estimation", {
  d <- make_grouped_lasso_data()
  for (alpha in list(-1, 2, Inf, NA_real_, "1", c(0, 1))) {
    expect_error(
      screen_covariates_lasso(d, "DV", c("x1", "x2"), alpha = alpha),
      "`alpha` must be a finite number",
      fixed = TRUE
    )
  }
  expect_error(
    screen_covariates_lasso(d, "DV", c("DV", "x1")),
    "cannot also be a candidate"
  )
  expect_error(
    screen_covariates_lasso(d, "DV", "x1"), "at least two numeric"
  )
  expect_error(
    screen_covariates_lasso(d, "DV", c("x1", "x1")), "unique column names"
  )
  expect_error(
    screen_covariates_lasso(d, "DV", c("x1", "SubjectID")), "numeric vectors"
  )
  d$x1[1] <- Inf
  expect_error(
    screen_covariates_lasso(d, "DV", c("x1", "x2")), "must be finite"
  )
  d$x1 <- NA_real_
  expect_error(
    screen_covariates_lasso(d, "DV", c("x1", "x2")),
    "At least three complete-case rows"
  )
})

test_that("degenerate training folds have actionable errors", {
  d <- make_grouped_lasso_data()
  folds <- rep(1:3, length.out = nrow(d))
  d$DV[folds != 1L] <- 0
  expect_error(
    screen_covariates_lasso(d, "DV", c("x1", "x2"), foldid = folds),
    "Training data excluding fold 1 has constant response"
  )
  d <- make_grouped_lasso_data()
  d[folds != 1L, c("x1", "x2")] <- 0
  expect_error(
    screen_covariates_lasso(d, "DV", c("x1", "x2"), foldid = folds),
    "Training data excluding fold 1 has no varying covariates"
  )
})
