test_that("joint model reports a missing JM backend", {
  testthat::local_mocked_bindings(.pharma_jm_available = function() FALSE)
  expect_error(
    pharma_joint_model(NULL, NULL, "time"),
    "install.packages\\('JM'\\)"
  )
})

test_that("joint model rejects unsupported fits and invalid time variables", {
  skip_if_not_installed("JM")

  longitudinal <- structure(
    list(data = data.frame(obstime = c(0, 1))), class = "lme"
  )
  survival <- structure(list(x = matrix(1, nrow = 2)), class = "coxph")

  expect_error(
    pharma_joint_model(structure(list(), class = "lmerMod"), survival, "obstime"),
    "nlme::lme"
  )
  expect_error(pharma_joint_model(longitudinal, list(), "obstime"),
               "survival::coxph")
  expect_error(pharma_joint_model(longitudinal, structure(list(), class = "coxph"),
                                  "obstime"), "x = TRUE")
  for (invalid in list(NA_character_, "", c("obstime", "visit"), 1)) {
    expect_error(pharma_joint_model(longitudinal, survival, invalid),
                 "timeVar must be a nonempty character string")
  }
  expect_error(pharma_joint_model(longitudinal, survival, "visit"),
               "timeVar not found")

  testthat::local_mocked_bindings(.pharma_jm_attached = function() FALSE)
  expect_error(pharma_joint_model(longitudinal, survival, "obstime"),
               "library\\(JM\\)")
})

test_that("joint model fits compatible nlme and Cox models", {
  skip_if_not_installed("JM")
  attached_before <- search()
  on.exit({
    added <- search()[!search() %in% attached_before]
    for (package in added[startsWith(added, "package:")]) {
      if (package %in% search()) {
        detach(package, character.only = TRUE)
      }
    }
  }, add = TRUE)
  suppressPackageStartupMessages(library(JM))
  data("aids", package = "JM", envir = environment())
  data("aids.id", package = "JM", envir = environment())

  longitudinal <- nlme::lme(
    sqrt(CD4) ~ obstime * drug - drug,
    random = ~ 1 | patient, data = aids
  )
  survival <- survival::coxph(
    survival::Surv(Time, death) ~ drug, data = aids.id, x = TRUE
  )

  fit <- pharma_joint_model(longitudinal, survival, timeVar = "obstime",
                            method = "weibull-PH-GH")
  expect_s3_class(fit, "jointModel")
  expect_identical(fit$method, "weibull-PH-GH")
  expect_identical(fit$timeVar, "obstime")
  expect_identical(fit$parameterization, "value")
  expect_equal(fit$convergence, 0, tolerance = 0)
  expect_equal(fit$N, nrow(aids), tolerance = 0)
  expect_equal(fit$n, nrow(aids.id), tolerance = 0)
  expect_length(fit$d, nrow(aids.id))
  expect_equal(sum(fit$d), sum(aids.id$death), tolerance = 0)
  expect_length(fit$ni, fit$n)
  expect_equal(sum(fit$ni), fit$N, tolerance = 0)

  required_coefficients <- c("betas", "sigma", "gammas", "alpha", "sigma.t", "D")
  expect_true(all(required_coefficients %in% names(fit$coefficients)))
  expect_identical(
    names(fit$coefficients$betas),
    names(nlme::fixed.effects(longitudinal))
  )
  expect_identical(
    names(fit$coefficients$gammas),
    names(stats::coef(survival))
  )
  numeric_parts <- unlist(fit$coefficients[required_coefficients], use.names = FALSE)
  expect_true(all(is.finite(numeric_parts)))
  expect_gt(fit$coefficients$sigma, 0)

  ll <- stats::logLik(fit)
  expect_true(is.finite(as.numeric(ll)))
  expect_equal(attr(ll, "nobs"), fit$n, tolerance = 0)
})
