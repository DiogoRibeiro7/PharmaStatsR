local_edition(3)

library(testthat)

test_that("diagnostics_status_text covers all status states", {
  expect_equal(
    PharmaStatsR:::diagnostics_status_text(NULL, NULL),
    "No data loaded."
  )
  expect_equal(
    PharmaStatsR:::diagnostics_status_text(data.frame(x = 1), NULL),
    "Data loaded. Click 'Fit model' to enable diagnostics."
  )
  expect_equal(
    PharmaStatsR:::diagnostics_status_text(data.frame(x = 1), list(model = TRUE)),
    "Model ready."
  )
  expect_equal(
    PharmaStatsR:::diagnostics_status_text(
      NULL, NULL, "Upload failed: empty file"
    ),
    "Upload failed: empty file"
  )
})

test_that("diagnostics validate names and numeric plotting columns", {
  validate <- PharmaStatsR:::validate_diagnostics_data
  d <- data.frame(SubjectID = c("A", "B"), Time = c(0, NA), DV = c(1.1, 2.2))
  expect_true(validate(d))
  expect_error(validate(NULL), "must be a data.frame")
  expect_error(validate(d[FALSE, ]), "at least one row")
  expect_error(validate(d[c("SubjectID", "Time")]), "Missing required.*DV")
  expect_error(
    validate(data.frame(SubjectID = 1, Time = "morning", DV = 1)),
    "must be numeric"
  )
  expect_error(
    validate(data.frame(SubjectID = 1, Time = 0, DV = Inf)), "infinite"
  )
  invalid <- d
  invalid$SubjectID <- list(1, 2)
  expect_error(validate(invalid), "numeric, logical, character, or factor")
  for (name in c("Time", "", NA_character_)) {
    names(invalid) <- c("SubjectID", "Time", name)
    expect_error(validate(invalid), "column names")
  }
})
