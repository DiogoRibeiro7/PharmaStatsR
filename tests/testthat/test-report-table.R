test_that("pharma_report_table returns tidy data frame", {
  set.seed(1)
  data <- data.frame(response = rnorm(10), treatment = rep(c("A", "B"), each = 5))
  fit <- lm(response ~ treatment, data = data)
  tbl <- pharma_report_table(fit)
  expect_s3_class(tbl, "data.frame")
  expect_true(all(c("term", "estimate", "conf.low", "conf.high", "p.value") %in% names(tbl)))
})

test_that("pharma_report_table errors when writing without dependencies", {
  skip_if(requireNamespace("openxlsx", quietly = TRUE))
  set.seed(1)
  data <- data.frame(response = rnorm(10), treatment = rep(c("A", "B"), each = 5))
  fit <- lm(response ~ treatment, data = data)
  tmp <- tempfile(fileext = ".xlsx")
  expect_error(pharma_report_table(fit, file = tmp), "openxlsx")
})

test_that("pharma_report_table writes Excel file when openxlsx available", {
  skip_if_not_installed("openxlsx")
  set.seed(1)
  data <- data.frame(response = rnorm(10), treatment = rep(c("A", "B"), each = 5))
  fit <- lm(response ~ treatment, data = data)
  tmp <- tempfile(fileext = ".xlsx")
  expect_silent(pharma_report_table(fit, file = tmp))
  expect_true(file.exists(tmp))
})
