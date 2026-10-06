# Independent linear-model arithmetic for pharma_report_table().
# Expected estimates, standard errors, confidence intervals and p-values are
# reconstructed from group summaries, not broom::tidy() or the wrapper.

report_reference_fit <- function() {
  data <- data.frame(
    response = c(1, 2, 3, 4, 3, 5, 7, 9),
    treatment = factor(rep(c("A", "B"), each = 4))
  )
  stats::lm(response ~ treatment, data = data)
}

report_reference_targets <- function(conf.level) {
  mean_a <- 5 / 2
  mean_b <- 6
  estimate <- c(mean_a, mean_b - mean_a)

  sse_a <- sum((c(1, 2, 3, 4) - mean_a)^2)
  sse_b <- sum((c(3, 5, 7, 9) - mean_b)^2)
  residual_df <- 8 - 2
  mse <- (sse_a + sse_b) / residual_df

  se <- c(
    sqrt(mse / 4),
    sqrt(mse * (1 / 4 + 1 / 4))
  )
  t_stat <- estimate / se
  alpha <- 1 - conf.level
  critical <- stats::qt(1 - alpha / 2, df = residual_df)

  data.frame(
    term = c("(Intercept)", "treatmentB"),
    estimate = estimate,
    conf.low = estimate - critical * se,
    conf.high = estimate + critical * se,
    p.value = 2 * stats::pt(-abs(t_stat), df = residual_df),
    stringsAsFactors = FALSE
  )
}

test_that("report table matches independent two-group lm arithmetic", {
  fit <- report_reference_fit()

  for (level in c(0.90, 0.95)) {
    actual <- pharma_report_table(fit, conf.level = level)
    expected <- report_reference_targets(level)

    expect_identical(names(actual), names(expected))
    expect_identical(actual$term, expected$term)
    expect_equal(actual$estimate, expected$estimate, tolerance = 1e-12)
    expect_equal(actual$conf.low, expected$conf.low, tolerance = 1e-10)
    expect_equal(actual$conf.high, expected$conf.high, tolerance = 1e-10)
    expect_equal(actual$p.value, expected$p.value, tolerance = 1e-10)
  }
})

test_that("report reference exposes its fixed residual arithmetic", {
  expected <- report_reference_targets(0.95)

  expect_equal(expected$estimate, c(2.5, 3.5), tolerance = 0)

  mse <- 25 / 6
  se_intercept <- sqrt(25 / 24)
  se_treatment <- sqrt(25 / 12)
  expect_equal(se_intercept, 5 / sqrt(24), tolerance = 1e-15)
  expect_equal(se_treatment, 5 / sqrt(12), tolerance = 1e-15)

  t_stat <- c(2.5 / se_intercept, 3.5 / se_treatment)
  expect_equal(t_stat, c(sqrt(6), 0.7 * sqrt(12)), tolerance = 1e-12)
  expect_equal(
    expected$p.value,
    2 * stats::pt(-abs(t_stat), df = 6),
    tolerance = 1e-12
  )
  expect_equal(mse, 25 / 6, tolerance = 0)
})

test_that("Excel and Word exports retain the independent numerical table", {
  fit <- report_reference_fit()
  expected <- report_reference_targets(0.95)

  if (requireNamespace("openxlsx", quietly = TRUE)) {
    xlsx <- tempfile(fileext = ".xlsx")
    on.exit(unlink(xlsx), add = TRUE)
    returned <- pharma_report_table(fit, file = xlsx, conf.level = 0.95)
    saved <- openxlsx::read.xlsx(xlsx)

    expect_equal(as.data.frame(returned), expected, tolerance = 1e-10)
    expect_identical(saved$term, expected$term)
    expect_equal(saved$estimate, expected$estimate, tolerance = 1e-10)
    expect_equal(saved$conf.low, expected$conf.low, tolerance = 1e-10)
    expect_equal(saved$conf.high, expected$conf.high, tolerance = 1e-10)
    expect_equal(saved$p.value, expected$p.value, tolerance = 1e-10)
  }

  if (requireNamespace("flextable", quietly = TRUE) &&
      requireNamespace("officer", quietly = TRUE)) {
    docx <- tempfile(fileext = ".docx")
    on.exit(unlink(docx), add = TRUE)
    returned <- pharma_report_table(fit, file = docx, conf.level = 0.95)
    content <- officer::docx_summary(officer::read_docx(docx))
    cells <- content$text[content$content_type == "table cell"]

    expect_equal(as.data.frame(returned), expected, tolerance = 1e-10)
    expect_true(all(expected$term %in% cells))
    expect_true(all(names(expected) %in% cells))
  }
})
