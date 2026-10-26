local_edition(3)

weighted_ancova_data <- function() {
  data.frame(
    response = c(11, 11, 13, 17, 14, 16, 20, 26),
    treatment = factor(rep(c("A", "B"), each = 4)),
    baseline = rep(0:3, 2), precision = 1:8,
    row.names = paste0("case-", 1:8)
  )
}

test_that("weighted ANCOVA matches independent normal-equation targets", {
  d <- weighted_ancova_data()
  original <- d
  fit <- pharma_ancova(response ~ treatment + baseline, d, weights = precision, conf.level = 0.9)
  # Exact arithmetic for X=(1, groupB, baseline), W=diag(1:8):
  # X'WX = rbind(c(36,26,64), c(26,26,44), c(64,44,156)).
  beta <- c(296, 311, 167) / 45
  inverse <- matrix(c(
    53 / 270, -31 / 270, -13 / 270,
    -31 / 270, 19 / 135, 1 / 135,
    -13 / 270, 1 / 135, 13 / 540
  ), 3, 3)
  sse <- 848 / 15
  covariance <- (sse / 5) * inverse
  se <- sqrt(diag(covariance))
  t <- beta / se
  expect_equal(unname(coef(fit$model)), beta, tolerance = 1e-12)
  expect_equal(unname(stats::vcov(fit$model)), covariance, tolerance = 1e-12)
  expect_equal(stats::deviance(fit$model), sse, tolerance = 1e-12)
  expect_equal(unname(coef(summary(fit))),
    unname(cbind(beta, se, t, 2 * stats::pt(-abs(t), 5))),
    tolerance = 1e-12
  )
  expect_equal(unname(coef(fit$interaction_model)), c(46 / 5, 147 / 41, 12 / 5, 354 / 205), tolerance = 1e-12)
  interaction_sse <- 6948 / 205
  expect_equal(stats::deviance(fit$interaction_model), interaction_sse, tolerance = 1e-12)
  f <- (sse - interaction_sse) / (interaction_sse / 4)
  expect_equal(unlist(fit$slope_homogeneity, use.names = FALSE),
    c(1, 4, f, stats::pf(f, 1, 4, lower.tail = FALSE)),
    tolerance = 1e-12
  )
  # Precision weights affect the fit; the adjustment point is the selected
  # observations' arithmetic mean, not their precision-weighted mean.
  expect_identical(fit$covariate_mean, 1.5)
  means <- c(1093 / 90, 343 / 18)
  mean_se <- sqrt(c(12137 / 10125, 901 / 2025))
  half_width <- stats::qt(0.95, 5) * mean_se
  expect_equal(fit$adjusted_means$adjusted_mean, means, tolerance = 1e-12)
  expect_equal(fit$adjusted_means$conf.low, means - half_width, tolerance = 1e-12)
  expect_equal(fit$adjusted_means$conf.high, means + half_width, tolerance = 1e-12)
  expect_identical(fit$model$weights, d$precision)
  expect_identical(fit$interaction_model$weights, d$precision)
  expect_identical(d, original)
})

test_that("weights use native column/expression lookup and scale invariance", {
  d <- weighted_ancova_data()
  baseline <- pharma_ancova(response ~ treatment + baseline, d)
  unit <- pharma_ancova(response ~ treatment + baseline, d, weights = rep(1, nrow(d)))
  expect_equal(coef(unit$model), coef(baseline$model))
  expect_equal(unit$adjusted_means, baseline$adjusted_means)
  reference <- pharma_ancova(response ~ treatment + baseline, d, weights = precision)
  scaled <- pharma_ancova(response ~ treatment + baseline, d, weights = 17 * precision)
  expect_equal(coef(scaled$model), coef(reference$model), tolerance = 1e-12)
  expect_equal(stats::vcov(scaled$model), stats::vcov(reference$model), tolerance = 1e-12)
  expect_equal(scaled$adjusted_means, reference$adjusted_means, tolerance = 1e-12)
  expect_equal(scaled$slope_homogeneity, reference$slope_homogeneity, tolerance = 1e-12)
  external_weights <- d$precision
  external <- pharma_ancova(response ~ treatment + baseline, d, weights = external_weights)
  expect_equal(coef(external$model), coef(reference$model), tolerance = 1e-12)
  native <- stats::lm(response ~ treatment + baseline, d, weights = precision)
  expect_equal(coef(reference$model), coef(native), tolerance = 1e-12)
  expect_equal(stats::vcov(reference$model), stats::vcov(native), tolerance = 1e-12)
  custom <- pharma_ancova(response ~ treatment + baseline, d,
    weights = precision,
    contrasts = list(treatment = "contr.sum"), tol = 1e-8,
    x = TRUE, y = TRUE, model = TRUE, qr = TRUE, method = "qr",
    singular.ok = FALSE, na.action = stats::na.exclude
  )
  expect_equal(custom$adjusted_means, reference$adjusted_means, tolerance = 1e-12)
  expect_equal(custom$slope_homogeneity, reference$slope_homogeneity, tolerance = 1e-12)
  expect_true(is.matrix(custom$model$x))
  expect_equal(unname(custom$model$y), d$response)
})

