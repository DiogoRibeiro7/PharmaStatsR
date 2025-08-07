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
