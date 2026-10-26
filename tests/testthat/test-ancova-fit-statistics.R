local_edition(3)

test_that("ANCOVA methods load when only base R is attached", {
  package_path <- getNamespaceInfo(asNamespace("PharmaStatsR"), "path")
  skip_if_not(
    file.exists(file.path(package_path, "Meta", "package.rds")),
    "requires an installed package"
  )
  script <- tempfile(fileext = ".R")
  on.exit(unlink(script))
  r_tests <- Sys.getenv("R_TESTS", unset = NA_character_)
  on.exit(if (is.na(r_tests)) Sys.unsetenv("R_TESTS") else Sys.setenv(R_TESTS = r_tests), add = TRUE)
  Sys.unsetenv("R_TESTS")
  writeLines(c(
    paste0(".libPaths(", paste(deparse(.libPaths()), collapse = ""), ")"),
    'stopifnot(!"package:stats" %in% search())',
    paste0("loadNamespace('PharmaStatsR', lib.loc = ", deparse(dirname(package_path)), ")"),
    'stopifnot(!"package:stats" %in% search())',
    "d <- data.frame(response = c(11, 11, 13, 17, 14, 16, 20, 26),",
    "  treatment = factor(rep(c('A', 'B'), each = 4)), baseline = rep(0:3, 2))",
    "fit <- PharmaStatsR::pharma_ancova(",
    "  stats::as.formula('response ~ treatment + baseline', env = baseenv()), d)",
    "stopifnot(length(stats::fitted(fit)) == 8L, length(stats::residuals(fit)) == 8L,",
    "  stats::nobs(fit) == 8, stats::df.residual(fit) == 5,",
    "  abs(stats::deviance(fit) - 18) < 1e-10,",
    "  is.finite(stats::logLik(fit)), is.finite(stats::AIC(fit)), is.finite(stats::BIC(fit)))",
    "cat('ANCOVA_BASE_NAMESPACE_OK\\n')"
  ), script)
  rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
  output <- suppressWarnings(system2(rscript,
    c("--vanilla", "--default-packages=NULL", shQuote(script)),
    stdout = TRUE, stderr = TRUE
  ))
  status <- attr(output, "status")
  expect_true(is.null(status) || identical(status, 0L), info = paste(output, collapse = "\n"))
  expect_true("ANCOVA_BASE_NAMESPACE_OK" %in% output, info = paste(output, collapse = "\n"))
})

ancova_statistics_data <- function() {
  data.frame(
    response = c(11, 11, 13, 17, 14, 16, 20, 26),
    treatment = factor(rep(c("A", "B"), each = 4)),
    baseline = rep(0:3, 2), precision = 1:8,
    row.names = paste0("case-", 1:8)
  )
}

test_that("fitted values and residual types match ordinary and weighted references", {
  d <- ancova_statistics_data()
  fits <- list(
    pharma_ancova(response ~ treatment + baseline, d),
    pharma_ancova(response ~ treatment + baseline, d, weights = precision)
  )
  fitted_values <- list(
    c(8.5, 11.5, 14.5, 17.5, 14.5, 17.5, 20.5, 23.5),
    c(296, 463, 630, 797, 607, 774, 941, 1108) / 45
  )
  raw_residuals <- list(
    c(2.5, -.5, -1.5, -.5, -.5, -1.5, -.5, 2.5),
    c(199, 32, -45, -32, 23, -54, -41, 62) / 45
  )
  weights <- list(rep(1, 8), d$precision)
  slopes <- list(c(6, 3), c(311, 167) / 45)
  for (i in seq_along(fits)) {
    fit <- fits[[i]]
    expected_fit <- setNames(fitted_values[[i]], rownames(d))
    expected_residual <- setNames(raw_residuals[[i]], rownames(d))
    expect_equal(fitted(fit), expected_fit, tolerance = 1e-12)
    expect_identical(fitted.values(fit), fitted(fit))
    expect_equal(residuals(fit), expected_residual, tolerance = 1e-12)
    expect_identical(resid(fit), residuals(fit))
    expect_equal(unname(fitted(fit) + residuals(fit)), d$response, tolerance = 1e-12)
    for (type in c("working", "response", "deviance", "pearson")) {
      expected <- expected_residual
      if (type %in% c("deviance", "pearson")) expected <- expected * sqrt(weights[[i]])
      expect_equal(residuals(fit, type = type), expected, tolerance = 1e-12)
    }
    partial <- residuals(fit, type = "partial")
    centered <- cbind(as.numeric(d$treatment == "B") - .5, d$baseline - 1.5)
    expected_partial <- sweep(centered, 2, slopes[[i]], "*") + raw_residuals[[i]]
    expect_equal(as.vector(partial), as.vector(expected_partial), tolerance = 1e-12)
    expect_identical(dim(partial), c(8L, 2L))
    expect_identical(rownames(partial), rownames(d))
    expect_identical(colnames(partial), c("treatment", "baseline"))
    expect_identical(partial, residuals(fit$model, type = "partial"))
    expect_error(residuals(fit, type = "unknown"), "arg")
    expect_equal(nobs(fit), 8)
    expect_equal(df.residual(fit), 5)
    expect_equal(deviance(fit), c(18, 848 / 15)[i], tolerance = 1e-12)
    expect_equal(deviance(fit) / df.residual(fit), summary(fit)$sigma^2, tolerance = 1e-12)
  }
})

