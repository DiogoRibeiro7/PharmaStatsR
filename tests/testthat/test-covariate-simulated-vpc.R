local_edition(3)

simulated_vpc_fixture <- function() {
  d <- data.frame(Time = 0:3, DV = c(0, 4, 10, 18))
  s <- matrix(c(
    0, 4, 10, 18, 2, 6, 14, 22, 4, 8, 18, 26,
    6, 10, 22, 30, 8, 12, 26, 34
  ), nrow = 4)
  list(data = d, simulations = s)
}

test_that("replicate percentile intervals match fixed type-7 arithmetic", {
  f <- simulated_vpc_fixture()
  plot <- plot_simulated_vpc(f$data, f$simulations,
    bins = 2, probs = c(0.25, 0.5, 0.75), level = 0.5
  )
  # Two observations per bin: type-7 quartiles interpolate by 1/4, 1/2, 3/4.
  # Replicate shifts are (0,2,4,6,8) and (0,4,8,12,16) for bins 1 and 2.
  # Across five replicate statistics the quartiles are order stats 2,3,4.
  expected <- data.frame(
    bin = rep(1:2, each = 3), left = rep(c(0, 1.5), each = 3),
    right = rep(c(1.5, 3), each = 3), bin_time = rep(c(0.5, 2.5), each = 3),
    n = 2L, probability = rep(c(0.25, 0.5, 0.75), 2),
    observed = c(1, 2, 3, 12, 14, 16), simulated = c(5, 6, 7, 20, 22, 24),
    lower = c(3, 4, 5, 16, 18, 20), upper = c(7, 8, 9, 24, 26, 28), nsim = 5L
  )
  expect_s3_class(plot, "ggplot")
  expect_equal(plot$data, expected)
  expect_equal(attr(plot, "vpc_bins"), data.frame(row = as.character(1:4), bin = c(1L, 1L, 2L, 2L)))
  expect_equal(attr(plot, "vpc_settings"), list(
    breaks = c(0, 1.5, 3), probs = c(0.25, 0.5, 0.75), level = 0.5,
    nsim = 5L, quantile_type = 7L
  ))
  # Pooling ten responses gives quartiles (4,6,8), not (5,6,7).
  expect_false(isTRUE(all.equal(plot$data$simulated[1:3], c(4, 6, 8))))
  built <- ggplot2::ggplot_build(plot)
  order <- c(1, 4, 2, 5, 3, 6)
  expect_equal(built$data[[1]]$ymin, expected$lower[order])
  expect_equal(built$data[[1]]$ymax, expected$upper[order])
  expect_equal(built$data[[4]]$y, expected$simulated[order])
  expect_equal(built$data[[5]]$y, expected$observed[order])
  expect_equal(as.numeric(built$layout$layout$probability), c(0.25, 0.5, 0.75))
})

test_that("named rows, literal columns, permutation and affine transforms agree", {
  f <- simulated_vpc_fixture()
  names(f$data) <- c("elapsed time", "response (mg)")
  rownames(f$data) <- rownames(f$simulations) <- c("d", "a", "c", "b")
  original <- f
  run <- function(d, s) {
    plot_simulated_vpc(d, s,
      time = "elapsed time", response = "response (mg)", bins = 2
    )
  }
  base <- run(f$data, f$simulations)
  index <- c(3, 1, 4, 2)
  permuted <- run(f$data[index, ], f$simulations[index, c(5, 2, 3, 1, 4)])
  expect_equal(permuted$data, base$data)
  expect_equal(attr(permuted, "vpc_bins"), attr(base, "vpc_bins")[index, ], ignore_attr = TRUE)
  transformed <- f$data
  transformed[[1]] <- 3 + 2 * transformed[[1]]
  transformed[[2]] <- -7 + 3 * transformed[[2]]
  scaled <- run(transformed, -7 + 3 * f$simulations)$data
  for (column in c("observed", "simulated", "lower", "upper")) {
    expect_equal(scaled[[column]], -7 + 3 * base$data[[column]])
  }
  for (column in c("left", "right", "bin_time")) {
    expect_equal(scaled[[column]], 3 + 2 * base$data[[column]])
  }
  expect_identical(f, original)
  restored <- unserialize(serialize(base, NULL))
  expect_equal(restored$data, base$data)
  expect_equal(attr(restored, "vpc_bins"), attr(base, "vpc_bins"))
})

