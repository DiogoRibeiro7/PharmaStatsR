# External HMAC-SHA256 reference vectors for the audit-chain serialization.
# Hex digests below were calculated independently with Python's stdlib hmac
# and hashlib, not with R openssl or package code.

audit_reference_vectors <- function() {
  data.frame(
    step = c("genesis", 'Load "trial", data', "Fit model v1"),
    timestamp = c(
      "2026-01-02 03:04:05 UTC",
      "2026-01-02 03:04:06 UTC",
      "2026-01-02 03:04:07 UTC"
    ),
    previous_hash = c(
      "NA",
      "438418a710bb511683c6a7a39fbf1e92a01274fbeec7ffbb3f499d578e340cd2",
      "b41f5af5f230a80e84b1f389009d0d207797d3bbfc71ff81023cb5af3dff44e8"
    ),
    hash = c(
      "438418a710bb511683c6a7a39fbf1e92a01274fbeec7ffbb3f499d578e340cd2",
      "b41f5af5f230a80e84b1f389009d0d207797d3bbfc71ff81023cb5af3dff44e8",
      "54a93366dbc94990c7cef060770a56c621e43c0ceddd3e763d0a4e580d6e5781"
    ),
    stringsAsFactors = FALSE
  )
}

write_audit_reference <- function(file) {
  utils::write.csv(
    audit_reference_vectors(), file,
    row.names = FALSE, na = "NA", qmethod = "double"
  )
  invisible(file)
}

test_that("external HMAC reference chain verifies exactly", {
  skip_if_not_installed("openssl")

  file <- tempfile(fileext = ".csv")
  on.exit(unlink(file), add = TRUE)
  write_audit_reference(file)

  expect_true(pharma_audit_verify(file, key = "reference-key-164"))
  expect_false(pharma_audit_verify(file, key = "different-key"))

  saved <- utils::read.csv(
    file, colClasses = "character", na.strings = character(),
    stringsAsFactors = FALSE
  )
  expect_identical(saved$step[[2L]], 'Load "trial", data')
  expect_identical(saved$hash, audit_reference_vectors()$hash)
})

test_that("external vectors expose the package serialization contract", {
  vectors <- audit_reference_vectors()

  expect_identical(
    paste(vectors$step[[1L]], vectors$timestamp[[1L]], NA_character_),
    "genesis 2026-01-02 03:04:05 UTC NA"
  )
  expect_identical(
    paste(
      vectors$step[[2L]], vectors$timestamp[[2L]],
      vectors$previous_hash[[2L]]
    ),
    paste0(
      'Load "trial", data 2026-01-02 03:04:06 UTC ',
      "438418a710bb511683c6a7a39fbf1e92a01274fbeec7ffbb3f499d578e340cd2"
    )
  )
  expect_identical(
    vectors$previous_hash[-1L],
    vectors$hash[-nrow(vectors)]
  )
})

test_that("external reference fails after any authenticated-field change", {
  skip_if_not_installed("openssl")

  original <- audit_reference_vectors()
  mutations <- list(
    function(x) { x$step[2] <- "Load altered data"; x },
    function(x) { x$timestamp[3] <- "2026-01-02 03:04:08 UTC"; x },
    function(x) { x$previous_hash[3] <- paste0(rep("0", 64), collapse = ""); x },
    function(x) { x$hash[2] <- paste0(rep("f", 64), collapse = ""); x }
  )

  for (mutate in mutations) {
    file <- tempfile(fileext = ".csv")
    changed <- mutate(original)
    utils::write.csv(changed, file, row.names = FALSE, na = "NA")
    expect_false(pharma_audit_verify(file, key = "reference-key-164"))
    unlink(file)
  }
})

test_that("a valid external prefix remains valid after tail deletion", {
  skip_if_not_installed("openssl")

  file <- tempfile(fileext = ".csv")
  on.exit(unlink(file), add = TRUE)

  prefix <- audit_reference_vectors()[1:2, , drop = FALSE]
  utils::write.csv(prefix, file, row.names = FALSE, na = "NA")

  # This is the documented limitation: a valid prefix cannot reveal that
  # later rows were deleted without an external expected length/final hash.
  expect_true(pharma_audit_verify(file, key = "reference-key-164"))
})

test_that("audit logger can append to the externally generated chain", {
  skip_if_not_installed("openssl")

  file <- tempfile(fileext = ".csv")
  on.exit(unlink(file), add = TRUE)
  write_audit_reference(file)

  expect_identical(
    pharma_audit_log("Post-reference step", file, key = "reference-key-164"),
    file
  )
  saved <- utils::read.csv(
    file, colClasses = "character", na.strings = character(),
    stringsAsFactors = FALSE
  )
  expect_equal(nrow(saved), 4L)
  expect_identical(
    saved$previous_hash[[4L]],
    "54a93366dbc94990c7cef060770a56c621e43c0ceddd3e763d0a4e580d6e5781"
  )
  expect_true(pharma_audit_verify(file, key = "reference-key-164"))
})
