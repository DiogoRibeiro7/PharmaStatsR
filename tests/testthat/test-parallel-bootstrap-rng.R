test_that("parallel row bootstrap uses reproducible streams across plans", {
  skip_if_not_installed("future.apply")
  skip_if_not_installed("future")
  d <- data.frame(id = seq_len(10), group = rep(c("A", "B"), each = 5),
                  unused = c(NA, rep(1, 9)))
  stat <- function(rows) rows$id
  before <- future::plan()

  set.seed(314)
  sequential <- pharma_parallel_bootstrap(d, stat, R = 6, plan = "sequential")
  set.seed(314)
  parallel <- pharma_parallel_bootstrap(
    d, stat, R = 6,
    plan = future::tweak(future::multisession, workers = 2L)
  )
  expect_identical(sequential, parallel)
  expect_equal(future::plan(), before)
  expect_true(all(vapply(sequential, length, integer(1)) == nrow(d)))
  expect_true(all(unlist(sequential) %in% d$id))
  expect_true(any(vapply(sequential, function(ids) anyDuplicated(ids) > 0L,
                         logical(1))))
})

test_that("callback randomness follows the same future streams across plans", {
  skip_if_not_installed("future.apply")
  skip_if_not_installed("future")
  d <- data.frame(id = 1:8)
  stat <- function(rows) list(ids = rows$id, noise = stats::rnorm(1))

  set.seed(271)
  sequential <- pharma_parallel_bootstrap(d, stat, R = 5,
                                           plan = "sequential")
  set.seed(271)
  parallel <- pharma_parallel_bootstrap(
    d, stat, R = 5,
    plan = future::tweak(future::multisession, workers = 2L)
  )

  expect_identical(sequential, parallel)
  expect_length(sequential, 5)
  expect_true(all(vapply(sequential, function(x) length(x$ids) == nrow(d),
                         logical(1))))
  expect_true(all(is.finite(vapply(sequential, `[[`, numeric(1), "noise"))))
})

test_that("default multisession bootstrap uses at most two workers", {
  skip_if_not_installed("future.apply")
  skip_if_not_installed("future")
  before <- future::plan()
  d <- data.frame(id = 1:4)
  pids <- pharma_parallel_bootstrap(d, function(rows) Sys.getpid(), R = 6)

  expect_lte(length(unique(unlist(pids))), 2L)
  expect_equal(future::plan(), before)
})

test_that("parallel bootstrap restores the plan after statistic failure", {
  skip_if_not_installed("future.apply")
  skip_if_not_installed("future")
  before <- future::plan()
  d <- data.frame(x = 1:4)
  expect_error(suppressWarnings(pharma_parallel_bootstrap(
    d, function(rows) stop("statistic failed"), R = 1,
    plan = "sequential"
  )), "statistic failed")
  expect_equal(future::plan(), before)
})

test_that("future worker validation enforces the two-worker ceiling", {
  expect_identical(
    PharmaStatsR:::.pharma_validate_future_workers(1L),
    1L
  )
  expect_identical(
    PharmaStatsR:::.pharma_validate_future_workers(2L),
    2L
  )
  for (bad in list(0L, 3L, Inf, NA_real_, "2", c(1L, 2L))) {
    expect_error(
      PharmaStatsR:::.pharma_validate_future_workers(bad),
      "one or two workers"
    )
  }
})

test_that("parallel bootstrap validates requested replicates and strategy", {
  skip_if_not_installed("future.apply")
  d <- data.frame(x = 1:4)
  stat <- function(rows) mean(rows$x)
  for (bad in list(0, -1, 1.5, NA_real_, Inf, "3", c(1, 2))) {
    expect_error(pharma_parallel_bootstrap(d, stat, R = bad), "`R`")
  }
  for (bad in list("", NA_character_, c("sequential", "multisession"), 2)) {
    expect_error(pharma_parallel_bootstrap(d, stat, plan = bad), "`plan`")
  }
  expect_error(pharma_parallel_bootstrap(d[FALSE, ], stat),
               "`data`")
})