test_that("ties, empty intervals, constant time and singleton bins are explicit", {
  d <- data.frame(Time = c(0, 0, 0, 0, 1, 1, 1, 1), DV = 1:8)
  s <- cbind(d$DV, d$DV + 2)
  p <- plot_simulated_vpc(d, s, bins = 20, probs = 0.5, level = 0.5)
  expect_equal(p$data$n, c(4L, 4L))
  expect_equal(p$data$observed, c(2.5, 6.5))
  expect_equal(p$data$simulated, c(3.5, 7.5))
  expect_equal(p$data$lower, c(3, 7))
  expect_equal(p$data$upper, c(4, 8))
  expect_true(any(diff(p$data$bin) > 1))
  expect_equal(attr(p, "vpc_bins")$bin, rep(p$data$bin, each = 4))

  d$Time <- 3
  p <- plot_simulated_vpc(d, s, bins = 10, probs = 0.5)
  expect_equal(p$data$n, 8L)
  expect_equal(p$data$observed, 4.5)
  expect_equal(p$data[c("left", "right", "bin_time")], data.frame(left = 3, right = 3, bin_time = 3))
  expect_equal(attr(p, "vpc_settings")$breaks, 3)
  expect_equal(attr(p, "vpc_bins")$bin, rep(1L, 8))
  expect_s3_class(ggplot2::ggplotGrob(p), "gtable")

  singleton <- plot_simulated_vpc(d[1, ], s[1, , drop = FALSE], probs = 0.5, level = 0.5)
  expect_equal(singleton$data$observed, 1)
  expect_equal(singleton$data$simulated, 2)
  expect_equal(singleton$data$lower, 1.5)
  expect_equal(singleton$data$upper, 2.5)
  f <- simulated_vpc_fixture()
  expect_equal(plot_simulated_vpc(f$data, f$simulations, bins = 1)$data$n, rep(4L, 3))
})

test_that("simulations must be complete replicated datasets aligned to observed rows", {
  f <- simulated_vpc_fixture()
  for (s in list(
    NULL, as.data.frame(f$simulations), as.numeric(f$simulations),
    f$simulations[-1, ], f$simulations[, 1, drop = FALSE],
    f$simulations[, FALSE, drop = FALSE], matrix("1", 4, 5),
    f$simulations + 1i, f$simulations > 1, array(1, c(4, 2, 2))
  )) {
    expect_error(plot_simulated_vpc(f$data, s), "finite real numeric matrix")
  }
  for (value in c(NA, NaN, Inf, -Inf)) {
    bad <- f$simulations
    bad[1, 1] <- value
    expect_error(plot_simulated_vpc(f$data, bad), "finite real numeric matrix")
    for (column in c("Time", "DV")) {
      bad_data <- f$data
      bad_data[[column]][1] <- value
      expect_error(plot_simulated_vpc(bad_data, f$simulations), "finite|infinite")
    }
  }
  rownames(f$simulations) <- as.character(4:1)
  expect_error(plot_simulated_vpc(f$data, f$simulations), "row names.*same order")
})

test_that("schema, probability and bin boundaries fail before plotting", {
  f <- simulated_vpc_fixture()
  for (d in list(
    NULL, list(Time = 1, DV = 2), f$data[FALSE, ],
    f$data["Time"], data.frame(Time = 0:3, DV = letters[1:4]),
    data.frame(Time = 0:3, DV = I(matrix(1, 4, 2)))
  )) {
    expect_error(plot_simulated_vpc(d, f$simulations))
  }
  for (value in c("Time", "", NA_character_)) {
    d <- f$data
    names(d)[2] <- value
    expect_error(plot_simulated_vpc(d, f$simulations), "column names")
  }
  for (value in list(NULL, character(), c("Time", "DV"), "", NA_character_, 1, matrix("Time"))) {
    expect_error(plot_simulated_vpc(f$data, f$simulations, time = value), "single nonempty")
    expect_error(plot_simulated_vpc(f$data, f$simulations, response = value), "single nonempty")
  }
  for (value in list(NULL, 0, -1, 1.5, NA, Inf, c(1, 2), "2", 2i, matrix(2), .Machine$integer.max)) {
    expect_error(plot_simulated_vpc(f$data, f$simulations, bins = value), "positive integer")
  }
  for (value in list(NULL, 0, 1, -0.1, 1.1, c(0.5, 0.5), c(0.9, 0.1), NA, Inf, "0.5", 0.5i, matrix(0.5))) {
    expect_error(plot_simulated_vpc(f$data, f$simulations, probs = value), "strictly increasing")
  }
  for (value in list(NULL, 0, 1, -1, NA, Inf, c(0.5, 0.9), "0.5", 0.5i, matrix(0.5))) {
    expect_error(plot_simulated_vpc(f$data, f$simulations, level = value), "strictly between")
  }
})

test_that("summarizing supplied simulations preserves the random stream", {
  f <- simulated_vpc_fixture()
  set.seed(215)
  before <- .Random.seed
  plot_simulated_vpc(f$data, f$simulations)
  expect_identical(.Random.seed, before)
})