test_that("Gaussian ML and REML likelihoods match independent determinant references", {
  d <- ancova_statistics_data()
  fits <- list(
    pharma_ancova(response ~ treatment + baseline, d),
    pharma_ancova(response ~ treatment + baseline, d, weights = precision)
  )
  for (i in seq_along(fits)) {
    fit <- fits[[i]]
    sse <- c(18, 848 / 15)[i]
    log_weights <- c(0, sum(log(1:8)))[i]
    determinant <- c(160, 10800)[i] # det(X'X) and det(X'WX)
    for (restricted in c(FALSE, TRUE)) {
      effective_n <- if (restricted) 5 else 8
      expected <- .5 * (log_weights - effective_n * (log(2 * pi) + 1 + log(sse / effective_n)))
      if (restricted) expected <- expected - .5 * log(determinant)
      result <- logLik(fit, REML = restricted)
      expect_s3_class(result, "logLik")
      expect_equal(as.numeric(result), expected, tolerance = 1e-12)
      expect_equal(attr(result, "df"), 4)
      expect_equal(attr(result, "nobs"), effective_n)
      expect_equal(attr(result, "nall"), 8)
      expect_identical(result, logLik(fit$model, REML = restricted))
    }
    ml <- .5 * (log_weights - 8 * (log(2 * pi) + 1 + log(sse / 8)))
    expect_identical(logLik(fit), logLik(fit, REML = FALSE))
    expect_equal(AIC(fit), -2 * ml + 2 * 4, tolerance = 1e-12)
    expect_equal(AIC(fit, k = 3.5), -2 * ml + 3.5 * 4, tolerance = 1e-12)
    expect_equal(BIC(fit), -2 * ml + log(8) * 4, tolerance = 1e-12)
    expect_equal(nobs(fit), 8) # REML inspection did not change the fitted row count
  }
})

