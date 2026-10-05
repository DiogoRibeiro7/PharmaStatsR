# Independent normal-equation derivation: docs/model-diagnostics.md.
# Expected diagnostics never call the stats diagnostic methods used by the
# wrapper. The six cases are synthetic, complete, and have unique row names.
diagnostic_reference_data <- function() {
  data.frame(
    x = c(-3, -1, 0, 0, 1, 3),
    y = c(0, -1, 3, 1, 4, 5),
    row.names = sprintf("case-%02d", seq_len(6))
  )
}

diagnostic_reference_values <- function() {
  # X'X = diag(6, 20), beta = (2, 1), SSE = 8, n - p = 4.
  data.frame(
    residual = c(1, -2, 1, -1, 1, 0),
    std_resid = c(
      sqrt(30 / 23), -sqrt(120 / 47), sqrt(3 / 5),
      -sqrt(3 / 5), sqrt(30 / 47), 0
    ),
    cook_d = c(555 / 529, 780 / 2209, 3 / 50, 3 / 50, 195 / 2209, 0),
    leverage = c(37 / 60, 13 / 60, 1 / 6, 1 / 6, 13 / 60, 37 / 60),
    flag = c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE),
    row.names = sprintf("case-%02d", seq_len(6))
  )
}

test_that("lm diagnostics match independent normal-equation targets", {
  fit <- stats::lm(y ~ x, data = diagnostic_reference_data())
  actual <- pharma_model_diagnostics(fit)
  expected <- diagnostic_reference_values()

  expect_equal(unname(stats::coef(fit)), c(2, 1), tolerance = 1e-12)
  expect_equal(fit$df.residual, 4)
  expect_s3_class(actual, "data.frame")
  expect_named(actual, c("residual", "std_resid", "cook_d", "leverage", "flag"))
  expect_identical(rownames(actual), rownames(expected))
  expect_true(all(vapply(actual[1:4], is.numeric, logical(1))))
  expect_type(actual$flag, "logical")
  expect_equal(actual, expected, tolerance = 1e-12)
  expect_identical(actual$flag, expected$flag)
  # High leverage alone does not trigger the residual/Cook screening rule.
  expect_false(actual$flag[6])
})

test_that("residual and Cook cutoffs contribute separately to the flag", {
  fit <- stats::lm(y ~ x, data = diagnostic_reference_data())
  residual_only <- pharma_model_diagnostics(fit, threshold = 1.5, cook_cutoff = 100)
  cook_only <- pharma_model_diagnostics(fit, threshold = 100, cook_cutoff = 0.8)
  combined <- pharma_model_diagnostics(fit, threshold = 1.5, cook_cutoff = 0.8)
  expect_identical(residual_only$flag, c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE))
  expect_identical(cook_only$flag, c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE))
  expect_identical(combined$flag, c(TRUE, TRUE, FALSE, FALSE, FALSE, FALSE))
})

test_that("screening uses strict greater-than comparisons at both cutoffs", {
  fit <- stats::lm(y ~ x, data = diagnostic_reference_data())
  measures <- pharma_model_diagnostics(fit)
  # Use the returned floating-point maxima only to set an exactly equal
  # cutoff. Independent numerical expectations are checked above; rounded
  # decimal cutoffs could otherwise lie on either side of exact equality.
  residual_boundary <- abs(measures$std_resid[2])
  cook_boundary <- measures$cook_d[1]
  expect_identical(
    pharma_model_diagnostics(fit, residual_boundary, 100)$flag,
    rep(FALSE, 6)
  )
  expect_identical(
    pharma_model_diagnostics(fit, residual_boundary * (1 - 1e-8), 100)$flag,
    c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE)
  )
  expect_identical(
    pharma_model_diagnostics(fit, 100, cook_boundary)$flag,
    rep(FALSE, 6)
  )
  expect_identical(
    pharma_model_diagnostics(fit, 100, cook_boundary * (1 - 1e-8))$flag,
    c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE)
  )
})

test_that("selected lm rows preserve targets through omit and exclude", {
  data <- diagnostic_reference_data()
  data$selected <- TRUE
  extra <- data.frame(
    x = c(-5, -4, -3, 3, 4, 5, -100, 100),
    y = c(rep(NA_real_, 6), -500, 500),
    selected = c(rep(TRUE, 6), FALSE, FALSE),
    row.names = c(sprintf("missing-%02d", seq_len(6)), "excluded-1", "excluded-2")
  )
  data <- rbind(data, extra)
  # Interleave six omitted responses and two complete subset exclusions.
  data <- data[c(13, 1, 7, 2, 8, 3, 9, 14, 4, 10, 5, 11, 6, 12), ]
  expected <- diagnostic_reference_values()

  omitted <- stats::lm(y ~ x, data, subset = selected, na.action = stats::na.omit)
  excluded <- stats::lm(y ~ x, data, subset = selected, na.action = stats::na.exclude)
  expect_equal(stats::nobs(omitted), 6)
  expect_equal(stats::nobs(excluded), 6)
  expect_equal(pharma_model_diagnostics(omitted), expected, tolerance = 1e-12)

  actual <- pharma_model_diagnostics(excluded)
  selected_ids <- rownames(data)[data$selected]
  padded <- data.frame(
    residual = rep(NA_real_, 12), std_resid = rep(NA_real_, 12),
    cook_d = rep(NA_real_, 12), leverage = rep(0, 12),
    flag = rep(NA, 12), row.names = selected_ids
  )
  padded[rownames(expected), ] <- expected
  expect_identical(rownames(actual), selected_ids)
  expect_equal(actual, padded, tolerance = 1e-12)
  expect_identical(actual$flag, padded$flag)
  # lm.influence() restores omitted rows with zero leverage, not NA.
  # Residual-based measures and flags remain unavailable at those positions.
  missing_rows <- grepl("^missing-", rownames(actual))
  expect_identical(actual$leverage[missing_rows], rep(0, 6))
  expect_true(all(is.na(actual[
    missing_rows, c("residual", "std_resid", "cook_d", "flag")
  ])))
  expect_false(any(grepl("^excluded-", rownames(actual))))

  # D_2 is below 4/6 but above 4/12: restored rows must not change the rule.
  expect_lt(780 / 2209, 4 / 6)
  expect_gt(780 / 2209, 4 / 12)
  expect_false(actual["case-02", "flag"])
})

test_that("affine response changes preserve standardized diagnostic magnitudes", {
  for (scale in c(2, -2)) {
    data <- diagnostic_reference_data()
    data$y <- 7 + scale * data$y
    expected <- diagnostic_reference_values()
    expected$residual <- scale * expected$residual
    expected$std_resid <- sign(scale) * expected$std_resid
    fit <- stats::lm(y ~ x, data)
    expect_equal(unname(stats::coef(fit)), c(7 + 2 * scale, scale), tolerance = 1e-12)
    expect_equal(pharma_model_diagnostics(fit), expected, tolerance = 1e-12)
  }
})

test_that("row permutations preserve named independent diagnostic targets", {
  order <- c(6, 2, 4, 1, 5, 3)
  data <- diagnostic_reference_data()[order, ]
  expected <- diagnostic_reference_values()[order, ]
  actual <- pharma_model_diagnostics(stats::lm(y ~ x, data))
  expect_identical(rownames(actual), rownames(expected))
  expect_equal(actual, expected, tolerance = 1e-12)
  expect_identical(actual$flag, expected$flag)
})