test_that("subsets determine both fits, levels, weights and adjustment point", {
  d <- weighted_ancova_data()
  extra <- d[1, ]
  extra$response <- NA_real_
  extra$baseline <- 1000
  extra$precision <- NA_real_
  extra$treatment <- factor("C", levels = c("A", "B", "C"))
  d$treatment <- factor(d$treatment, levels = c("A", "B", "C"))
  d <- rbind(d, extra)
  d$include <- c(rep(TRUE, 8), FALSE)
  selected <- pharma_ancova(response ~ treatment + baseline, d, weights = precision, subset = include)
  expect_identical(rownames(selected$model$model), rownames(d)[1:8])
  expect_identical(rownames(selected$interaction_model$model), rownames(d)[1:8])
  expect_identical(selected$adjusted_means$treatment, c("A", "B"))
  expect_identical(selected$covariate_mean, 1.5)
  expect_equal(selected$model$weights, 1:8)
  fit <- pharma_ancova(response ~ treatment + baseline, d,
    weights = precision,
    subset = include & baseline > 0
  )
  keep <- c(2, 3, 4, 6, 7, 8)
  native <- stats::lm(response ~ treatment + baseline, d[keep, ], weights = precision)
  expect_identical(rownames(fit$model$model), rownames(d)[keep])
  expect_identical(rownames(fit$interaction_model$model), rownames(d)[keep])
  expect_equal(fit$model$weights, d$precision[keep])
  expect_identical(fit$covariate_mean, 2)
  expect_equal(coef(fit$model), coef(native), tolerance = 1e-12)
  predicted <- predict(native, data.frame(treatment = c("A", "B"), baseline = 2), interval = "confidence")
  expect_equal(as.matrix(fit$adjusted_means[, 3:5]), unname(predicted), ignore_attr = TRUE)
  permuted <- pharma_ancova(response ~ treatment + baseline, d,
    weights = precision,
    subset = c(8, 1, 6, 3, 2, 7, 4, 5)
  )
  expect_equal(coef(permuted$model), coef(selected$model), tolerance = 1e-12)
  expect_equal(permuted$adjusted_means, selected$adjusted_means, tolerance = 1e-12)
  expect_error(
    pharma_ancova(response ~ treatment + baseline, d, subset = include & treatment == "A"),
    "at least two observed levels"
  )
})

test_that("data-dependent expressions are resolved once and saved fits remain usable", {
  d <- weighted_ancova_data()
  calls <- new.env()
  calls$weights <- calls$subset <- 0L
  once_weights <- function(x) {
    calls$weights <- calls$weights + 1L
    x
  }
  once_subset <- function(x) {
    calls$subset <- calls$subset + 1L
    x
  }
  fit <- pharma_ancova(response ~ treatment + baseline, d,
    weights = once_weights(precision), subset = once_subset(baseline >= 0)
  )
  expect_identical(calls$weights, 1L)
  expect_identical(calls$subset, 1L)
  expect_identical(fit$model$weights, fit$interaction_model$weights)
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(fit, path)
  restored <- readRDS(path)
  expect_identical(coef(summary(restored)), coef(summary(fit)))
  newdata <- data.frame(treatment = c("A", "B"), baseline = 1.5)
  expect_identical(predict(restored$model, newdata), predict(fit$model, newdata))
  expect_identical(calls$weights, 1L)
  expect_identical(calls$subset, 1L)
  d$treatment <- d$treatment == "B"
  logical <- pharma_ancova(response ~ treatment + baseline, d, weights = precision)
  expect_equal(logical$adjusted_means$adjusted_mean, fit$adjusted_means$adjusted_mean, tolerance = 1e-12)
})

test_that("ANCOVA rejects unsupported weight, row and fit configurations", {
  d <- weighted_ancova_data()
  for (bad in list(
    c(0, rep(1, 7)), c(-1, rep(1, 7)), c(NA, rep(1, 7)),
    c(Inf, rep(1, 7)), rep(TRUE, 8), rep("1", 8),
    rep(1 + 1i, 8), matrix(1, 8, 1)
  )) {
    expect_error(
      pharma_ancova(response ~ treatment + baseline, d, weights = bad),
      "strictly positive numeric"
    )
  }
  expect_error(
    pharma_ancova(response ~ treatment + baseline, d, weights = 1:3),
    "variable lengths differ"
  )
  expect_error(
    pharma_ancova(response ~ treatment + baseline, d, offset = baseline),
    "Offsets are unsupported"
  )
  expect_error(
    pharma_ancova(response ~ treatment + baseline + offset(baseline), d),
    "Offsets are unsupported"
  )
  expect_error(pharma_ancova(response ~ treatment + baseline, d, qr = FALSE), "qr must be TRUE")
  expect_error(pharma_ancova(response ~ treatment + baseline, d, model = FALSE), "model must be TRUE")
  expect_error(pharma_ancova(response ~ treatment + baseline, d, method = "model.frame"), "method must be")
  expect_error(pharma_ancova(response ~ treatment + baseline, d, tol = 0), "tol must be")
  expect_error(pharma_ancova(response ~ treatment + baseline, d, unknown = TRUE), "Unsupported ANCOVA")
  expect_error(pharma_ancova(response ~ treatment + baseline, d, 0.95, 1:8), "unique, complete names")
  expect_error(
    pharma_ancova(response ~ treatment + baseline, d, weights = 1:8, weights = 1:8),
    "unique, complete names"
  )
  expect_error(
    pharma_ancova(response ~ treatment + baseline, d, na.action = function(x) x[-1, ]),
    "Custom na.action"
  )
  d$response[1] <- NA_real_
  expect_error(
    pharma_ancova(response ~ treatment + baseline, d, na.action = stats::na.omit),
    "contain NA"
  )
  d <- weighted_ancova_data()
  expect_error(
    pharma_ancova(response ~ treatment + baseline, d, subset = c(TRUE, NA, rep(TRUE, 6))),
    "contain NA"
  )
  d$baseline <- as.numeric(d$treatment)
  expect_error(pharma_ancova(response ~ treatment + baseline, d), "full column rank")
  d <- weighted_ancova_data()[c(1, 2, 5, 6), ]
  expect_error(pharma_ancova(response ~ treatment + baseline, d), "positive residual degrees")
})
