# Fixed cluster totals and exact support: docs/cluster-bootstrap.md.
# Expected statistics are calculated from this ledger, not backend resamples.
cluster_reference_data <- function() {
  data.frame(
    cluster = c("C", "A", "B", "C", "B", "C"),
    row_id = c("C-1", "A-1", "B-1", "C-2", "B-2", "C-3"),
    value = c(6, 0, 2, 8, 4, 10),
    unused = rep(NA_real_, 6),
    stringsAsFactors = FALSE
  )
}

# Test-only seed isolation; production calls still advance the caller's stream.
cluster_reference_with_seed <- function(seed, code) {
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

# Cluster A: size 1, total 0; B: size 2, total 6; C: size 3, total 24.
# IDs follow explicit factor order A, B, C, regardless of input-row order.
cluster_reference_values <- function(ids, shift = 0, multiplier = 1) {
  stopifnot(
    is.numeric(ids), length(ids) == 3L,
    all(is.finite(ids)), all(ids %in% seq_len(3L))
  )
  sizes <- c(1L, 2L, 3L)
  counts <- tabulate(ids, nbins = 3L)
  n_rows <- sum(sizes[ids])
  row_ids <- list("A-1", c("B-1", "B-2"), c("C-1", "C-2", "C-3"))
  list(
    pooled = shift + multiplier * (6 * counts[2] + 24 * counts[3]) / n_rows,
    equal_copy = shift + multiplier * (3 * counts[2] + 8 * counts[3]) / 3,
    n_rows = as.integer(n_rows),
    source = rep(c("A", "B", "C")[ids], sizes[ids]),
    row_id = unlist(row_ids[ids], use.names = FALSE),
    copy_id = rep(seq_len(3L), sizes[ids]),
    missing_values = 0L,
    unused = rep(NA_real_, n_rows)
  )
}

# This is the actual user callback, deliberately distinct from the ledger.
cluster_reference_statistic <- function(rows, shift = 0, multiplier = 1,
                                        na.rm = FALSE) {
  copy_means <- vapply(split(rows$value, rows$copy_id), function(x) {
    mean(x, na.rm = na.rm)
  }, numeric(1))
  list(
    pooled = shift + multiplier * mean(rows$value, na.rm = na.rm),
    equal_copy = shift + multiplier * mean(copy_means),
    n_rows = nrow(rows),
    source = as.character(rows$cluster),
    row_id = rows$row_id,
    copy_id = rows$copy_id,
    missing_values = as.integer(sum(is.na(rows$value))),
    unused = rows$unused
  )
}

test_that("unequal-cluster support has independent exact conditional moments", {
  orders <- as.matrix(expand.grid(
    first = seq_len(3L), second = seq_len(3L), third = seq_len(3L),
    KEEP.OUT.ATTRS = FALSE
  ))
  counts <- t(apply(orders, 1L, tabulate, nbins = 3L))
  keys <- apply(counts, 1L, paste, collapse = ",")
  expected_keys <- c(
    "3,0,0", "2,1,0", "2,0,1", "1,2,0", "1,1,1",
    "1,0,2", "0,3,0", "0,2,1", "0,1,2", "0,0,3"
  )
  expected_counts <- c(1L, 3L, 3L, 3L, 6L, 3L, 1L, 3L, 3L, 1L)
  expected <- cbind(
    pooled = c(0, 3 / 2, 24 / 5, 12 / 5, 5, 48 / 7, 3, 36 / 7, 27 / 4, 8),
    equal_copy = c(0, 1, 8 / 3, 2, 11 / 3, 16 / 3, 3, 14 / 3, 19 / 3, 8)
  )
  draws <- lapply(seq_len(nrow(orders)), function(i) {
    cluster_reference_values(orders[i, ])
  })
  values <- t(vapply(draws, function(x) {
    c(pooled = x$pooled, equal_copy = x$equal_copy)
  }, c(pooled = 0, equal_copy = 0)))
  matched <- match(keys, expected_keys)
  expect_identical(dim(orders), c(27L, 3L))
  expect_identical(nrow(unique(as.data.frame(orders))), 27L)
  expect_false(anyNA(matched))
  expect_identical(tabulate(matched, nbins = 10L), expected_counts)
  expect_equal(values, expected[matched, , drop = FALSE], tolerance = 1e-12)

  # These are moments of the whole distribution, with denominator 27, not 26.
  center <- c(2467 / 540, 11 / 3)
  covariance <- matrix(c(
    14515811 / 3572100, 10288 / 2835,
    10288 / 2835, 98 / 27
  ), nrow = 2L)
  expect_equal(unname(colMeans(values)), center, tolerance = 1e-12)
  centered <- sweep(values, 2L, center, "-")
  expect_equal(unname(crossprod(centered) / 27), covariance, tolerance = 1e-12)
  sizes <- vapply(draws, `[[`, integer(1), "n_rows")
  expect_identical(tabulate(sizes - 2L, nbins = 7L), c(1L, 3L, 6L, 7L, 6L, 3L, 1L))
  expect_equal(mean(sizes), 6, tolerance = 0)
  # A mean of ratios need not equal the original pooled-row mean of 5.
  expect_gt(abs(center[1] - 5), 0.4)
})

test_that("seeded cluster samples retain ledger statistics and copy identities", {
  data <- cluster_reference_data()
  original <- data
  forms <- list(
    "cluster", data$cluster,
    factor(data$cluster, levels = c("A", "B", "C", "unused"))
  )
  for (seed in c(21L, 149L)) {
    for (n_draws in c(1L, 31L)) {
      reference <- cluster_reference_with_seed(seed, {
        ids <- lapply(seq_len(n_draws), function(i) {
          sample.int(3L, 3L, replace = TRUE)
        })
        list(
          draws = lapply(ids, cluster_reference_values),
          state = get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
        )
      })
      for (cluster in forms) {
        actual <- cluster_reference_with_seed(seed, {
          draws <- pharma_block_bootstrap(
            data, cluster, cluster_reference_statistic, R = n_draws,
            progress = FALSE, resample_id = "copy_id"
          )
          list(draws = draws, state = get(".Random.seed", envir = .GlobalEnv))
        })
        expect_type(actual$draws, "list")
        expect_length(actual$draws, n_draws)
        expect_equal(actual$draws, reference$draws, tolerance = 1e-12)
        expect_identical(actual$state, reference$state)
        for (i in seq_len(n_draws)) {
          expect_identical(actual$draws[[i]]$row_id, reference$draws[[i]]$row_id)
          expect_identical(actual$draws[[i]]$copy_id, reference$draws[[i]]$copy_id)
          expect_identical(unique(actual$draws[[i]]$copy_id), seq_len(3L))
          expect_identical(actual$draws[[i]]$source, reference$draws[[i]]$source)
        }
        first <- cluster_reference_with_seed(seed, {
          pharma_block_bootstrap(
            data, cluster, cluster_reference_statistic, R = 1L,
            progress = FALSE, resample_id = "copy_id"
          )
        })
        expect_identical(first, actual$draws[1L])
      }
    }
  }
  expect_identical(data, original)
})

test_that("cluster means preserve affine values and forwarded callback arguments", {
  data <- cluster_reference_data()
  ids <- cluster_reference_with_seed(149L, {
    lapply(seq_len(31L), function(i) sample.int(3L, 3L, replace = TRUE))
  })
  for (multiplier in c(2, -2)) {
    expected <- lapply(ids, cluster_reference_values, shift = 7, multiplier = multiplier)
    transformed <- data
    transformed$value <- 7 + multiplier * data$value
    actual <- cluster_reference_with_seed(149L, {
      pharma_block_bootstrap(
        transformed, "cluster", cluster_reference_statistic, R = 31L,
        progress = FALSE, resample_id = "copy_id"
      )
    })
    forwarded <- cluster_reference_with_seed(149L, {
      pharma_block_bootstrap(
        data, "cluster", cluster_reference_statistic, R = 31L,
        progress = FALSE, shift = 7, multiplier = multiplier,
        resample_id = "copy_id"
      )
    })
    expect_equal(actual, expected, tolerance = 1e-12)
    expect_equal(forwarded, expected, tolerance = 1e-12)
  }
})

test_that("missing non-ID values reach the callback without changing samples", {
  data <- cluster_reference_data()
  data$value[data$row_id == "B-2"] <- NA_real_
  ids <- cluster_reference_with_seed(149L, {
    lapply(seq_len(31L), function(i) sample.int(3L, 3L, replace = TRUE))
  })
  for (remove_missing in c(FALSE, TRUE)) {
    expected <- lapply(ids, function(draw) {
      out <- cluster_reference_values(draw)
      counts <- tabulate(draw, nbins = 3L)
      out$missing_values <- counts[2]
      if (remove_missing) {
        # B has one observed value of 2; its missing row still reaches the callback.
        out$pooled <- (2 * counts[2] + 24 * counts[3]) /
          (counts[1] + counts[2] + 3 * counts[3])
        out$equal_copy <- (2 * counts[2] + 8 * counts[3]) / 3
      } else if (counts[2] > 0L) {
        out$pooled <- NA_real_
        out$equal_copy <- NA_real_
      }
      out
    })
    actual <- cluster_reference_with_seed(149L, {
      pharma_block_bootstrap(
        data, "cluster", cluster_reference_statistic, R = 31L,
        progress = FALSE, na.rm = remove_missing, resample_id = "copy_id"
      )
    })
    expect_equal(actual, expected, tolerance = 1e-12)
    expect_identical(lapply(actual, `[[`, "row_id"), lapply(expected, `[[`, "row_id"))
  }
})
