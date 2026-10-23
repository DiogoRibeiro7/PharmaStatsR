local_edition(3)

test_that("interleaved long rows match an independent typed wide table", {
  levels <- c("low", "mid", "high", "unused")
  d <- data.frame(
    "subject id" = c("s2", "s1", "s2", "s1"), visit = c(1, 0, 0, 1),
    "mass (kg)" = c(72, 60, 70, NA), event = c(TRUE, FALSE, FALSE, NA),
    stage = ordered(c("high", "low", "mid", NA), levels = levels),
    arm = factor(c("B", "A", "B", "A"), levels = c("A", "B", "unused")),
    collected = as.Date(c("2024-01-02", "2024-01-01", "2024-01-02", "2024-01-01")),
    row.names = c("r4", "r2", "r3", "r1"), check.names = FALSE
  )
  original <- d
  vars <- c("stage", "mass (kg)", "event")
  expected <- data.frame(
    "subject id" = c("s2", "s1"),
    arm = factor(c("B", "A"), levels = c("A", "B", "unused")),
    collected = as.Date(c("2024-01-02", "2024-01-01")),
    stage_1 = ordered(c("high", NA), levels = levels),
    stage_0 = ordered(c("mid", "low"), levels = levels),
    "mass (kg)_1" = c(72, NA), "mass (kg)_0" = c(70, 60),
    event_1 = c(TRUE, NA), event_0 = c(FALSE, FALSE), check.names = FALSE
  )
  wide <- reshape_timevarying(d, vars, "subject id", "visit")
  expect_identical(as.data.frame(wide), expected)
  expect_identical(d, original)
  # Wide column order controls the long value-column order, even with reversed selection.
  back <- reshape_timevarying(wide, rev(vars), "subject id", "visit")
  expected_long <- data.frame(
    "subject id" = c("s2", "s2", "s1", "s1"),
    arm = factor(c("B", "B", "A", "A"), levels = c("A", "B", "unused")),
    collected = as.Date(c("2024-01-02", "2024-01-02", "2024-01-01", "2024-01-01")),
    visit = c(1L, 0L, 1L, 0L),
    stage = ordered(c("high", "mid", NA, "low"), levels = levels),
    "mass (kg)" = c(72, 70, NA, 60), event = c(TRUE, FALSE, NA, FALSE),
    check.names = FALSE
  )
  expect_identical(back, expected_long)
  expect_identical(as.data.frame(wide), expected)
  # The all-missing s1/visit1 measurement remains a real output row.
  expect_true(all(is.na(back[3, vars])))
  expect_identical(as.data.frame(reshape_timevarying(back, vars, "subject id", "visit")), expected)
})

test_that("sparse covariate schemas have explicit structural missing cells", {
  d <- data.frame(id = c(2L, 1L), label = c("B", "A"), WT_1 = c(NA, 10), AGE_0 = c(30L, 40L))
  original <- d
  expected <- data.frame(
    id = c(2L, 2L, 1L, 1L), label = c("B", "B", "A", "A"),
    Time = c(1L, 0L, 1L, 0L), WT = c(NA, NA, 10, NA),
    AGE = c(NA_integer_, 30L, NA_integer_, 40L)
  )
  long <- reshape_timevarying(d, c("AGE", "WT"), "id")
  expect_identical(long, expected)
  completed <- reshape_timevarying(long, c("WT", "AGE"), "id")
  expected_wide <- data.frame(
    id = c(2L, 1L), label = c("B", "A"), WT_1 = c(NA, 10), WT_0 = c(NA_real_, NA_real_),
    AGE_1 = c(NA_integer_, NA_integer_), AGE_0 = c(30L, 40L)
  )
  expect_identical(as.data.frame(completed), expected_wide)
  expect_identical(reshape_timevarying(completed, c("WT", "AGE"), "id"), expected)
  expect_identical(d, original)
})

test_that("all retained metadata participate in row identity", {
  d <- data.frame(id = c(1L, 1L), Time = c(0L, 1L), WT = c(70, 72), period = c("before", "after"))
  expected <- data.frame(id = c(1L, 1L), period = c("before", "after"), WT_0 = c(70, NA), WT_1 = c(NA, 72))
  wide <- reshape_timevarying(d, "WT", "id")
  expect_identical(as.data.frame(wide), expected)
  expected_long <- data.frame(
    id = rep(1L, 4), period = c("before", "before", "after", "after"),
    Time = c(0L, 1L, 0L, 1L), WT = c(70, NA, NA, 72)
  )
  expect_identical(reshape_timevarying(wide, "WT", "id"), expected_long)
  # Equal subject/time is valid when another retained key distinguishes the rows.
  d$Time[] <- 0L
  expect_identical(
    as.data.frame(reshape_timevarying(d, "WT", "id")),
    data.frame(id = c(1L, 1L), period = c("before", "after"), WT_0 = c(70, 72))
  )
})

test_that("duplicate wide keys are rejected independently of measurement values", {
  for (id_name in c("id", "WT_id", ".value", "subject id")) {
    for (values in list(c(70, 80), c(70, 70), c(NA_real_, NA_real_))) {
      d <- data.frame(id = c(1L, 1L), group = c("A", "A"), WT_0 = values)
      names(d)[1] <- id_name
      rownames(d) <- c("first", "second")
      original <- d
      expect_error(reshape_timevarying(d, "WT", id_name), "Duplicate wide row keys")
      expect_identical(d, original)
      # An explicit replicate key makes both records representable without aggregation.
      d$replicate <- c(1L, 2L)
      result <- reshape_timevarying(d, "WT", id_name)
      expect_identical(result$WT, values)
      expect_identical(result$replicate, c(1L, 2L))
      expect_identical(
        as.data.frame(reshape_timevarying(result, "WT", id_name))[names(d)],
        `rownames<-`(d, NULL)
      )
    }
  }
  only_id <- data.frame(id = c(1L, 1L), WT_0 = c(70, 80))
  expect_error(reshape_timevarying(only_id, "WT", "id"), "Duplicate wide row keys")
})

test_that("missing keys and empty wide schemas retain a consistent contract", {
  d <- data.frame(id = c(NA_integer_, NA_integer_), group = c(NA_character_, NA_character_), WT_0 = c(70, 80))
  expect_error(reshape_timevarying(d, "WT", "id"), "Duplicate wide row keys")
  long <- data.frame(id = c(NA_integer_, NA_integer_), group = c(NA_character_, NA_character_), Time = c(0L, 0L), WT = c(70, 80))
  expect_error(reshape_timevarying(long, "WT", "id"), "Duplicate identifier/time")
  d$group <- c("A", "B")
  expect_identical(
    reshape_timevarying(d, "WT", "id"),
    data.frame(id = c(NA_integer_, NA_integer_), group = c("A", "B"), Time = c(0L, 0L), WT = c(70, 80))
  )
  empty <- d[FALSE, ]
  expected <- data.frame(id = integer(), group = character(), Time = integer(), WT = numeric())
  expect_identical(reshape_timevarying(empty, "WT", "id"), expected)
  expect_identical(
    reshape_timevarying(d[1, ], "WT", "id"),
    data.frame(id = NA_integer_, group = "A", Time = 0L, WT = 70)
  )
})
