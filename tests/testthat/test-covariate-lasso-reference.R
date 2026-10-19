local_edition(3)

lasso_reference_data <- function(signal_effect = 2, noise_effect = 0) {
  u <- rep(c(-1, 1), 4)
  v <- rep(c(-1, -1, 1, 1), 2)
  error <- rep(c(-1, 1), each = 4)
  data.frame(
    y = rep(3 + signal_effect * u + noise_effect * v + 0.5 * error, 3),
    signal = rep(u, 3), noise = rep(v, 3),
    id = rep(c("subject-a", "subject-b", "subject-c"), each = 8)
  )
}

test_that("the LASSO path and held-out errors agree with soft thresholding", {
  observed <- NULL
  real_cv <- glmnet::cv.glmnet
  local_mocked_bindings(
    cv.glmnet = function(x, y, ...) {
      # keep retains held-out predictions without changing the fitted path.
      observed <<- real_cv(x, y, ..., keep = TRUE)
      observed
    },
    .package = "glmnet"
  )
  for (effects in list(c(2, 0), c(-2, 0), c(2, 1))) {
    d <- lasso_reference_data(effects[1], effects[2])
    selected <- screen_covariates_lasso(
      d, "y", c("signal", "noise"),
      id = "id",
      foldid = rep(c(10L, 20L, 30L), each = 8)
    )
    # In every training split, u and v have mean 0, mean square 1, and
    # zero cross-product; the error is orthogonal with mean square 1/4.
    # Thus beta_j(lambda) = sign(effect_j)*max(abs(effect_j)-lambda, 0).
    # This target uses no fitted coefficients, another solver or CV routine.
    lambda <- observed$lambda
    b1 <- sign(effects[1]) * pmax(abs(effects[1]) - lambda, 0)
    b2 <- sign(effects[2]) * pmax(abs(effects[2]) - lambda, 0)
    expected_coefficients <- rbind(rep(3, length(lambda)), b1, b2)
    expected_predictions <- 3 + outer(d$signal, b1) + outer(d$noise, b2)
    expected_mse <- 0.25 + (effects[1] - b1)^2 + (effects[2] - b2)^2

    expect_equal(max(lambda), 2, tolerance = 1e-10)
    expect_gt(min(lambda), 0)
    expect_lt(min(lambda), 1)
    expect_equal(
      as.matrix(stats::coef(observed$glmnet.fit)), expected_coefficients,
      ignore_attr = TRUE, tolerance = 1e-10
    )
    expect_equal(
      observed$fit.preval, expected_predictions,
      ignore_attr = TRUE, tolerance = 1e-10
    )
    expect_equal(observed$cvm, expected_mse, tolerance = 1e-10)
    expect_equal(observed$cvsd, rep(0, length(lambda)), tolerance = 1e-10)
    expect_identical(observed$lambda.min, min(lambda))
    expect_identical(observed$lambda.min, lambda[which.min(expected_mse)])
    expect_identical(selected, c("signal", "noise")[effects != 0])
  }
})

test_that("literal predictor names are not confused with the fitted intercept", {
  folds <- rep(1:3, each = 8)
  for (name in c("(Intercept)", "body mass", "x+y", "x:y", "`x`", ".", "I(x)")) {
    d <- lasso_reference_data()
    names(d)[2] <- name
    original <- d
    expect_identical(
      screen_covariates_lasso(d, "y", c(signal = name, control = "noise"), foldid = folds),
      name
    )
    expect_identical(d, original)
  }
  # The actual intercept is 3, but the candidate named (Intercept) has zero
  # coefficient. Excluding only the first coefficient must not select it.
  d <- lasso_reference_data(signal_effect = 0, noise_effect = 2)
  names(d)[2] <- "(Intercept)"
  expect_identical(
    screen_covariates_lasso(d, "y", c("(Intercept)", "noise"), foldid = folds),
    "noise"
  )
})

test_that("selected names follow candidate order for multiple active columns", {
  d <- lasso_reference_data(noise_effect = 1)
  names(d)[2:3] <- c("(Intercept)", "other effect")
  for (candidates in list(c("(Intercept)", "other effect"), c("other effect", "(Intercept)"))) {
    expect_identical(
      screen_covariates_lasso(d, "y", candidates, foldid = rep(1:3, each = 8)),
      candidates
    )
  }
})

test_that("analytic CV references survive complete-case row and fold alignment", {
  observed <- NULL
  captured <- NULL
  real_cv <- glmnet::cv.glmnet
  local_mocked_bindings(
    cv.glmnet = function(x, y, ...) {
      captured <<- list(x = x, y = y, args = list(...))
      observed <<- real_cv(x, y, ..., keep = TRUE)
      observed
    },
    .package = "glmnet"
  )
  d <- lasso_reference_data()
  extra <- data.frame(
    y = c(10000, -10000, NA), signal = c(NA, 1000, 2000),
    noise = c(1000, NA, 3000), id = NA_character_
  )
  full <- rbind(d, extra)
  full$unused <- NA_real_
  foldid <- c(rep(c(10L, 20L, 30L), each = 8), rep(40L, 3))
  permutation <- rev(seq_len(nrow(full)))
  full <- full[permutation, ]
  foldid <- foldid[permutation]
  keep <- complete.cases(full[c("y", "signal", "noise")])
  expect_identical(
    screen_covariates_lasso(
      full, "y", c("signal", "noise"),
      id = "id", foldid = foldid
    ),
    "signal"
  )
  expect_equal(captured$x, as.matrix(full[keep, c("signal", "noise")]))
  expect_identical(captured$y, full$y[keep])
  expect_identical(captured$args$foldid, match(foldid[keep], c(10L, 20L, 30L)))
  b <- pmax(2 - observed$lambda, 0)
  expect_equal(
    observed$fit.preval, 3 + outer(full$signal[keep], b),
    ignore_attr = TRUE, tolerance = 1e-10
  )
  expect_equal(observed$cvm, 0.25 + (2 - b)^2, tolerance = 1e-10)
})

test_that("standardization preserves selection under changed predictor units", {
  d <- lasso_reference_data()
  d$signal <- 10 - 4 * d$signal
  d$noise <- 100 + 0.25 * d$noise
  d$y <- 13 - 7 * d$y
  names(d)[2] <- "(Intercept)"
  expect_identical(
    screen_covariates_lasso(d, "y", c("noise", "(Intercept)"), foldid = rep(1:3, each = 8)),
    "(Intercept)"
  )
})
