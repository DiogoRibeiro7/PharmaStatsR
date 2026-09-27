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
  expect_identical(future::plan(), before)
  expect_true(all(vapply(sequential, length, integer(1)) == nrow(d)))
  expect_true(all(unlist(sequential) %in% d$id))
  expect_true(any(vapply(sequential, function(ids) anyDuplicated(ids) > 0L,
                         logical(1))))
})

test_that("parallel bootstrap restores the plan after statistic failure", {
  skip_if_not_installed("future.apply")
  skip_if_not_installed("future")
  before <- future::plan()
  d <- data.frame(x = 1:4)
  expect_error(pharma_parallel_bootstrap(
    d, function(rows) stop("statistic failed"), R = 1,
    plan = "sequential"
  ), "statistic failed")
  expect_identical(future::plan(), before)
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
