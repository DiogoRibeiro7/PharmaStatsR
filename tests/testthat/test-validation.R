test_that("column checks report only names that exist", {
  required <- c("subject", "response")
  expect_true(pharma_check_columns(pharma_sample, required))
  expect_true(check_ich_columns(pharma_sample))

  report <- pharma_column_report(pharma_sample, "Treatment difference", required)
  expect_identical(report$estimand, "Treatment difference")
  expect_identical(report$n, nrow(pharma_sample))
  expect_identical(report$required_columns, required)
  expect_true(report$columns_present)
  expect_false("compliant" %in% names(report))

  expect_identical(
    pharma_validation_report(pharma_sample, "Treatment difference", required),
    report
  )
})

test_that("column checks reject missing and invalid inputs", {
  expect_error(
    pharma_check_columns(pharma_sample, c("subject", "not_a_column")),
    "Missing required columns: not_a_column"
  )
  expect_error(pharma_check_columns(list(subject = 1L), "subject"), "data frame")
  expect_error(pharma_check_columns(pharma_sample, character()), "required")
  expect_error(pharma_check_columns(pharma_sample, NA_character_), "required")
  expect_error(pharma_check_columns(pharma_sample, "  "), "required")
  expect_error(pharma_check_columns(pharma_sample, c("subject", "subject")), "required")
  expect_error(check_ich_columns(pharma_sample, "not_a_column"), "Missing required")
})

test_that("reports reject invalid estimand labels and missing columns", {
  expect_error(pharma_column_report(pharma_sample, ""), "estimand")
  expect_error(pharma_column_report(pharma_sample, NA_character_), "estimand")
  expect_error(pharma_column_report(pharma_sample, c("A", "B")), "estimand")
  expect_error(
    pharma_validation_report(pharma_sample, "Treatment", "not_a_column"),
    "Missing required columns"
  )
})
