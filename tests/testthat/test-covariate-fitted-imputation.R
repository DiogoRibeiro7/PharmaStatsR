local_edition(3)

test_that("training replacements match fixed arithmetic references", {
  training <- data.frame(x = c(1, NA, 3, 8), z = c(-2, 2, 6, 10))
  original <- training
  # Observed x sum is 12 across three values; the middle sorted value is 3.
  # The four observed z values have sum 16 and middle pair (2, 6).
  for (method in c("mean", "median")) {
    expected <- if (method == "mean") c(4, 4) else c(3, 4)
    params <- fit_imputation(training, c("x", "z"), method)
    expect_identical(params, data.frame(
      var = c("x", "z"), value = expected, method = rep(method, 2)
    ))
    completed <- training
    completed$x[2] <- expected[1]
    expect_identical(apply_imputation(training, params), completed)
    legacy <- if (method == "mean") impute_mean else impute_median
    expect_identical(completed, legacy(training, c("x", "z")))
  }
  expect_identical(training, original)
})

test_that("held-out values cannot affect fitted replacements", {
  params <- fit_imputation(data.frame(x = c(1, 3, 8)), "x")
  original <- params
  validation <- data.frame(x = c(NA, 100, NaN), outcome = c(999, NA, -1))
  completed <- apply_imputation(validation, params)
  expect_identical(completed$x, c(4, 100, 4))
  expect_identical(completed$outcome, validation$outcome)
  perturbed <- validation
  perturbed$x[2] <- -1e20
  expect_identical(apply_imputation(perturbed, params)$x[c(1, 3)], c(4, 4))
  augmented <- rbind(validation, data.frame(x = 1e20, outcome = 2))
  expect_identical(apply_imputation(augmented, params)[1:3, ], completed)
  expect_identical(params, original)
  expect_identical(validation$x, c(NA_real_, 100, NaN))
  expect_false(identical(impute_mean(validation, "x")$x, completed$x))
})

test_that("separate subject folds fit on training observations only", {
  d <- data.frame(
    SubjectID = rep(1:3, each = 2), x = c(1, NA, 3, NA, 8, NA)
  )
  completed <- d
  expected_means <- c(5.5, 4.5, 2)
  for (subject in 1:3) {
    held_out <- d$SubjectID == subject
    training <- d[!held_out, , drop = FALSE]
    params <- fit_imputation(training, "x")
    expect_equal(params$value, expected_means[subject])
    result <- apply_imputation(d[held_out, , drop = FALSE], params)
    expect_identical(result$SubjectID, rep(subject, 2))
    completed$x[held_out] <- result$x
  }
  expect_identical(completed$x, c(1, 5.5, 3, 4.5, 8, 2))
  expect_identical(completed$SubjectID, d$SubjectID)
})

test_that("fitted imputation composes with saved scaling", {
  training <- data.frame(x = c(1, 3, 8, NA))
  imputation <- fit_imputation(training, "x")
  fitted <- center_scale(apply_imputation(training, imputation), "x")
  # Completed training values are (1, 3, 8, 4); mean 4, sum of squares 26.
  expect_equal(fitted$params$mean, 4)
  expect_equal(fitted$params$sd, sqrt(26 / 3))
  validation <- apply_imputation(data.frame(x = c(NA, 10)), imputation)
  actual <- apply_center_scale(validation, fitted$params)
  expect_equal(actual$x, c(0, 6 / sqrt(26 / 3)))
})

test_that("literal names and saved tables preserve row and column identity", {
  training <- data.frame(x = c(1, 3, 8), y = c(2, 4, 9))
  names(training) <- c("weight (kg)", "a+b")
  params <- fit_imputation(training, c("a+b", "weight (kg)"), "median")
  validation <- training[c(3, 1), c(2, 1)]
  validation[["a+b"]][1] <- NA_real_
  validation[["weight (kg)"]][2] <- NA_real_
  validation$untouched <- I(list(Inf, "text"))
  rownames(validation) <- c("later", "earlier")
  expected <- validation
  expected[["a+b"]][1] <- 4
  expected[["weight (kg)"]][2] <- 3
  original <- validation
  params <- params[2:1, c("method", "value", "var")]
  params$metadata <- "training"
  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(saved))
  saveRDS(params, saved)
  expect_identical(apply_imputation(validation, readRDS(saved)), expected)
  expect_identical(validation, original)
  expect_identical(params, readRDS(saved))
  expect_identical(apply_imputation(validation, params[c("var", "value")]), expected)
})

