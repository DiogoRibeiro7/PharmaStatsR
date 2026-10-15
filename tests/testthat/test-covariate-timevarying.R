local_edition(3)

library(testthat)

make_long_data <- function() {
  data.frame(
    SubjectID = rep(1:2, each = 2),
    Time = rep(c(0, 1), times = 2),
    WT = c(70, 72, 65, 66)
  )
}

# Long to wide

test_that("reshape_timevarying converts long to wide", {
  long_data <- make_long_data()
  wide_data <- reshape_timevarying(
    long_data,
    "WT",
    id = "SubjectID",
    time_var = "Time"
  )
  expect_equal(nrow(wide_data), 2)
  expect_true(all(c("WT_0", "WT_1") %in% names(wide_data)))
})

test_that("round-trip retains values", {
  long_data <- make_long_data()
  wide_data <- reshape_timevarying(
    long_data,
    "WT",
    id = "SubjectID",
    time_var = "Time"
  )
  back_to_long <- reshape_timevarying(
    wide_data,
    "WT",
    id = "SubjectID",
    time_var = "Time"
  )
  sorted_orig <- long_data[order(long_data$SubjectID, long_data$Time), ]
  sorted_back <- back_to_long[order(
    back_to_long$SubjectID,
    back_to_long$Time
  ), ]
  rownames(sorted_orig) <- NULL
  rownames(sorted_back) <- NULL
  expect_equal(sorted_back, sorted_orig)
})

test_that("literal covariate names and time labels survive round trips", {
  d <- data.frame(
    subject = rep(1:2, each = 2), visit = rep(c("pre_dose", "post_dose"), 2),
    a = c(1, 2, NA, 4), b = c(70, 72, 65, 66),
    group = factor(rep(c("A", "B"), each = 2))
  )
  variables <- c("dose_rate", "WT(kg)")
  names(d)[1:4] <- c("subject id", "visit label", variables)
  wide <- reshape_timevarying(d, variables, "subject id", "visit label")
  expect_named(wide, c(
    "subject id", "group", "dose_rate_pre_dose", "dose_rate_post_dose",
    "WT(kg)_pre_dose", "WT(kg)_post_dose"
  ))
  result <- reshape_timevarying(wide, variables, "subject id", "visit label")
  expect_equal(result[names(d)], d)

  # Regex metacharacters and braces are ordinary characters in both directions.
  for (variable in c("x.y", "a+b", "[x]", "a|b", "{dose}", "a\\b")) {
    simple <- data.frame(id = c(1, 1), visit = c("before_dose", "after_dose"))
    simple[[variable]] <- c(3, 4)
    names(simple)[2] <- "time {label}"
    wide <- reshape_timevarying(simple, variable, "id", "time {label}")
    expect_equal(
      reshape_timevarying(wide, variable, "id", "time {label}"), simple
    )
  }
})

test_that("literal matching leaves unrelated columns untouched", {
  d <- data.frame(id = 1L, check.names = FALSE)
  d[["WT(kg)_0"]] <- 70
  d[["WTkg_0"]] <- "metadata"
  result <- reshape_timevarying(d, "WT(kg)", id = "id")
  expect_equal(result, data.frame(
    id = 1L, WTkg_0 = "metadata", Time = 0L, "WT(kg)" = 70,
    check.names = FALSE
  ))
  d <- data.frame(WT_id = c("s1", "s2"), WT_0 = c(70, 80))
  result <- reshape_timevarying(d, "WT", id = "WT_id")
  expect_identical(result$WT_id, d$WT_id)
  expect_equal(as.data.frame(reshape_timevarying(result, "WT", "WT_id")), d)
})

test_that("time labels are not collapsed or interpreted as missing", {
  for (labels in list(
    c("01", "1"), c("1", "1.0"), c("NA", "NaN"), "NaN",
    c("TRUE", "FALSE"), c("pre_dose", "post_dose")
  )) {
    d <- data.frame(id = 1, Time = labels, WT = seq_along(labels))
    wide <- reshape_timevarying(d, "WT", "id")
    expect_identical(reshape_timevarying(wide, "WT", "id")$Time, labels)
  }
  d <- data.frame(
    id = 1, WT_0 = 10, "WT_1.5" = 20, "WT_-2" = 30,
    check.names = FALSE
  )
  expect_identical(reshape_timevarying(d, "WT", "id")$Time, c(0, 1.5, -2))
})

