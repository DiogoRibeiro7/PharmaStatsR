# Independent risk-set derivations and numerical targets:
# docs/survival-regression.md, "Independent ordinary Cox reference".
# No expected value below comes from a second coxph() fit.
ordinary_cox_reference_data <- function() {
  treatment <- factor(
    rep(c("control", "active"), each = 6),
    levels = c("control", "active")
  )
  # Fix the reference group independently of the session's contrast options.
  stats::contrasts(treatment) <- stats::contr.treatment(levels(treatment))
  data.frame(
    time = c(1, 2, 2, 3, 5, 6, 1, 2, 3, 3, 4, 6),
    status = c(1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0),
    treatment = treatment,
    selected = TRUE,
    row.names = sprintf("subject-%02d", seq_len(12))
  )
}

# Scalar partial log likelihood, score, and observed information for this
# fixture only. These are analytic expressions, not a general Cox fitter.
ordinary_cox_reference_terms <- function(beta, method) {
  stopifnot(
    is.numeric(beta), length(beta) == 1L, is.finite(beta),
    is.character(method), length(method) == 1L,
    method %in% c("breslow", "efron")
  )
  r <- exp(beta)
  if (method == "breslow") {
    return(list(
      loglik = 3 * beta - log(300) - 5 * log1p(r) - 2 * log(3 + 4 * r),
      score = 3 - 5 * r / (1 + r) - 8 * r / (3 + 4 * r),
      information = 5 * r / (1 + r)^2 + 24 * r / (3 + 4 * r)^2
    ))
  }
  list(
    loglik = 3 * beta - log(135) - 5 * log1p(r) -
      log(3 + 4 * r) - log(5 + 7 * r),
    score = 3 - 5 * r / (1 + r) - 4 * r / (3 + 4 * r) -
      7 * r / (5 + 7 * r),
    information = 5 * r / (1 + r)^2 + 12 * r / (3 + 4 * r)^2 +
      35 * r / (5 + 7 * r)^2
  )
}

expect_ordinary_cox_reference <- function(actual, method) {
  expected <- switch(method,
    breslow = list(
      beta = log((sqrt(145) - 1) / 16),
      variance = 0.5857860744819957,
      se = 0.7653666274942981,
      loglik = c(-13.0613386755665542, -12.9424910951151456),
      log_ci = c(-1.8710102801936754, 1.1291717695217406)
    ),
    efron = list(
      beta = -0.3780599269349066,
      variance = 0.5862490959986279,
      se = 0.7656690512216279,
      loglik = c(-12.8018274800814696, -12.6784431161375415),
      log_ci = c(-1.8787436914062513, 1.1226238375364381)
    ),
    stop("Unknown reference tie method")
  )
  expect_s3_class(actual, "coxph")
  expect_identical(actual$method, method)
  expect_equal(actual$n, 12)
  expect_equal(actual$nevent, 7)
  expect_null(actual$naive.var)
  expect_identical(names(stats::coef(actual)), "treatmentactive")
  beta <- unname(stats::coef(actual))
  expect_equal(beta, expected$beta, tolerance = 1e-7)
  expect_equal(
    unname(stats::vcov(actual)), matrix(expected$variance, nrow = 1),
    tolerance = 1e-7
  )
  expect_equal(actual$loglik, expected$loglik, tolerance = 1e-9)

  # Check the returned uncertainty on the log-hazard-ratio scale, as well
  # as the exponentiated effect and the model-based 95% Wald interval.
  result <- summary(actual, conf.int = 0.95)
  expect_equal(
    unname(result$coefficients["treatmentactive", "se(coef)"]),
    expected$se, tolerance = 1e-7
  )
  expect_equal(
    unname(result$coefficients["treatmentactive", "exp(coef)"]),
    exp(expected$beta), tolerance = 1e-7
  )
  expect_equal(
    unname(log(result$conf.int["treatmentactive", c("lower .95", "upper .95")])),
    expected$log_ci, tolerance = 1e-7
  )

  # Evaluate the independent derivatives at the wrapper's fitted value.
  terms <- ordinary_cox_reference_terms(beta, method)
  expect_lt(abs(terms$score), 1e-7)
  expect_equal(terms$information, 1 / expected$variance, tolerance = 1e-7)
  expect_equal(actual$loglik[2], terms$loglik, tolerance = 1e-9)
  expect_equal(
    ordinary_cox_reference_terms(0, method)$loglik,
    expected$loglik[1], tolerance = 1e-12
  )
}

test_that("ordinary Cox fits match independent Breslow and Efron references", {
  data <- ordinary_cox_reference_data()
  for (method in c("breslow", "efron")) {
    actual <- pharma_survival_fit(
      survival::Surv(time, status) ~ treatment, data,
      ties = method, robust = FALSE, model = TRUE, x = TRUE, y = TRUE
    )
    expect_ordinary_cox_reference(actual, method)
    expect_identical(rownames(actual$model), rownames(data))
    expect_equal(unname(actual$x[, "treatmentactive"]), rep(c(0, 1), each = 6))
    expect_equal(unname(actual$y[, "time"]), data$time)
    expect_equal(unname(actual$y[, "status"]), data$status)
  }
})

test_that("the default ordinary Cox tie rule matches the Efron reference", {
  actual <- pharma_survival_fit(
    survival::Surv(time, status) ~ treatment,
    ordinary_cox_reference_data(), robust = FALSE
  )
  expect_ordinary_cox_reference(actual, "efron")
})

test_that("selected complete Cox rows retain the independent references", {
  reference_data <- ordinary_cox_reference_data()
  extra <- reference_data[1:6, , drop = FALSE]
  extra$time <- c(0.1, 0.2, 100, NA, 2, 1)
  extra$status <- c(1, 1, 0, 1, NA, 1)
  extra$treatment[6] <- NA
  extra$selected <- c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE)
  rownames(extra) <- c(
    "excluded-1", "excluded-2", "excluded-3",
    "missing-time", "missing-status", "missing-treatment"
  )
  data <- rbind(reference_data, extra)

  # Three complete decoys must be excluded before the three incomplete
  # selected observations are handled by the explicit missing-data policy.
  for (method in c("breslow", "efron")) {
    for (action in list(stats::na.omit, stats::na.exclude)) {
      actual <- pharma_survival_fit(
        survival::Surv(time, status) ~ treatment, data,
        subset = selected, na.action = action, ties = method,
        robust = FALSE, model = TRUE, x = TRUE, y = TRUE
      )
      expect_ordinary_cox_reference(actual, method)
      expect_identical(rownames(actual$model), rownames(reference_data))
      expect_identical(names(actual$na.action), rownames(extra)[4:6])
      expect_equal(unname(actual$x[, "treatmentactive"]), rep(c(0, 1), each = 6))
      expect_equal(unname(actual$y[, "time"]), reference_data$time)
      expect_equal(unname(actual$y[, "status"]), reference_data$status)
    }
  }
  # This is an input-policy boundary, not an optimizer-message assertion.
  expect_error(pharma_survival_fit(
    survival::Surv(time, status) ~ treatment, data,
    subset = selected, na.action = stats::na.fail, ties = "breslow"
  ))
})

test_that("row order does not change the tied Cox numerical reference", {
  data <- ordinary_cox_reference_data()
  data <- data[rev(seq_len(nrow(data))), , drop = FALSE]
  for (method in c("breslow", "efron")) {
    actual <- pharma_survival_fit(
      survival::Surv(time, status) ~ treatment, data,
      ties = method, robust = FALSE
    )
    expect_ordinary_cox_reference(actual, method)
  }
})
