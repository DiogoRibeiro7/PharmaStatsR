local_edition(3)

ancova_methods_data <- function() {
  data.frame(
    response = c(11, 11, 13, 17, 14, 16, 20, 26),
    treatment = factor(rep(c("A", "B"), each = 4)),
    baseline = rep(0:3, 2), precision = 1:8,
    row.names = paste0("case-", 1:8)
  )
}

ancova_methods_future <- function() {
  data.frame(
    treatment = c("A", "B", "A", "B"), baseline = c(0, 2, 1.5, 3),
    row.names = c("first", "second", "third", "fourth")
  )
}

test_that("ANCOVA extraction matches independent ordinary and weighted normal equations", {
  d <- ancova_methods_data()
  fits <- list(
    pharma_ancova(response ~ treatment + baseline, d, conf.level = 0.8),
    pharma_ancova(response ~ treatment + baseline, d, weights = precision, conf.level = 0.8)
  )
  inverses <- list(
    matrix(c(19 / 40, -1 / 4, -3 / 20, -1 / 4, 1 / 2, 0, -3 / 20, 0, 1 / 10), 3, 3),
    matrix(c(53 / 270, -31 / 270, -13 / 270, -31 / 270, 19 / 135, 1 / 135, -13 / 270, 1 / 135, 13 / 540), 3, 3)
  )
  betas <- list(c(8.5, 6, 3), c(296, 311, 167) / 45)
  variances <- c(18 / 5, 848 / 75)
  labels <- c("(Intercept)", "treatmentB", "baseline")
  for (i in seq_along(fits)) {
    fit <- fits[[i]]
    original <- fit
    beta <- setNames(betas[[i]], labels)
    covariance <- variances[i] * inverses[[i]]
    dimnames(covariance) <- list(labels, labels)
    expect_equal(coef(fit), beta, tolerance = 1e-12)
    expect_equal(vcov(fit), covariance, tolerance = 1e-12)
    expect_identical(coef(fit, complete = FALSE), coef(fit$model, complete = FALSE))
    expect_identical(vcov(fit, complete = FALSE), vcov(fit$model, complete = FALSE))
    expect_identical(coef(fit), coef(summary(fit))[, "Estimate"])
    for (level in c(0.9, 0.95)) {
      half_width <- stats::qt((1 + level) / 2, 5) * sqrt(diag(covariance))
      expected <- cbind(beta - half_width, beta + half_width)
      expect_equal(unname(confint(fit, level = level)), unname(expected), tolerance = 1e-12)
      expect_equal(unname(confint(fit, parm = c("baseline", "(Intercept)"), level = level)),
        unname(expected[c(3, 1), , drop = FALSE]),
        tolerance = 1e-12
      )
      expect_equal(unname(confint(fit, parm = c(2, 1), level = level)),
        unname(expected[c(2, 1), , drop = FALSE]),
        tolerance = 1e-12
      )
    }
    expect_identical(confint(fit), confint(fit$model))
    expect_identical(fit, original)
  }
})

test_that("ordinary ANCOVA predictions and intervals match independent variance targets", {
  fit <- pharma_ancova(response ~ treatment + baseline, ancova_methods_data(), conf.level = 0.8)
  future <- ancova_methods_future()
  means <- setNames(c(8.5, 20.5, 13, 23.5), rownames(future))
  leverage <- c(19 / 40, 11 / 40, 1 / 4, 19 / 40)
  variance <- 18 / 5
  se <- sqrt(variance * leverage)
  q <- stats::qt(0.95, 5)
  expect_equal(predict(fit, future), means, tolerance = 1e-12)
  expect_identical(predict(fit), predict(fit$model))
  expect_identical(predict(fit, NULL), predict(fit$model, NULL))
  result <- predict(fit, future, se.fit = TRUE)
  expect_equal(result$fit, means, tolerance = 1e-12)
  expect_equal(unname(result$se.fit), se, tolerance = 1e-12)
  expect_equal(result$df, 5)
  expect_equal(result$residual.scale, sqrt(variance), tolerance = 1e-12)
  for (kind in c("confidence", "prediction")) {
    half_width <- q * sqrt(variance * (leverage + (kind == "prediction")))
    expected <- cbind(fit = means, lwr = means - half_width, upr = means + half_width)
    expect_equal(predict(fit, future, interval = kind, level = 0.9), expected, tolerance = 1e-12)
    combined <- predict(fit, future, interval = kind, level = 0.9, se.fit = TRUE)
    expect_equal(combined$fit, expected, tolerance = 1e-12)
    expect_equal(unname(combined$se.fit), se, tolerance = 1e-12)
  }
  custom <- predict(fit, future, interval = "confidence", level = 0.9, se.fit = TRUE, scale = 2, df = 10)
  expect_equal(unname(custom$se.fit), 2 * sqrt(leverage), tolerance = 1e-12)
  expect_equal(custom$df, 10)
  expect_equal(custom$residual.scale, 2)
  expect_equal(unname(custom$fit[, "upr"]), unname(means) + stats::qt(0.95, 10) * 2 * sqrt(leverage), tolerance = 1e-12)
})

