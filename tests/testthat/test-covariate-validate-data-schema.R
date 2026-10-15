local_edition(3)

library(testthat)

# Valid dataset should pass
valid_data <- data.frame(
  SubjectID = c(1L, 2L),
  Time = c(0, 1),
  DV = c(1.1, 1.2),
  WT = c(70, 80)
)

test_that("validate_data_schema passes on valid data", {
  expect_true(validate_data_schema(valid_data))
})

# Missing required column
missing_col <- valid_data
missing_col$Time <- NULL

test_that("validate_data_schema fails when columns are missing", {
  expect_error(validate_data_schema(missing_col), "Missing required columns")
})

# Wrong type for SubjectID
wrong_type <- valid_data
wrong_type$SubjectID <- as.character(wrong_type$SubjectID)

test_that("validate_data_schema fails with wrong types", {
  expect_error(validate_data_schema(wrong_type), "SubjectID")
})

test_that("schema validation rejects duplicate required and covariate names", {
  for (duplicate in c("SubjectID", "Time", "DV", "WT")) {
    d <- valid_data
    d$extra <- 1:2
    names(d)[5] <- duplicate
    expect_error(validate_data_schema(d), "unique column names")
  }
})

test_that("schema columns must be vectors of the expected storage type", {
  d <- valid_data
  d$Time <- c(1 + 1i, 2 + 1i)
  expect_error(validate_data_schema(d), "`Time` must be numeric", fixed = TRUE)
  d <- valid_data
  d$SubjectID <- I(matrix(1:4, nrow = 2))
  expect_error(
    validate_data_schema(d), "`SubjectID` must be integer",
    fixed = TRUE
  )
  d <- valid_data
  d$DV[1] <- NA_real_
  expect_true(validate_data_schema(d))
})
