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
})

test_that("joint model fits compatible nlme and Cox models", {
  skip_if_not_installed("JM")
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
})
