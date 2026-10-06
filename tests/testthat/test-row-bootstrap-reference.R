# Independent three-row distribution: docs/parallel-bootstrap.md.
# Numerical expectations use fixed row counts, not the statistic callback.
row_reference_data <- function() {
  data.frame(
    id = 1:3, value = c(0, 2, 7), unused = rep(NA_real_, 3),
    row.names = c("row-A", "row-B", "row-C")
  )
}

# Assigning a worker seed changes RNG kinds as well as state. Restore both,
# including the absence of .Random.seed, even when a test expression errors.
row_reference_with_seed <- function(seed, code) {
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) {
    old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  }
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(seed)
  force(code)
}

# This is the callback under test, not a generator of expected values.
row_reference_statistic <- function(rows, shift = 0, multiplier = 1,
                                    na.rm = FALSE) {
  list(
    ids = rows$id, values = rows$value, n = nrow(rows),
    base_frame = identical(class(rows), "data.frame"),
    unused_missing = is.na(rows$unused),
    average = shift + multiplier * mean(rows$value, na.rm = na.rm)
  )
}

# Public future.apply seed capture, followed by base-R index replay. Only
# stream allocation is delegated to the backend; no resamples or means are.
row_reference_sample <- function(seed, n_draws) {
  old_plan <- future::plan()
  on.exit(future::plan(old_plan), add = TRUE)
  future::plan(future::sequential)
  row_reference_with_seed(seed, {
    seeds <- future.apply::future_lapply(seq_len(n_draws), function(i) {
      get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    }, future.seed = TRUE)
    caller_state <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    draws <- lapply(seeds, function(worker_seed) {
      assign(".Random.seed", worker_seed, envir = .GlobalEnv)
      ids <- sample.int(3L, 3L, replace = TRUE)
      list(
        ids = ids, values = c(0, 2, 7)[ids], n = 3L,
        base_frame = TRUE, unused_missing = rep(TRUE, 3L),
        average = (2 * sum(ids == 2L) + 7 * sum(ids == 3L)) / 3
      )
    })
    list(draws = draws, state = caller_state)
  })
}

test_that("row mean reference enumerates all 27 samples with exact moments", {
  indices <- as.matrix(expand.grid(a = 1:3, b = 1:3, c = 1:3))
  sums <- apply(indices, 1L, function(ids) {
    2 * sum(ids == 2L) + 7 * sum(ids == 3L)
  })
  support <- c(0, 2, 4, 6, 7, 9, 11, 14, 16, 21)
  counts <- c(1L, 3L, 3L, 1L, 3L, 6L, 3L, 3L, 3L, 1L)
  expect_identical(dim(indices), c(27L, 3L))
  expect_identical(nrow(unique(as.data.frame(indices))), 27L)
  expect_equal(sort(unique(sums)), support, tolerance = 0)
  expect_identical(
    vapply(support, function(k) sum(sums == k), integer(1)), counts
  )
  averages <- sums / 3
  expect_equal(mean(averages), 3, tolerance = 1e-12)
  expect_equal(mean(averages^2), 107 / 9, tolerance = 1e-12)
  # The complete distribution has denominator 27, not the sample divisor 26.
  expect_equal(sum((averages - 3)^2) / 27, 26 / 9, tolerance = 1e-12)
  expect_equal(sum(counts * (support / 3 - 3)^2) / 27, 26 / 9,
    tolerance = 1e-12
  )
})

test_that("sequential row draws match independent arithmetic under future seeds", {
  skip_if_not_installed("future")
  skip_if_not_installed("future.apply")
  data <- row_reference_data()
  original <- data
  before <- future::plan()
  on.exit(future::plan(before), add = TRUE)
  for (seed in c(11L, 150L)) {
    for (n_draws in c(1L, 31L)) {
      expected <- row_reference_sample(seed, n_draws)
      actual <- row_reference_with_seed(seed, {
        draws <- pharma_parallel_bootstrap(
          data, row_reference_statistic, R = n_draws, plan = "sequential"
        )
        list(draws = draws, state = get(".Random.seed", envir = .GlobalEnv))
      })
      expect_type(actual$draws, "list")
      expect_length(actual$draws, n_draws)
      expect_equal(actual$draws, expected$draws, tolerance = 1e-12)
      expect_identical(lapply(actual$draws, `[[`, "ids"),
        lapply(expected$draws, `[[`, "ids")
      )
      expect_identical(actual$state, expected$state)
      expect_equal(future::plan(), before)
      first <- row_reference_with_seed(seed, {
        pharma_parallel_bootstrap(
          data, row_reference_statistic, R = 1L, plan = "sequential"
        )
      })
      expect_equal(first, actual$draws[1L], tolerance = 1e-12)
    }
  }
  expect_identical(data, original)
})

test_that("bounded multisession matches the reference and restores caller plan", {
  skip_if_not_installed("future")
  skip_if_not_installed("future.apply")
  data <- row_reference_data()
  before <- future::plan()
  on.exit(future::plan(before), add = TRUE)
  for (n_draws in c(1L, 31L)) {
    expected <- row_reference_sample(150L, n_draws)
    actual <- row_reference_with_seed(150L, {
      draws <- pharma_parallel_bootstrap(
        data, row_reference_statistic, R = n_draws,
        plan = future::tweak(future::multisession, workers = 2L)
      )
      list(draws = draws, state = get(".Random.seed", envir = .GlobalEnv))
    })
    expect_equal(actual$draws, expected$draws, tolerance = 1e-12)
    expect_identical(lapply(actual$draws, `[[`, "ids"),
      lapply(expected$draws, `[[`, "ids")
    )
    expect_identical(actual$state, expected$state)
    expect_equal(future::plan(), before)
  }
})