test_that("new data may be empty or entirely missing", {
  params <- fit_imputation(data.frame(x = c(2, 4)), "x")
  for (values in list(numeric(), NA_real_, c(NA_real_, NaN), c(7, 7))) {
    expected <- values
    expected[is.na(expected)] <- 3
    expect_identical(apply_imputation(data.frame(x = values), params)$x, expected)
  }
  for (values in list(5, c(5, 5, NA))) {
    expect_equal(fit_imputation(data.frame(x = values), "x")$value, 5)
  }
  expect_equal(fit_imputation(data.frame(x = c(2, NaN, 4)), "x")$value, 3)
})

test_that("empty selections produce reusable empty tables", {
  for (vars in list(character(0), NULL)) {
    params <- fit_imputation(data.frame(x = c(1, NA)), vars)
    expect_identical(params, data.frame(
      var = character(), value = numeric(), method = character()
    ))
    expect_identical(
      apply_imputation(data.frame(x = c(1, NA)), params),
      data.frame(x = c(1, NA))
    )
    expect_identical(apply_imputation(data.frame(), params), data.frame())
  }
})

test_that("numeric replacements retain fractional and large finite values", {
  params <- fit_imputation(data.frame(x = c(1L, 2L)), "x")
  expect_identical(
    apply_imputation(data.frame(x = c(NA_integer_, 4L)), params)$x,
    c(1.5, 4)
  )
  expect_identical(apply_imputation(data.frame(x = 4L), params)$x, 4L)
  for (method in c("mean", "median")) {
    large <- fit_imputation(data.frame(x = c(1e308, 1e308)), "x", method)
    expect_equal(large$value, 1e308)
    expect_equal(apply_imputation(data.frame(x = NA_real_), large)$x, 1e308)
  }
})

test_that("fitting requires observed training values and a known method", {
  for (values in list(numeric(), NA_real_, c(NA_real_, NaN))) {
    expect_error(
      fit_imputation(data.frame(x = values), "x"),
      "at least one observed training value"
    )
  }
  expect_error(fit_imputation(data.frame(x = 1), "x", "mode"), "arg")
  expect_error(fit_imputation(data.frame(x = 1), "missing"), "Variables not found")
  for (vars in list(c("x", "x"), NA_character_, 1, matrix("x"))) {
    expect_error(fit_imputation(data.frame(x = 1), vars), "unique column names")
  }
})

test_that("invalid data and selected column types are rejected before applying", {
  params <- data.frame(var = "x", value = 4)
  for (column in list(Inf, -Inf, "1", TRUE, factor("a"), 1i, I(matrix(1)))) {
    d <- data.frame(x = 1)
    d$x <- column
    expect_error(fit_imputation(d, "x"), "must be numeric|infinite values")
    expect_error(apply_imputation(d, params), "must be numeric|infinite values")
  }
  expect_error(apply_imputation(data.frame(y = 1), params), "Variables not found")
  for (d in list(NULL, list(x = 1), matrix(1))) {
    expect_error(fit_imputation(d, "x"), "data.frame")
    expect_error(apply_imputation(d, params), "data.frame")
  }
  for (bad_name in c("", NA_character_, "x")) {
    d <- data.frame(x = 1, z = 2)
    names(d)[2] <- bad_name
    expect_error(fit_imputation(d, "x"), "column names")
    expect_error(apply_imputation(d, params), "column names")
  }
})

test_that("invalid parameter tables are rejected even for complete data", {
  d <- data.frame(x = 1)
  valid <- data.frame(var = "x", value = 4)
  for (params in list(NULL, as.matrix(valid), as.list(valid))) {
    expect_error(apply_imputation(d, params), "params.*data.frame")
  }
  for (column in names(valid)) {
    expect_error(
      apply_imputation(d, valid[setdiff(names(valid), column)]),
      "must contain"
    )
  }
  for (name in c("", NA_character_, "var")) {
    params <- valid
    names(params)[2] <- name
    expect_error(apply_imputation(d, params), "column names")
  }
  for (name in list("", NA_character_, 1, factor("x"), matrix("x"))) {
    params <- valid
    params$var <- name
    expect_error(apply_imputation(d, params), "variable names")
  }
  expect_error(apply_imputation(d, rbind(valid, valid)), "variable names")
  for (value in list(NA_real_, NaN, Inf, -Inf, TRUE, "4", 1i, list(4), matrix(4))) {
    params <- valid
    params$value <- value
    expect_error(apply_imputation(d, params), "finite real numbers")
  }
})
