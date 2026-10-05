# Independent projection arithmetic and the complete support are documented in
# docs/permutation.md. Expected F values never come from lm() or lm.fit().
permutation_reference_data <- function() {
  data.frame(
    first = c(-2, -1, 0, 1, 2),
    second = c(2, -1, -2, -1, 2),
    response = c(0, 1, 4, 2, 7),
    row.names = paste0("case-", seq_len(5))
  )
}

# This test-only helper restores the caller's stream, including an absent seed.
permutation_reference_with_seed <- function(seed, code) {
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

# Enumerate the tiny fixture only; this is not an exported permutation API.
permutation_reference_orders <- function(indices = seq_len(5L)) {
  if (length(indices) == 1L) {
    return(matrix(indices, nrow = 1L))
  }
  do.call(rbind, lapply(seq_along(indices), function(i) {
    cbind(indices[i], permutation_reference_orders(indices[-i]))
  }))
}

# For permutations of (0, 1, 4, 2, 7), SST = 154/5 and
# SSR = a^2/10 + b^2/14. Both degrees of freedom are 2, so F = k/(539-k).
# The integer k permits exact tail comparisons without numerical tie decisions.
permutation_reference_score <- function(response) {
  stopifnot(
    is.numeric(response), length(response) == 5L,
    all(is.finite(response)), identical(sort(as.numeric(response)), c(0, 1, 2, 4, 7))
  )
  a <- sum(c(-2, -1, 0, 1, 2) * response)
  b <- sum(c(2, -1, -2, -1, 2) * response)
  (7 * a^2 + 5 * b^2) / 4
}

permutation_reference_sample <- function(seed, n_draws) {
  permutation_reference_with_seed(seed, {
    response <- permutation_reference_data()$response
    scores <- vapply(seq_len(n_draws), function(i) {
      permutation_reference_score(response[sample.int(5L)])
    }, numeric(1))
    list(
      statistic = 405 / 134,
      perm = scores / (539 - scores),
      p.value = (1 + sum(scores >= 405)) / (n_draws + 1),
      state = get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    )
  })
}

test_that("permutation reference exhausts all 120 label permutations", {
  data <- permutation_reference_data()
  orders <- permutation_reference_orders()
  scores <- apply(orders, 1L, function(order) {
    permutation_reference_score(data$response[order])
  })
  expected_scores <- c(
    3, 27, 33, 55, 73, 75, 103, 145, 157, 187, 192, 195, 213,
    220, 223, 243, 255, 283, 297, 300, 307, 313, 355, 363, 367,
    388, 405, 433, 447, 468, 493, 495, 507, 517, 523, 528, 537
  )
  expected_counts <- c(
    4L, 10L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 8L, 2L, 2L, 4L,
    2L, 2L, 12L, 2L, 2L, 8L, 2L, 4L, 2L, 2L, 2L, 4L,
    2L, 6L, 4L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 2L, 4L
  )
  expect_identical(dim(orders), c(120L, 5L))
  expect_identical(nrow(unique(as.data.frame(orders))), 120L)
  expect_equal(sort(unique(scores)), expected_scores, tolerance = 0)
  counts <- vapply(expected_scores, function(k) sum(scores == k), integer(1))
  expect_identical(counts, expected_counts)
  expect_equal(sum(scores > 405), 24)
  expect_equal(sum(scores == 405), 6)
  expect_equal(mean(scores >= 405), 1 / 4, tolerance = 0)

  # Orthogonal columns: rank 3, numerator df 2, denominator df 2.
  design <- cbind(1, data$first, data$second)
  expect_equal(unname(crossprod(design)), diag(c(5, 10, 14)), tolerance = 0)
  expect_equal(sum((data$response - 14 / 5)^2), 154 / 5, tolerance = 1e-12)
  # First-term sequential F = (45/2)/(134/35), NOT the global F.
  expect_gt(abs(1575 / 268 - 405 / 134), 2)

  # Exercise the production statistic at every support point, not just the
  # independent reference formula. One sampled draw per call keeps this small.
  permutation_reference_with_seed(145L, {
    for (i in seq_len(nrow(orders))) {
      data$response <- c(0, 1, 4, 2, 7)[orders[i, ]]
      actual <- pharma_perm_f_test(response ~ first + second, data, R = 1L)
      expect_equal(actual$statistic, scores[i] / (539 - scores[i]),
        tolerance = 1e-12
      )
    }
  })
})

test_that("seeded global F draws and tail counts match the exact reference", {
  data <- permutation_reference_data()
  for (seed in c(7L, 145L)) {
    for (n_draws in c(1L, 31L, 241L)) {
      expected <- permutation_reference_sample(seed, n_draws)
      actual <- permutation_reference_with_seed(seed, {
        result <- pharma_perm_f_test(response ~ first + second, data, R = n_draws)
        list(result = result, state = get(".Random.seed", envir = .GlobalEnv))
      })
      expect_named(actual$result, c("statistic", "perm", "p.value"))
      expect_type(actual$result$perm, "double")
      expect_length(actual$result$perm, n_draws)
      expect_equal(actual$result$statistic, expected$statistic, tolerance = 1e-12)
      expect_equal(actual$result$perm, expected$perm, tolerance = 1e-12)
      # Integer scores count all six mathematical ties exactly. No fitted
      # floating-point threshold supplies this p-value expectation.
      expect_equal(actual$result$p.value, expected$p.value, tolerance = 0)
      expect_identical(actual$state, expected$state)
      first <- permutation_reference_with_seed(seed, {
        pharma_perm_f_test(response ~ first + second, data, R = 1L)
      })
      expect_equal(first$perm, actual$result$perm[1L], tolerance = 0)
    }
  }
})

test_that("response transformations preserve the exact permutation reference", {
  data <- permutation_reference_data()
  expected <- permutation_reference_sample(145L, 241L)
  for (scale in c(2, -2)) {
    transformed <- data
    transformed$response <- 7 + scale * data$response
    actual <- permutation_reference_with_seed(145L, {
      pharma_perm_f_test(response ~ first + second, transformed, R = 241L)
    })
    expect_equal(actual$statistic, expected$statistic, tolerance = 1e-12)
    expect_equal(actual$perm, expected$perm, tolerance = 1e-12)
    expect_equal(actual$p.value, expected$p.value, tolerance = 0)
  }
  actual <- permutation_reference_with_seed(145L, {
    pharma_perm_f_test(I(7 - 2 * response) ~ first + second, data, R = 241L)
  })
  expect_equal(actual$perm, expected$perm, tolerance = 1e-12)
  expect_equal(actual$p.value, expected$p.value, tolerance = 0)
})

test_that("subset and missing-value policies keep exactly the reference rows", {
  data <- permutation_reference_data()
  data$include <- TRUE
  extra <- data.frame(
    first = c(0, NA, -100, 100), second = c(0, 0, -200, 200),
    response = c(NA, 3, -999, 999), include = c(TRUE, TRUE, FALSE, FALSE),
    row.names = c("missing-y", "missing-x", "excluded-1", "excluded-2")
  )
  data <- rbind(data, extra)[c(8, 1, 6, 2, 3, 7, 4, 9, 5), ]
  expected <- permutation_reference_sample(145L, 31L)
  for (action in list(stats::na.omit, stats::na.exclude)) {
    actual <- permutation_reference_with_seed(145L, {
      result <- pharma_perm_f_test(response ~ first + second, data,
        R = 31L, subset = include, na.action = action
      )
      list(result = result, state = get(".Random.seed", envir = .GlobalEnv))
    })
    expect_equal(actual$result$statistic, expected$statistic, tolerance = 1e-12)
    expect_equal(actual$result$perm, expected$perm, tolerance = 1e-12)
    expect_equal(actual$result$p.value, expected$p.value, tolerance = 0)
    expect_identical(actual$state, expected$state)
  }
  permutation_reference_with_seed(145L, {
    before <- get(".Random.seed", envir = .GlobalEnv)
    expect_error(pharma_perm_f_test(response ~ first + second, data,
      R = 1L, subset = include, na.action = stats::na.fail
    ), "missing")
    expect_identical(get(".Random.seed", envir = .GlobalEnv), before)
  })
})

test_that("permutation reference seed isolation also survives errors", {
  permutation_reference_with_seed(901L, {
    before <- get(".Random.seed", envir = .GlobalEnv)
    permutation_reference_sample(145L, 1L)
    expect_identical(get(".Random.seed", envir = .GlobalEnv), before)
    expect_error(permutation_reference_with_seed(145L, {
      sample.int(5L)
      stop("seed restoration probe")
    }), "seed restoration probe")
    expect_identical(get(".Random.seed", envir = .GlobalEnv), before)
    rm(".Random.seed", envir = .GlobalEnv)
    permutation_reference_sample(145L, 1L)
    expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
    expect_error(permutation_reference_with_seed(145L, {
      sample.int(5L)
      stop("seed restoration probe")
    }), "seed restoration probe")
    expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
  })
})