test_that("selected rows determine residual order, likelihood and observation counts", {
  d <- ancova_statistics_data()
  keep <- c(8, 7, 6, 4, 3, 2)
  fit <- pharma_ancova(response ~ treatment + baseline, d, weights = precision, subset = keep)
  design <- cbind(1, as.numeric(d$treatment == "B"), d$baseline)[keep, ]
  w <- d$precision[keep]
  cross_product <- crossprod(design, design * w)
  beta <- solve(cross_product, crossprod(design, d$response[keep] * w))
  expected_fit <- as.vector(design %*% beta)
  expected_residual <- d$response[keep] - expected_fit
  sse <- sum(w * expected_residual^2)
  expect_equal(unname(fitted(fit)), expected_fit, tolerance = 1e-12)
  expect_equal(unname(residuals(fit)), expected_residual, tolerance = 1e-12)
  expect_identical(names(fitted(fit)), rownames(d)[keep])
  expect_identical(names(residuals(fit)), rownames(d)[keep])
  expect_equal(nobs(fit), 6)
  expect_equal(df.residual(fit), 3)
  expect_equal(deviance(fit), sse, tolerance = 1e-12)
  expected_ml <- .5 * (sum(log(w)) - 6 * (log(2 * pi) + 1 + log(sse / 6)))
  expected_reml <- .5 * (sum(log(w)) - 3 * (log(2 * pi) + 1 + log(sse / 3)) - log(det(cross_product)))
  expect_equal(as.numeric(logLik(fit)), expected_ml, tolerance = 1e-12)
  expect_equal(as.numeric(logLik(fit, REML = TRUE)), expected_reml, tolerance = 1e-12)
  expect_equal(attr(logLik(fit), "nobs"), 6)
  expect_equal(BIC(fit), -2 * expected_ml + log(6) * 4, tolerance = 1e-12)
})

test_that("precision rescaling preserves likelihood and changes weighted SSE as expected", {
  d <- ancova_statistics_data()
  fit <- pharma_ancova(response ~ treatment + baseline, d, weights = precision)
  scaled <- pharma_ancova(response ~ treatment + baseline, d, weights = 13 * precision)
  for (method in list(fitted, residuals, nobs, df.residual, AIC, BIC)) {
    expect_equal(method(scaled), method(fit), tolerance = 1e-12)
  }
  expect_equal(deviance(scaled), 13 * deviance(fit), tolerance = 1e-12)
  expect_equal(residuals(scaled, type = "pearson"), sqrt(13) * residuals(fit, type = "pearson"), tolerance = 1e-12)
  expect_equal(logLik(scaled), logLik(fit), tolerance = 1e-12)
  expect_equal(logLik(scaled, REML = TRUE), logLik(fit, REML = TRUE), tolerance = 1e-12)
})

test_that("native multi-model criteria and unequal-population warnings remain available", {
  d <- ancova_statistics_data()
  fit <- pharma_ancova(response ~ treatment + baseline, d)
  reduced <- stats::lm(response ~ treatment, d)
  expected_ll <- -4 * (log(2 * pi) + 1 + log(c(18, 108) / 8))
  aic <- AIC(fit, reduced)
  bic <- BIC(fit, reduced)
  expect_identical(colnames(aic), c("df", "AIC"))
  expect_identical(colnames(bic), c("df", "BIC"))
  expect_equal(aic$df, c(4, 3))
  expect_equal(aic$AIC, -2 * expected_ll + 2 * c(4, 3), tolerance = 1e-12)
  expect_equal(bic$BIC, -2 * expected_ll + log(8) * c(4, 3), tolerance = 1e-12)
  smaller <- pharma_ancova(response ~ treatment + baseline, d, subset = c(8, 7, 6, 4, 3, 2))
  expect_warning(AIC(fit, smaller), "same number of observations")
  expect_warning(BIC(fit, smaller), "same number of observations")
})

test_that("saved fits expose statistics without refitting, mutation or RNG draws", {
  d <- ancova_statistics_data()
  formula <- stats::as.formula("response ~ treatment + baseline", env = baseenv())
  fit <- pharma_ancova(formula, d, weights = precision, subset = c(8, 7, 6, 4, 3, 2))
  methods <- list(fitted, residuals, nobs, df.residual, deviance, logLik, AIC, BIC)
  expected <- lapply(methods, function(method) method(fit$model))
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
  set.seed(526)
  seed <- .Random.seed
  expect_identical(lapply(methods, function(method) method(restored)), expected)
  expect_identical(summary(restored), summary(fit))
  expect_identical(predict(restored), predict(fit))
  expect_identical(.Random.seed, seed)
  expect_identical(restored, fit)
  for (bad in list(NULL, list(), structure(list(), class = c("glm", "lm")), structure(list(), class = c("mlm", "lm")))) {
    invalid <- restored
    invalid$model <- bad
    for (method in methods) {
      expect_error(method(invalid), "saved additive model must be an lm")
    }
  }
})