test_that("weighted prediction intervals use explicit future precision", {
  d <- ancova_methods_data()
  fit <- pharma_ancova(response ~ treatment + baseline, d, weights = precision)
  future <- ancova_methods_future()
  design <- cbind(1, c(0, 1, 0, 1), future$baseline)
  inverse <- matrix(c(53 / 270, -31 / 270, -13 / 270, -31 / 270, 19 / 135, 1 / 135, -13 / 270, 1 / 135, 13 / 540), 3, 3)
  means <- as.vector(design %*% (c(296, 311, 167) / 45))
  variance <- 848 / 75
  mean_variance <- variance * rowSums((design %*% inverse) * design)
  future$precision <- c(2, 4, 1, 8)
  half_width <- stats::qt(0.95, 5) * sqrt(mean_variance + variance / future$precision)
  expected <- cbind(fit = means, lwr = means - half_width, upr = means + half_width)
  rownames(expected) <- rownames(future)
  expect_equal(predict(fit, future, interval = "prediction", level = 0.9, weights = future$precision), expected, tolerance = 1e-12)
  expect_equal(predict(fit, future, interval = "prediction", level = 0.9, weights = ~precision), expected, tolerance = 1e-12)
  scaled <- pharma_ancova(response ~ treatment + baseline, d, weights = 13 * precision)
  expect_equal(predict(scaled, future, interval = "prediction", level = 0.9, weights = 13 * future$precision), expected, tolerance = 1e-12)
  expect_equal(predict(fit, future, interval = "prediction", pred.var = 0),
    predict(fit, future, interval = "confidence"),
    tolerance = 1e-12
  )
  expect_warning(predict(fit, future, interval = "prediction"), "prediction variance")
  expect_warning(
    expect_warning(predict(fit, interval = "prediction"), "future.*responses"),
    "prediction variance"
  )
})

test_that("native row handling, terms, contrasts and selected populations are preserved", {
  d <- ancova_methods_data()
  keep <- c(8, 7, 6, 4, 3, 2)
  fit <- pharma_ancova(response ~ treatment + baseline, d, subset = keep, weights = precision)
  expect_identical(names(predict(fit)), rownames(d)[keep])
  expect_identical(predict(fit, se.fit = TRUE), predict(fit$model, se.fit = TRUE))
  design <- cbind(1, as.numeric(d$treatment == "B"), d$baseline)[keep, ]
  beta <- solve(crossprod(design, design * d$precision[keep]), crossprod(design, d$response[keep] * d$precision[keep]))
  expect_equal(unname(predict(fit)), as.vector(design %*% beta), tolerance = 1e-12)
  future <- ancova_methods_future()
  expect_identical(predict(fit, future[1, , drop = FALSE]), predict(fit$model, future[1, , drop = FALSE]))
  expect_length(predict(fit, future[FALSE, ]), 0L)
  expect_identical(dim(predict(fit, future[FALSE, ], interval = "confidence")), c(0L, 3L))
  future$baseline[2] <- NA_real_
  expect_true(is.na(predict(fit, future)[2]))
  expect_identical(names(predict(fit, future)), rownames(future))
  expect_identical(names(predict(fit, future, na.action = stats::na.omit)), rownames(future)[-2])
  future$treatment[1] <- "unknown"
  expect_error(predict(fit, future), "new level")
  expect_error(predict(fit, data.frame(treatment = "A")), "baseline")
  custom <- pharma_ancova(response ~ treatment + baseline, d, contrasts = list(treatment = "contr.sum"))
  future <- ancova_methods_future()
  terms <- predict(custom, future, type = "terms")
  expect_equal(rowSums(terms) + attr(terms, "constant"), predict(custom, future), tolerance = 1e-12)
  expect_identical(
    predict(custom, future, type = "terms", terms = "baseline", se.fit = TRUE),
    predict(custom$model, future, type = "terms", terms = "baseline", se.fit = TRUE)
  )
})

test_that("saved ANCOVA methods preserve native results without refitting or RNG draws", {
  d <- ancova_methods_data()
  formula <- stats::as.formula("response ~ treatment + baseline", env = baseenv())
  fit <- pharma_ancova(formula, d, weights = precision)
  future <- ancova_methods_future()
  expected <- list(coef = coef(fit$model), vcov = vcov(fit$model), confint = confint(fit$model), predict = predict(fit$model, future, se.fit = TRUE))
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(fit, path)
  restored <- readRDS(path)
  rm(d, formula)
  local_mocked_bindings(
    lm = function(...) stop("Unexpected refitting"),
    lm.fit = function(...) stop("Unexpected refitting"),
    lm.wfit = function(...) stop("Unexpected refitting"),
    .package = "stats"
  )
  set.seed(525)
  seed <- .Random.seed
  expect_identical(coef(restored), expected$coef)
  expect_identical(vcov(restored), expected$vcov)
  expect_identical(confint(restored), expected$confint)
  expect_identical(predict(restored, future, se.fit = TRUE), expected$predict)
  expect_identical(summary(restored), summary(fit))
  expect_identical(.Random.seed, seed)
  expect_identical(restored, fit)
})

test_that("methods require the saved additive lm rather than another model class", {
  fit <- pharma_ancova(response ~ treatment + baseline, ancova_methods_data())
  for (bad in list(NULL, list(), structure(list(), class = c("glm", "lm")), structure(list(), class = c("mlm", "lm")))) {
    fit$model <- bad
    for (method in list(coef, vcov, confint, predict)) {
      expect_error(method(fit), "saved additive model must be an lm")
    }
  }
})
