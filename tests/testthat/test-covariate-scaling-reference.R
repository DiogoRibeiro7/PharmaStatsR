local_edition(3)

test_that("sample scaling matches fixed references across extreme units", {
  # x has mean 3, centered sum of squares 10 and 4 observed values.
  # y has mean 0, centered sum of squares 8 and 3 observed values.
  x <- c(1, 2, 4, 5, NA_real_, NaN)
  y <- c(-2, 0, 2, NA_real_, NaN, NA_real_)
  for (unit in c(1, 1e200, 1e-200, 2^700, 2^-700)) {
    for (direction in c(1, -1)) {
      d <- data.frame(x = direction * unit * x, y = unit * y, group = factor(letters[1:6]))
      names(d)[1:2] <- c("body mass", "x+y")
      rownames(d) <- paste0("row-", 6:1)
      original <- d
      fitted <- center_scale(d, c("x+y", "body mass"))
      # Compare ratios so tiny expected values cannot pass an absolute tolerance.
      expect_equal(fitted$params$mean / unit, c(0, 3 * direction), tolerance = 1e-14)
      expect_equal(fitted$params$sd / unit, c(2, sqrt(10 / 3)), tolerance = 1e-14)
      expect_identical(fitted$params$var, c("x+y", "body mass"))
      expect_equal(fitted$data[["body mass"]], direction * (x - 3) / sqrt(10 / 3), tolerance = 1e-14)
      expect_equal(fitted$data[["x+y"]], y / 2, tolerance = 1e-14)
      expect_identical(fitted$data[["body mass"]][5:6], c(NA_real_, NaN))
      expect_identical(fitted$data$group, d$group)
      expect_identical(rownames(fitted$data), rownames(d))
      expect_identical(names(fitted$data), names(d))
      expect_identical(apply_center_scale(d, fitted$params), fitted$data)
      expect_identical(d, original)
    }
  }
})

test_that("large offsets retain small representable differences", {
  offset <- 2^600
  step <- 2^548
  d <- data.frame(x = offset + c(0, 1, 2, 4) * step)
  fitted <- center_scale(d, "x")
  # The mathematical mean offset is 7/4 steps and rounds to 2 steps.
  # Variance about the exact mean is (35/12)*step^2. Computing SD on
  # centered, normalized differences removes that rounded-mean offset.
  expect_identical(fitted$params$mean, offset + 2 * step)
  expect_equal(fitted$params$sd / step, sqrt(35 / 12), tolerance = 1e-14)
  expect_equal(fitted$data$x, c(-2, -1, 0, 2) / sqrt(35 / 12), tolerance = 1e-14)
  expect_identical(apply_center_scale(d, fitted$params), fitted$data)
  expect_equal(center_scale(d[c(4, 2, 1, 3), , drop = FALSE], "x")$data$x,
    fitted$data$x[c(4, 2, 1, 3)],
    tolerance = 1e-14
  )
})

test_that("overflowing subtraction still gives finite training and saved results", {
  unit <- 1e308
  d <- data.frame(x = c(-1.5, 1.5, 1.5, 1.5, 1.5) * unit)
  fitted <- center_scale(d, "x")
  # A lone value -1.5 among four 1.5 values: mean=.9, sample SD=3/sqrt(5).
  expect_equal(fitted$params$mean / unit, 0.9, tolerance = 1e-14)
  expect_equal(fitted$params$sd / unit, 3 / sqrt(5), tolerance = 1e-14)
  expect_equal(fitted$data$x, c(-4, 1, 1, 1, 1) / sqrt(5), tolerance = 1e-14)
  expect_true(all(is.finite(fitted$data$x)))
  expect_identical(apply_center_scale(d, fitted$params), fitted$data)
  file <- tempfile(fileext = ".rds")
  on.exit(unlink(file), add = TRUE)
  saveRDS(fitted$params, file)
  params <- readRDS(file)
  new <- data.frame(x = c(-1.5, 0, 1.5, NA_real_) * unit)
  expected <- c(-4, -1.5, 1, NA_real_) / sqrt(5)
  expect_equal(apply_center_scale(new, params)$x, expected, tolerance = 1e-14)
  expect_identical(params, fitted$params)
  augmented <- rbind(new, data.frame(x = 0.5 * unit))
  expect_identical(apply_center_scale(augmented, params)$x[1:4], apply_center_scale(new, params)$x)
})

test_that("ordinary finite mean and SD estimates retain their exact results", {
  d <- data.frame(x = c(1, 2, 4, 5, NA), y = c(0.1, 0.3, 0.9, 1.4, NA))
  fitted <- center_scale(d, c("x", "y"))
  for (i in 1:2) {
    mu <- mean(d[[i]], na.rm = TRUE)
    spread <- stats::sd(d[[i]], na.rm = TRUE)
    expect_identical(fitted$params$mean[i], mu)
    expect_identical(fitted$params$sd[i], spread)
    expect_identical(fitted$data[[i]], (d[[i]] - mu) / spread)
  }
})

test_that("fallback cannot invent variation or represent impossible scales", {
  tiny <- .Machine$double.xmin * .Machine$double.eps
  for (x in list(rep(1e300, 3), c(-1.3e308, 1.3e308), c(0, 0, 0, tiny))) {
    expect_error(center_scale(data.frame(x = x), "x"), "positive, finite.*standard deviation")
  }
  # These intended increments were already rounded away before the call.
  expect_error(center_scale(data.frame(x = 2^600 + c(0, 1, 2)), "x"), "positive, finite.*standard deviation")
  for (x in list(numeric(), NA_real_, c(1e300, NA_real_, NaN))) {
    expect_error(center_scale(data.frame(x = x), "x"), "at least two observed")
  }
})
