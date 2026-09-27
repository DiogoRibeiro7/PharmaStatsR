test_that("valid audit chains verify with the original key", {
  skip_if_not_installed("openssl")
  file <- tempfile()
  on.exit(unlink(file), add = TRUE)
  expect_identical(pharma_audit_log("start", file, key = "secret"), file)
  pharma_audit_log("NA", file, key = "secret")
  pharma_audit_log('step, with "quotes"', file, key = "secret")
  expect_true(pharma_audit_verify(file, key = "secret"))
  expect_false(pharma_audit_verify(file, key = "different"))
  expect_equal(nrow(utils::read.csv(file)), 4L)
})

test_that("altered links, genesis metadata and invalid CSV fail closed", {
  skip_if_not_installed("openssl")
  file <- tempfile()
  on.exit(unlink(file), add = TRUE)
  pharma_audit_log("start", file, key = "secret")
  pharma_audit_log("next", file, key = "secret")
  original <- utils::read.csv(file, stringsAsFactors = FALSE)

  changed <- original
  changed$step[2] <- "altered"
  utils::write.csv(changed, file, row.names = FALSE)
  expect_false(pharma_audit_verify(file, key = "secret"))

  changed <- original
  changed$previous_hash[1] <- "forged"
  utils::write.csv(changed, file, row.names = FALSE)
  expect_false(pharma_audit_verify(file, key = "secret"))

  changed <- original
  changed$previous_hash[3] <- NA_character_
  utils::write.csv(changed, file, row.names = FALSE)
  expect_false(pharma_audit_verify(file, key = "secret"))

  changed <- original
  changed$hash[2] <- NA_character_
  utils::write.csv(changed, file, row.names = FALSE)
  expect_false(pharma_audit_verify(file, key = "secret"))

  utils::write.csv(original[, -4L], file, row.names = FALSE)
  expect_false(pharma_audit_verify(file, key = "secret"))

  writeLines(c("step,timestamp,previous_hash,hash", '"unclosed'), file)
  expect_false(pharma_audit_verify(file, key = "secret"))
})

test_that("invalid logs and wrong keys are rejected before append", {
  skip_if_not_installed("openssl")
  file <- tempfile()
  on.exit(unlink(file), add = TRUE)
  pharma_audit_log("start", file, key = "secret")
  original <- readLines(file, warn = FALSE)
  expect_error(
    pharma_audit_log("next", file, key = "different"),
    "failed verification"
  )
  expect_identical(readLines(file, warn = FALSE), original)

  log <- utils::read.csv(file, stringsAsFactors = FALSE)
  log$step[2] <- "changed"
  utils::write.csv(log, file, row.names = FALSE)
  corrupted <- readLines(file, warn = FALSE)
  expect_error(
    pharma_audit_log("next", file, key = "secret"),
    "failed verification"
  )
  expect_identical(readLines(file, warn = FALSE), corrupted)
})

test_that("audit arguments are scalar, nonmissing and nonempty", {
  skip_if_not_installed("openssl")
  file <- tempfile()
  on.exit(unlink(file), add = TRUE)
  expect_error(pharma_audit_log(NA_character_, file, key = "secret"), "message")
  expect_error(pharma_audit_log("", file, key = "secret"), "message")
  expect_error(pharma_audit_log("step", NA_character_, key = "secret"), "file")
  expect_error(pharma_audit_log("step", file, key = ""), "key")
  expect_false(file.exists(file))
  expect_error(pharma_audit_verify(file, key = "secret"), "does not exist")
})