test_that("reserved internal names do not collide with user columns", {
  for (time_name in c(".name", ".value", ".seq", ".pharmocovr_time")) {
    d <- data.frame(id = c(1L, 1L), time = c(0L, 1L), x = c(2, 3))
    names(d)[2:3] <- c(time_name, "value_name")
    d$.pharmocovr_time.1 <- "metadata"
    wide <- reshape_timevarying(d, "value_name", "id", time_name)
    back <- reshape_timevarying(wide, "value_name", "id", time_name)
    expect_identical(back[names(d)], d)
  }
  d <- data.frame(id = c(1L, 1L), Time = c(0L, 1L))
  d$.value <- c(1, 2)
  wide <- reshape_timevarying(d, ".value", "id")
  expect_identical(reshape_timevarying(wide, ".value", "id"), d)
})

test_that("sparse data preserve missing cells and covariate types", {
  d <- data.frame(id = c(2L, 1L), WT_1 = c(NA, 10), AGE_0 = c(30L, 40L))
  result <- reshape_timevarying(d, c("WT", "AGE"), "id")
  expect_equal(result, data.frame(
    id = c(2L, 2L, 1L, 1L), Time = c(1L, 0L, 1L, 0L),
    WT = c(NA, NA, 10, NA), AGE = c(NA_integer_, 30L, NA_integer_, 40L)
  ))
  d <- data.frame(id = 1L, check.names = FALSE)
  d$stage_0 <- ordered("low", levels = c("low", "high", "unused"))
  d$stage_1 <- ordered("high", levels = c("low", "high", "unused"))
  result <- reshape_timevarying(d, "stage", "id")
  expect_identical(
    result$stage, ordered(c("low", "high"), levels = levels(d$stage_0))
  )
  empty <- reshape_timevarying(d[FALSE, ], "stage", "id")
  expect_equal(nrow(empty), 0L)
  expect_named(empty, c("id", "Time", "stage"))
})

test_that("ambiguous names and conflicting output columns are rejected", {
  d <- data.frame(id = 1, x_0 = 10, x_y_0 = 20)
  expect_error(reshape_timevarying(d, c("x", "x_y"), "id"), "Ambiguous")
  long <- data.frame(id = 1, Time = 0, x = 10, x_y = 20)
  expect_error(reshape_timevarying(long, c("x", "x_y"), "id"), "Ambiguous")
  expect_error(
    reshape_timevarying(data.frame(id = 1, x_ = 2), "x", "id"), "nonempty time"
  )
  d <- data.frame(id = 1, WT_0 = 70)
  expect_error(reshape_timevarying(d, c("WT", "AGE"), "id"), "no wide-format")
  d$WT <- 80
  expect_error(reshape_timevarying(d, "WT", "id"), "conflict with retained")
  d <- data.frame(id = 1, Time = 0, WT = 70, WT_note = "baseline")
  expect_error(reshape_timevarying(d, "WT", "id"), "conflict with covariate")
  d <- data.frame(WT_0 = 1, Time = 0, WT = 70)
  expect_error(reshape_timevarying(d, "WT", "WT_0"), "not unique")
  d <- data.frame(id = 1, Time = 0, WT_0 = 70)
  expect_error(reshape_timevarying(d, "WT", "id"), "some selected covariates")
})

test_that("long-format keys and time labels must be unambiguous", {
  d <- data.frame(id = c(1, 1), Time = c(0, 0), WT = c(70, 80))
  expect_error(reshape_timevarying(d, "WT", "id"), "Duplicate identifier/time")
  d$group <- c("A", "B")
  expect_equal(nrow(reshape_timevarying(d, "WT", "id")), 2L)
  for (times in list(c(NA, 1), c("", "day1"), list(0, 1), matrix(0:1))) {
    d$Time <- times
    expect_error(reshape_timevarying(d, "WT", "id"), "Time values")
  }
  d$Time <- c(1, 1 + 1e-15)
  expect_error(reshape_timevarying(d, "WT", "id"), "duplicate wide column")
  expect_error(reshape_timevarying(d[FALSE, ], "WT", "id"), "at least one time")
})

test_that("reshape selections and data names are validated", {
  d <- make_long_data()
  for (variables in list(
    character(), NA_character_, "", c("WT", "WT"), matrix("WT")
  )) {
    expect_error(reshape_timevarying(d, variables), "character vector")
  }
  invalid_names <- list(
    character(), NA_character_, "", c("a", "b"), 1, matrix("a")
  )
  for (name in invalid_names) {
    expect_error(reshape_timevarying(d, "WT", id = name), "single nonempty")
    expect_error(
      reshape_timevarying(d, "WT", time_var = name), "single nonempty"
    )
  }
  expect_error(reshape_timevarying(d, "WT", time_var = "SubjectID"), "distinct")
  expect_error(reshape_timevarying(d, "SubjectID"), "distinct")
  expect_error(reshape_timevarying(d, "Time"), "distinct")
  for (name in c("SubjectID", "", NA_character_)) {
    names(d)[3] <- name
    expect_error(reshape_timevarying(d, "WT"), "column names")
  }
})