test_that("row bootstrap retains affine responses and callback arguments", {
  skip_if_not_installed("future")
  skip_if_not_installed("future.apply")
  before <- future::plan()
  on.exit(future::plan(before), add = TRUE)
  data <- row_reference_data()
  expected <- row_reference_sample(150L, 31L)$draws
  for (scale in c(2, -2)) {
    transformed <- data
    transformed$value <- 7 + scale * data$value
    actual <- row_reference_with_seed(150L, {
      pharma_parallel_bootstrap(
        transformed, row_reference_statistic, R = 31L, plan = "sequential"
      )
    })
    target <- lapply(expected, function(draw) {
      draw$values <- 7 + scale * draw$values
      draw$average <- 7 + scale * draw$average
      draw
    })
    expect_equal(actual, target, tolerance = 1e-12)
  }
  # Exercise forwarded arguments on workers, not just a local callback.
  actual <- row_reference_with_seed(150L, {
    pharma_parallel_bootstrap(
      data, row_reference_statistic, R = 31L,
      plan = future::tweak(future::multisession, workers = 2L),
      shift = 7, multiplier = -2
    )
  })
  target <- lapply(expected, function(draw) {
    draw$average <- 7 - 2 * draw$average
    draw
  })
  expect_equal(actual, target, tolerance = 1e-12)
})

test_that("missing values reach callbacks without changing the sampled rows", {
  skip_if_not_installed("future")
  skip_if_not_installed("future.apply")
  before <- future::plan()
  on.exit(future::plan(before), add = TRUE)
  data <- row_reference_data()
  data$value[2] <- NA_real_
  expected <- row_reference_sample(150L, 31L)$draws
  for (remove_missing in c(FALSE, TRUE)) {
    actual <- row_reference_with_seed(150L, {
      pharma_parallel_bootstrap(
        data, row_reference_statistic, R = 31L, plan = "sequential",
        na.rm = remove_missing
      )
    })
    target <- lapply(expected, function(draw) {
      missing <- draw$ids == 2L
      draw$values[missing] <- NA_real_
      draw$average <- if (!remove_missing && any(missing)) {
        NA_real_
      } else {
        # With na.rm=TRUE, all-missing samples give 0/0 = NaN.
        7 * sum(draw$ids == 3L) / sum(!missing)
      }
      draw
    })
    expect_equal(actual, target, tolerance = 1e-12)
  }
  # A guaranteed all-missing callback boundary, without relying on a lucky draw.
  data$value[] <- NA_real_
  for (remove_missing in c(FALSE, TRUE)) {
    actual <- row_reference_with_seed(150L, {
      pharma_parallel_bootstrap(
        data, row_reference_statistic, R = 1L, plan = "sequential",
        na.rm = remove_missing
      )
    })[[1L]]
    expect_identical(actual$n, 3L)
    expect_identical(actual$ids, expected[[1L]]$ids)
    expect_true(all(is.na(actual$values)))
    expect_true(is.na(actual$average))
    expect_identical(is.nan(actual$average), remove_missing)
  }
})

test_that("row bootstrap restores plans after local and worker callback errors", {
  skip_if_not_installed("future")
  skip_if_not_installed("future.apply")
  before <- future::plan()
  on.exit(future::plan(before), add = TRUE)
  for (strategy in list("sequential", future::tweak(future::multisession,
    workers = 2L
  ))) {
    row_reference_with_seed(150L, {
      expect_error(suppressWarnings(pharma_parallel_bootstrap(
        row_reference_data(), function(rows) stop("row reference failure"),
        R = 1L, plan = strategy
      )), "row reference failure")
    })
    expect_equal(future::plan(), before)
  }
})

test_that("row reference isolation restores RNG kinds and absent seed bindings", {
  row_reference_with_seed(901L, {
    before <- get(".Random.seed", envir = .GlobalEnv)
    kind <- RNGkind()
    row_reference_with_seed(150L, {
      RNGkind("L'Ecuyer-CMRG")
      sample.int(3L, 3L, replace = TRUE)
    })
    expect_identical(RNGkind(), kind)
    expect_identical(get(".Random.seed", envir = .GlobalEnv), before)
    expect_error(row_reference_with_seed(150L, {
      RNGkind("L'Ecuyer-CMRG")
      stop("row seed restoration probe")
    }), "row seed restoration probe")
    expect_identical(RNGkind(), kind)
    expect_identical(get(".Random.seed", envir = .GlobalEnv), before)
    rm(".Random.seed", envir = .GlobalEnv)
    row_reference_with_seed(150L, sample.int(3L))
    expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
    expect_error(row_reference_with_seed(150L, {
      RNGkind("L'Ecuyer-CMRG")
      stop("row seed restoration probe")
    }), "row seed restoration probe")
    expect_identical(RNGkind(), kind)
    expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
  })
})
