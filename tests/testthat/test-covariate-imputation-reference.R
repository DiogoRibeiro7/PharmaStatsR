local_edition(3)

test_that("location replacements match fixed mean and median references", {
  # x: observed sum 12 / 3, median 3. z: sum 16 / 4, middle pair (2, 6).
  for (unit in c(1, 1e200, 1e-200)) {
    for (direction in c(1, -1)) {
      d <- data.frame(x = c(1, NA, 3, 8, NaN, NA), z = c(-2, 2, 6, 10, NA, NaN))
      d[] <- lapply(d, function(x) direction * unit * x)
      names(d) <- c("body mass", "x+y")
      d$group <- factor(letters[1:6])
      rownames(d) <- paste0("row-", 6:1)
      original <- d
      for (method in c("mean", "median")) {
        expected <- direction * if (method == "mean") c(4, 4) else c(3, 4)
        fit <- fit_imputation(d, names(d)[1:2], method)
        legacy <- if (method == "mean") impute_mean else impute_median
        filled <- legacy(d, names(d)[1:2])
        expect_equal(fit$value / unit, expected, tolerance = 1e-14)
        expect_identical(fit$var, names(d)[1:2])
        expect_identical(fit$method, rep(method, 2))
        for (j in 1:2) {
          missing <- is.na(d[[j]])
          expect_equal(filled[[j]][missing] / unit, rep(expected[j], sum(missing)), tolerance = 1e-14)
          expect_identical(filled[[j]][!missing], d[[j]][!missing])
        }
        expect_identical(apply_imputation(d, fit), filled)
        expect_identical(filled$group, d$group)
        expect_identical(rownames(filled), rownames(d))
        expect_identical(names(filled), names(d))
        expect_identical(d, original)
      }
    }
  }
})

test_that("extreme signed locations remain finite with missing and reordered rows", {
  unit <- 1e308
  for (direction in c(1, -1)) {
    d <- data.frame(x = direction * unit * c(-1.5, 1.5, 1.5, 1.5, 1.5, NA, NaN))
    for (rows in list(1:7, c(7, 3, 1, 6, 5, 2, 4))) {
      training <- d[rows, , drop = FALSE]
      for (method in c("mean", "median")) {
        # Five observed values have mean .9 and median 1.5, before units/sign.
        expected <- direction * if (method == "mean") 0.9 else 1.5
        fit <- fit_imputation(training, "x", method)
        legacy <- if (method == "mean") impute_mean else impute_median
        actual <- legacy(training, "x")
        expect_equal(fit$value / unit, expected, tolerance = 1e-14)
        expect_true(all(is.finite(actual$x)))
        expect_equal(actual$x[is.na(training$x)] / unit, rep(expected, 2), tolerance = 1e-14)
        expect_identical(actual$x[!is.na(training$x)], training$x[!is.na(training$x)])
        expect_identical(apply_imputation(training, fit), actual)
        new <- data.frame(x = c(NA, 0.2 * unit, NaN))
        expect_equal(apply_imputation(new, fit)$x / unit, c(expected, 0.2, expected), tolerance = 1e-14)
      }
    }
  }
})

test_that("saved extreme location parameters are independent of new batches", {
  fit <- fit_imputation(data.frame(x = c(-1.5, 1.5, 1.5, 1.5, 1.5) * 1e308), "x")
  file <- tempfile(fileext = ".rds")
  on.exit(unlink(file))
  saveRDS(fit, file)
  restored <- readRDS(file)
  new <- data.frame(x = c(NA_real_, 1e308, NaN))
  original <- new
  result <- apply_imputation(new, restored)
  expect_equal(result$x / 1e308, c(0.9, 1, 0.9), tolerance = 1e-14)
  expect_identical(apply_imputation(rbind(new, data.frame(x = -1.7e308)), restored)$x[1:3], result$x)
  expect_identical(restored, fit)
  expect_identical(new, original)
})

test_that("legacy neighbor means use the selected finite donors", {
  for (direction in c(1, -1)) {
    d <- data.frame(y = direction * 1e308 * c(-1.5, 1.5, 1.5, 1.5, 1.5, NA, NaN), x = 0)
    original <- d
    for (distance in c("euclidean", "gower")) {
      for (k in c(3, 5, 99)) {
        # All distances tie: the first three donors average .5, all five .9.
        expected <- direction * if (k == 3) 0.5 else 0.9
        result <- impute_ml(d, "y", k, predictors = "x", distance = distance)
        expect_equal(result$y[6:7] / 1e308, rep(expected, 2), tolerance = 1e-14)
        expect_true(all(is.finite(result$y)))
        expect_identical(result$y[1:5], d$y[1:5])
        expect_identical(result$x, d$x)
        expect_identical(d, original)
      }
    }
  }
})

test_that("saved neighbor means remain finite and retain training-only donors", {
  file <- tempfile(fileext = ".rds")
  on.exit(unlink(file))
  for (direction in c(1, -1)) {
    training <- data.frame(y = direction * 1e308 * c(-1.5, 1.5, 1.5, 1.5, 1.5), x = 0)
    for (k in c(3, 5, 99)) {
      model <- fit_knn_imputation(training, "y", "x", k = k)
      saveRDS(model, file)
      restored <- readRDS(file)
      new <- data.frame(y = c(NA, NaN, 0.2e308), x = 0)
      original <- new
      result <- apply_knn_imputation(new, restored)
      expected <- direction * if (k == 3) 0.5 else 0.9
      expect_equal(result$y / 1e308, c(expected, expected, 0.2), tolerance = 1e-14)
      expect_true(all(is.finite(result$y)))
      expect_identical(apply_knn_imputation(rbind(new, data.frame(y = -1e308, x = 0)), restored)$y[1:3], result$y)
      expect_identical(restored, model)
      expect_identical(new, original)
    }
  }
})

test_that("Euclidean predictor filling uses a finite observed mean", {
  for (direction in c(1, -1)) {
    d <- data.frame(y = c(10, 20, 30, 40, 50, 60, NA), x = direction * 1e308 * c(-1.5, 1.5, 1.5, 1.5, 1.5, NA, 0))
    # The six observed x values average .75 units. Filling donor 6's x makes
    # it closest to recipient x=0; every other donor is 1.5 units away.
    result <- impute_ml(d, "y", 1, predictors = "x")
    expect_identical(result$y, c(10, 20, 30, 40, 50, 60, 60))
    expect_identical(result$x, d$x)
    # Gower omits that missing pair instead: original donor 1 wins the tie.
    expect_equal(impute_ml(d, "y", 1, predictors = "x", distance = "gower")$y[7], 10)
  }
})

test_that("ordinary means and all-missing policies are preserved", {
  d <- data.frame(x = c(0.1, 0.3, 0.9, 1.4, NA, NaN))
  expected <- mean(d$x, na.rm = TRUE)
  expect_identical(fit_imputation(d, "x")$value, expected)
  expect_identical(impute_mean(d, "x")$x[5:6], rep(expected, 2))
  missing <- data.frame(x = c(NA_real_, NaN))
  expect_warning(result <- impute_mean(missing, "x"), "contains only NA")
  expect_identical(result, missing)
  expect_error(fit_imputation(missing, "x"), "at least one observed")
  # An entirely missing Euclidean predictor still uses internal zero filling.
  d <- data.frame(y = c(2, 4, NA), x = NA_real_)
  expect_identical(impute_ml(d, "y", 2, predictors = "x")$y, c(2, 4, 3))
})
