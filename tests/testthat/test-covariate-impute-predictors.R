local_edition(3)

test_that("explicit predictors restrict distances and retain the table", {
  d <- data.frame(
    SubjectID = c(1, 1000, 1000), DV = c(0, 10000, 10000),
    y = c(10, 20, NA), x = c(0, 10, 0),
    row.names = c("first", "second", "third")
  )
  original <- d
  # The historical default includes SubjectID and DV in neighbor distances.
  expect_identical(impute_ml(d, "y", 1)$y, c(10, 20, 20))
  expect_identical(impute_ml(d, "y", 1, predictors = NULL)$y, c(10, 20, 20))
  expected <- d
  expected$y[3] <- 10
  expect_identical(impute_ml(d, "y", 1, predictors = "x"), expected)
  expect_identical(d, original)

  # Excluded columns may contain values or types unsuitable for imputation.
  d$DV <- c(Inf, -Inf, NA)
  d$notes <- I(list(list(source = "a"), "b", NULL))
  expected <- d
  expected$y[3] <- 10
  expect_identical(impute_ml(d, "y", 1, predictors = "x"), expected)
  expect_identical(original$y, c(10, 20, NA_real_))
  expect_identical(d$y, original$y)
})

test_that("predictor selection matches the existing subset workflow", {
  d <- data.frame(
    SubjectID = c(1000, 1, 1000, 1),
    a = c(0, NA, 10, 20), b = c(0, 10, NA, 20), x = c(0, 1, 2, 3)
  )
  selected <- c("a", "b", "x")
  for (targets in list(c("a", "b"), c("b", "a"))) {
    expected <- d
    expected[selected] <- impute_ml(d[selected], targets, k = 1)
    expect_identical(
      impute_ml(d, targets, k = 1, predictors = selected), expected
    )
    expect_identical(
      impute_ml(d, targets, k = 1, predictors = names(d)),
      impute_ml(d, targets, k = 1)
    )
  }
})

test_that("other targets are not implicitly added to an explicit selection", {
  d <- data.frame(a = c(10, 20, NA), b = c(100, NA, 300), x = c(0, 10, 0))
  expected <- data.frame(a = c(10, 20, 10), b = c(100, 100, 300), x = d$x)
  for (targets in list(c("a", "b"), c("b", "a"))) {
    expect_identical(
      impute_ml(d, targets, k = 1, predictors = "x"), expected
    )
  }
})

test_that("self-selection and an empty predictor pool do not invent donors", {
  d <- data.frame(y = c(10, 20, NA), x = c(0, 10, 0))
  expect_identical(
    impute_ml(d, "y", k = 1, predictors = c("y", "x")),
    impute_ml(d, "y", k = 1, predictors = "x")
  )
  for (selection in list("y", character(0))) {
    expect_warning(
      result <- impute_ml(d, "y", predictors = selection),
      "No predictor columns available for 'y'"
    )
    expect_identical(result, d)
  }
  complete <- data.frame(y = 1:3, x = 4:6)
  expect_no_warning(
    result <- impute_ml(complete, "y", predictors = character(0))
  )
  expect_identical(result, complete)
  expect_no_warning(result <- impute_ml(d, character(0), predictors = "x"))
  expect_identical(result, d)
})

test_that("predictor names are validated with no missing target", {
  d <- data.frame(y = 1:3, x = 4:6)
  invalid <- list(
    1, TRUE, numeric(0), list("x"), matrix("x"), c("x", NA),
    c("x", "x")
  )
  for (selection in invalid) {
    expect_error(
      impute_ml(d, "y", predictors = selection),
      "`predictors` must be a character vector of unique column names"
    )
  }
  expect_error(
    impute_ml(d, "y", predictors = "missing"), "Predictors not found"
  )
  expect_error(
    impute_ml(d, character(0), predictors = "missing"), "Predictors not found"
  )
  d$y[3] <- NA
  expect_identical(
    impute_ml(d, "y", k = 1, predictors = c(selected = "x"))$y, c(1, 2, 2)
  )
})

test_that("selected predictors are validated when imputation uses them", {
  d <- data.frame(y = c(1, NA, 3), x = c(1, Inf, 3))
  expect_error(impute_ml(d, "y", predictors = "x"), "infinite values")
  d$x <- I(list(1, 2, 3))
  expect_error(
    impute_ml(d, "y", predictors = "x"),
    "numeric, logical, character, or factor"
  )
  d$y <- 1:3
  expect_identical(impute_ml(d, "y", predictors = "x"), d)
  d$y <- NA_real_
  expect_warning(
    result <- impute_ml(d, "y", predictors = "x"), "contains only NA"
  )
  expect_identical(result, d)
})

test_that("explicit predictors retain categorical types and missing behavior", {
  d <- data.frame(
    group = factor(c("b", NA, "a"), levels = c("a", "b", "unused")),
    x = c(0, 1, 2), unrelated = c(10000, 0, 0)
  )
  expected <- d
  expected$group[2] <- "b"
  expect_identical(impute_ml(d, "group", k = 1, predictors = "x"), expected)
  numeric_data <- data.frame(
    y = c(10, NA, 30), x = c(0, NA, 2), unrelated = 1:3
  )
  expected <- numeric_data
  expected$y[2] <- 10
  expect_identical(
    impute_ml(numeric_data, "y", k = 1, predictors = "x"), expected
  )
  numeric_data$x <- NA_real_
  expected <- numeric_data
  expected$y[2] <- 10
  expect_identical(
    impute_ml(numeric_data, "y", k = 1, predictors = "x"), expected
  )
})

test_that("explicit predictors use literal names", {
  d <- data.frame(y = c(10, 20, NA), x = c(0, 10, 0))
  names(d) <- c("target value", "x + y")
  expect_identical(
    impute_ml(d, "target value", k = 1, predictors = "x + y")[["target value"]],
    c(10, 20, 10)
  )
})
