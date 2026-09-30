report_table_fit <- function() {
  data <- data.frame(
    response = c(1, 2, 3, 4, 5, 2, 3, 4, 5, 6),
    treatment = factor(rep(c("A", "B"), each = 5))
  )
  stats::lm(response ~ treatment, data = data)
}

test_that("pharma_report_table returns five tidy columns without exporters", {
  testthat::local_mocked_bindings(
    .pharma_report_package_available = function(package) FALSE
  )
  tbl <- pharma_report_table(report_table_fit())
  expect_s3_class(tbl, "data.frame")
  expect_identical(names(tbl),
                   c("term", "estimate", "conf.low", "conf.high", "p.value"))
  expect_identical(tbl$term, c("(Intercept)", "treatmentB"))
})

test_that("missing Excel exporter gives an actionable error", {
  testthat::local_mocked_bindings(
    .pharma_report_package_available = function(package) package != "openxlsx"
  )
  path <- tempfile(fileext = ".xlsx")
  expect_error(pharma_report_table(report_table_fit(), file = path),
               "optional package\\(s\\): openxlsx")
  expect_false(file.exists(path))
})

test_that("missing Word exporters are reported individually", {
  check_missing <- function(missing) {
    testthat::local_mocked_bindings(
      .pharma_report_package_available = function(package) package != missing
    )
    path <- tempfile(fileext = ".docx")
    expect_error(pharma_report_table(report_table_fit(), file = path),
                 paste0("optional package\\(s\\): ", missing))
    expect_false(file.exists(path))
  }
  for (missing in c("flextable", "officer")) {
    check_missing(missing)
  }
})

test_that("Excel export contains the reported terms and estimates", {
  skip_if_not_installed("openxlsx")
  path <- tempfile(fileext = ".xlsx")
  on.exit(unlink(path), add = TRUE)
  tbl <- pharma_report_table(report_table_fit())
  returned <- pharma_report_table(report_table_fit(), file = path)
  expect_identical(returned, tbl)
  expect_true(file.exists(path))
  saved <- openxlsx::read.xlsx(path)
  expect_identical(names(saved), names(tbl))
  expect_identical(saved$term, tbl$term)
  expect_equal(saved$estimate, tbl$estimate, tolerance = 1e-10)
})

test_that("Word export contains the reported table", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("officer")
  path <- tempfile(fileext = ".docx")
  on.exit(unlink(path), add = TRUE)
  tbl <- pharma_report_table(report_table_fit())
  returned <- pharma_report_table(report_table_fit(), file = path)
  expect_identical(returned, tbl)
  expect_true(file.exists(path))
  content <- officer::docx_summary(officer::read_docx(path))
  cells <- content$text[content$content_type == "table cell"]
  expect_true(all(names(tbl) %in% cells))
  expect_true(all(tbl$term %in% cells))
})
