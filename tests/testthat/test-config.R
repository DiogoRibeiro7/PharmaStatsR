test_that("pharma_config sets and retrieves options", {
  original <- getOption("pharma")
  on.exit(base::options(pharma = original), add = TRUE)
  pharma_config(log_level = "DEBUG", default_ci = 0.9)
  cfg <- pharma_config()
  expect_equal(cfg$log_level, "DEBUG")
  expect_equal(cfg$default_ci, 0.9)
})

test_that("with_pharma_config temporarily sets options", {
  original <- getOption("pharma")
  on.exit(base::options(pharma = original), add = TRUE)
  with_pharma_config(list(log_level = "ERROR"), {
    expect_equal(pharma_config()$log_level, "ERROR")
  })
  expect_identical(getOption("pharma"), original)
})

test_that("with_pharma_config restores an unset option on success and error", {
  original <- getOption("pharma")
  on.exit(base::options(pharma = original), add = TRUE)
  base::options(pharma = NULL)

  value <- with_pharma_config(list(log_level = "DEBUG"), {
    pharma_config()$log_level
  })
  expect_identical(value, "DEBUG")
  expect_null(getOption("pharma"))

  expect_error(
    with_pharma_config(list(log_level = "ERROR"), stop("example failure")),
    "example failure"
  )
  expect_null(getOption("pharma"))
})

test_that("with_pharma_config preserves a partial option on a failed update", {
  original <- getOption("pharma")
  on.exit(base::options(pharma = original), add = TRUE)
  base::options(pharma = list(log_level = "WARN"))

  expect_error(
    with_pharma_config(list(unknown = TRUE), 1),
    "Unknown option"
  )
  expect_identical(getOption("pharma"), list(log_level = "WARN"))
})

test_that("core defaults are positive integers when detection fails", {
  expect_identical(PharmaStatsR:::.pharma_default_max_cores(NA_integer_), 1L)
  expect_identical(PharmaStatsR:::.pharma_default_max_cores(0L), 1L)
  expect_identical(PharmaStatsR:::.pharma_default_max_cores(1L), 1L)
  expect_identical(PharmaStatsR:::.pharma_default_max_cores(4L), 3L)
})

test_that("configuration uses a usable default core count", {
  original <- getOption("pharma")
  on.exit(options(pharma = original), add = TRUE)
  options(pharma = NULL)
  cores <- pharma_config()$max_cores
  expect_type(cores, "integer")
  expect_gte(cores, 1L)
})
