test_that("pharma_log enforces log levels", {
  original <- pharma_config()
  on.exit(do.call(pharma_config, original))
  pharma_config(log_level = "WARN")
  expect_message(pharma_log("ERROR", "problem"), "problem")
  expect_silent(pharma_log("INFO", "ignore"))
  expect_error(pharma_log("UNKNOWN", "msg"), "Unknown log level")
})

test_that("pharma_progress returns NULL when non-interactive", {
  expect_null(pharma_progress(10))
})
