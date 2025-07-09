test_that("audit log creates file", {
  f <- tempfile()
  key <- "secret"
  pharma_audit_log("start", f, key = key)
  expect_true(file.exists(f))
  pharma_audit_log("next", f, key = key)
  log <- read.csv(f)
  expect_equal(nrow(log), 3)
})

test_that("audit log verifies chain", {
  f <- tempfile()
  key <- "secret"
  pharma_audit_log("start", f, key = key)
  pharma_audit_log("step2", f, key = key)
  expect_true(pharma_audit_verify(f, key = key))
  log <- read.csv(f)
  log$previous_hash[3] <- "tampered"
  write.csv(log, f, row.names = FALSE)
  expect_false(pharma_audit_verify(f, key = key))
})

test_that("modifying a log entry breaks verification", {
  f <- tempfile()
  key <- "secret"
  pharma_audit_log("start", f, key = key)
  pharma_audit_log("step2", f, key = key)
  log <- read.csv(f)
  log$step[2] <- "changed"
  write.csv(log, f, row.names = FALSE)
  expect_false(pharma_audit_verify(f, key = key))
})
