# Independent finite-support derivation: docs/wild-bootstrap.md.
# Test-only fixtures; no expected coefficient is obtained from a model fit.
wild_reference_data <- function() {
  data.frame(x = c(-1, 0, 1, 2), y = c(0, 0, 6, 8))
}

# Evaluate a test expression under a seed without leaking RNG state, including
# on errors or when the caller did not previously have a .Random.seed binding.
wild_reference_with_seed <- function(seed, code) {
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) {
    old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  }
  on.exit({
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(seed)
  force(code)
}

# Rows are sign vectors in {-1, 1}^4. X'X = matrix(c(4, 2, 2, 6), 2),
# beta = c(2, 3), and e = c(1, -2, 1, 0). The fourth sign has no effect.
wild_reference_draws <- function(signs) {
  stopifnot(
    is.matrix(signs), is.numeric(signs), ncol(signs) == 4L,
    nrow(signs) > 0L, all(signs %in% c(-1, 1))
  )
  cbind(
    "(Intercept)" = 2 + (2 * signs[, 1] - 3 * signs[, 2] + signs[, 3]) / 5,
    x = 3 + (-3 * signs[, 1] + 2 * signs[, 2] + signs[, 3]) / 10
  )
}

test_that("wild reference exhausts the sign support and its exact moments", {
  signs <- unname(as.matrix(expand.grid(
    s1 = c(-1, 1), s2 = c(-1, 1), s3 = c(-1, 1), s4 = c(-1, 1),
    KEEP.OUT.ATTRS = FALSE
  )))
  draws <- wild_reference_draws(signs)
  # s1 varies fastest; each eight-row table repeats for the two s4 values.
  expected <- cbind(
    "(Intercept)" = rep(c(2, 14 / 5, 4 / 5, 8 / 5, 12 / 5, 16 / 5, 6 / 5, 2), 2),
    x = rep(c(3, 12 / 5, 17 / 5, 14 / 5, 16 / 5, 13 / 5, 18 / 5, 3), 2)
  )
  expect_identical(dim(draws), c(16L, 2L))
  expect_equal(draws, expected, tolerance = 1e-12)
  expect_equal(unname(colMeans(draws)), c(2, 3), tolerance = 1e-12)
  centered <- sweep(draws, 2L, c(2, 3), "-")
  # This is the full probability distribution, not a sample: divide by 16,
  # rather than the 15 used by the usual sample covariance estimator.
  covariance <- matrix(c(14 / 25, -11 / 50, -11 / 50, 7 / 50), 2L)
  expect_equal(unname(crossprod(centered) / 16), covariance, tolerance = 1e-12)
  expect_identical(nrow(unique(as.data.frame(draws))), 7L)
  expect_equal(draws[1:8, ], draws[9:16, ], tolerance = 1e-12)
})

test_that("seeded wild draws match independent targets in replicate order", {
  data <- wild_reference_data()
  for (seed in c(11L, 144L)) {
    for (n_draws in c(1L, 17L)) {
      reference <- wild_reference_with_seed(seed, {
        signs <- t(vapply(seq_len(n_draws), function(i) {
          sample(c(-1, 1), 4L, replace = TRUE)
        }, numeric(4)))
        list(
          draws = wild_reference_draws(signs),
          state = get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
        )
      })
      actual <- wild_reference_with_seed(seed, {
        draws <- pharma_wild_bootstrap(y ~ x, data, R = n_draws)
        list(
          draws = draws,
          state = get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
        )
      })
      expect_type(actual$draws, "double")
      expect_identical(dim(actual$draws), c(n_draws, 2L))
      expect_identical(colnames(actual$draws), c("(Intercept)", "x"))
      expect_null(rownames(actual$draws))
      expect_equal(actual$draws, reference$draws, tolerance = 1e-12)
      # Even a zero-residual row consumes a sign in the current RNG contract.
      expect_identical(actual$state, reference$state)
      first <- wild_reference_with_seed(seed, {
        pharma_wild_bootstrap(y ~ x, data, R = 1L)
      })
      expect_equal(first, actual$draws[1L, , drop = FALSE], tolerance = 1e-12)
    }
  }
})

test_that("wild offset and transformed-term targets retain the offset once", {
  data <- wild_reference_data()
  data$known <- c(1, 0, 2, -1)
  data$y <- data$y + data$known
  for (n_draws in c(1L, 17L)) {
    expected <- wild_reference_with_seed(144L, {
      signs <- t(vapply(seq_len(n_draws), function(i) {
        sample(c(-1, 1), 4L, replace = TRUE)
      }, numeric(4)))
      draws <- wild_reference_draws(signs)
      # I(2 * x) halves the original slope and its sign-dependent increment.
      draws[, 2] <- draws[, 2] / 2
      colnames(draws)[2] <- "I(2 * x)"
      draws
    })
    actual <- wild_reference_with_seed(144L, {
      pharma_wild_bootstrap(y ~ I(2 * x) + offset(known), data, R = n_draws)
    })
    expect_identical(dim(actual), c(n_draws, 2L))
    expect_identical(colnames(actual), c("(Intercept)", "I(2 * x)"))
    expect_null(rownames(actual))
    expect_equal(actual, expected, tolerance = 1e-12)
  }
})

test_that("wild reference seed isolation survives normal and error exits", {
  wild_reference_with_seed(901L, {
    before <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    wild_reference_with_seed(144L, sample(c(-1, 1), 4L, replace = TRUE))
    expect_identical(get(".Random.seed", envir = .GlobalEnv), before)
    expect_error(wild_reference_with_seed(144L, {
      sample(c(-1, 1), 4L, replace = TRUE)
      stop("seed restoration probe")
    }), "seed restoration probe")
    expect_identical(get(".Random.seed", envir = .GlobalEnv), before)

    rm(".Random.seed", envir = .GlobalEnv)
    wild_reference_with_seed(144L, sample(c(-1, 1), 4L, replace = TRUE))
    expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
    expect_error(wild_reference_with_seed(144L, {
      sample(c(-1, 1), 4L, replace = TRUE)
      stop("seed restoration probe")
    }), "seed restoration probe")
    expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
  })
})
