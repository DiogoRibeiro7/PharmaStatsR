local_edition(3)

test_that("saved parameters transform new data without refitting", {
  training <- data.frame(x = c(10, 20, 30), y = c(2, 4, 6))
  fitted <- center_scale(training, c("x", "y"))
  validation <- data.frame(x = c(40, 50), y = c(8, 10))
  actual <- apply_center_scale(validation, fitted$params)
  expect_equal(actual, data.frame(x = c(2, 3), y = c(2, 3)))
  expect_identical(apply_center_scale(training, fitted$params), fitted$data)
  reference <- scale(
    as.matrix(validation),
    center = fitted$params$mean, scale = fitted$params$sd
  )
  expect_equal(as.matrix(actual), reference, ignore_attr = TRUE)
  refitted <- center_scale(validation, c("x", "y"))$data
  expect_false(isTRUE(all.equal(actual, refitted)))

  # Adding unrelated validation rows cannot change an existing prediction row.
  augmented <- rbind(validation, data.frame(x = 1e6, y = -1e6))
  expect_identical(apply_center_scale(augmented, fitted$params)[1:2, ], actual)
})

test_that("parameter names control matching and preserve table structure", {
  training <- data.frame(a = c(1, 3, 5), b = c(20, 30, 40))
  names(training) <- c("weight (kg)", "a+b")
  fitted <- center_scale(training, c("a+b", "weight (kg)"))
  validation <- training[c(3, 1), c(2, 1)]
  validation$SubjectID <- c("second", "first")
  validation$untouched <- I(list(Inf, "text"))
  rownames(validation) <- c("row-z", "row-a")
  expected <- validation
  expected[["a+b"]] <- c(1, -1)
  expected[["weight (kg)"]] <- c(1, -1)
  params <- fitted$params[2:1, c("sd", "var", "mean")]
  params$metadata <- "training"
  original_data <- validation
  original_params <- params
  expect_identical(apply_center_scale(validation, params), expected)
  expect_identical(validation, original_data)
  expect_identical(params, original_params)
})

test_that("new data need not support estimating its own parameters", {
  params <- center_scale(data.frame(x = c(1, 3, 5)), "x")$params
  for (values in list(numeric(), 7, c(7, 7), c(NA_real_, NaN))) {
    expected <- data.frame(x = (values - 3) / 2)
    expect_identical(
      apply_center_scale(data.frame(x = values), params), expected
    )
  }
  d <- data.frame(x = c(7, NA_real_, NaN, 1))
  expect_identical(apply_center_scale(d, params)$x, c(2, NA_real_, NaN, -1))
  empty <- center_scale(d, character(0))$params
  expect_identical(apply_center_scale(d, empty), d)
  expect_identical(apply_center_scale(data.frame(), empty), data.frame())
})

test_that("integer and extreme values scale without avoidable overflow", {
  params <- data.frame(var = "x", mean = -2147483647L, sd = 2147483647L)
  expect_equal(
    apply_center_scale(data.frame(x = 2147483647L), params)$x, 2
  )
  params$mean <- -1e308
  params$sd <- 1e308
  expect_equal(apply_center_scale(data.frame(x = 1e308), params)$x, 2)
  params$mean <- 1e308
  expect_equal(apply_center_scale(data.frame(x = -1e308), params)$x, -2)
  params$mean <- 0
  params$sd <- 1e-300
  expect_equal(apply_center_scale(data.frame(x = 2e-300), params)$x, 2)
  expect_error(
    apply_center_scale(data.frame(x = 1e308), params), "cannot be represented"
  )
  params$mean <- -1e308
  params$sd <- 1
  expect_error(
    apply_center_scale(data.frame(x = 1e308), params), "cannot be represented"
  )
})

test_that("invalid parameter tables produce clear errors", {
  d <- data.frame(x = 1:3)
  valid <- center_scale(d, "x")$params
  invalid_tables <- list(
    NULL, list(var = "x", mean = 2, sd = 1), as.matrix(valid)
  )
  for (params in invalid_tables) {
    expect_error(apply_center_scale(d, params), "must be a data.frame")
  }
  for (column in names(valid)) {
    expect_error(
      apply_center_scale(d, valid[setdiff(names(valid), column)]),
      "must contain"
    )
  }
  for (name in c("", NA_character_, "mean")) {
    params <- valid
    names(params)[1] <- name
    expect_error(apply_center_scale(d, params), "column names")
  }
  for (variables in list(NA_character_, "", factor("x"), 1, matrix("x"))) {
    params <- valid
    params$var <- variables
    expect_error(apply_center_scale(d, params), "variable names")
  }
  expect_error(apply_center_scale(d, rbind(valid, valid)), "variable names")
  for (column in c("mean", "sd")) {
    invalid <- list(NA_real_, NaN, Inf, -Inf, "1", TRUE, 1i, list(1), matrix(1))
    for (value in invalid) {
      params <- valid
      params[[column]] <- value
      expect_error(apply_center_scale(d, params), "finite real numbers")
    }
  }
  for (value in c(0, -1)) {
    params <- valid
    params$sd <- value
    expect_error(apply_center_scale(d, params), "positive, finite")
  }
})

test_that("selected new columns follow numeric preprocessing validation", {
  params <- center_scale(data.frame(x = 1:3), "x")$params
  expect_error(apply_center_scale(list(x = 1), params), "must be a data.frame")
  expect_error(
    apply_center_scale(data.frame(y = 1), params), "Variables not found"
  )
  for (value in list("1", TRUE, factor("a"), 1i, list(1), matrix(1))) {
    d <- data.frame(x = 1)
    d$x <- value
    expect_error(apply_center_scale(d, params), "must be numeric")
  }
  for (value in c(Inf, -Inf)) {
    expect_error(apply_center_scale(data.frame(x = value), params), "infinite")
  }
  d <- data.frame(x = 1, y = 2)
  for (name in c("x", "", NA_character_)) {
    names(d)[2] <- name
    expect_error(apply_center_scale(d, params), "column names")
  }
})
