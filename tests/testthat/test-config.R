test_that("pharma_config sets and retrieves options", {
  original <- pharma_config()
  on.exit(do.call(pharma_config, original))
  pharma_config(log_level = "DEBUG", default_ci = 0.9)
  cfg <- pharma_config()
  expect_equal(cfg$log_level, "DEBUG")
  expect_equal(cfg$default_ci, 0.9)
})

test_that("with_pharma_config temporarily sets options", {
  original <- pharma_config()
  with_pharma_config(list(log_level = "ERROR"), {
    expect_equal(pharma_config()$log_level, "ERROR")
  })
  expect_equal(pharma_config()$log_level, original$log_level)
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
