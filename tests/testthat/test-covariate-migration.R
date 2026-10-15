local_edition(3)

test_that("installed covariate data supports a complete PharmaStatsR workflow", {
  datasets <- new.env(parent = baseenv())
  utils::data("pharmo_example", package = "PharmaStatsR", envir = datasets)
  d <- datasets$pharmo_example
  expect_equal(dim(d), c(500L, 6L))
  expect_true(validate_data_schema(d))
  d$WT[1] <- NA_real_
  prepared <- impute_ml(d, "WT",
    k = 3, predictors = c("AGE", "CRCL"),
    distance = "gower", weights = c(AGE = 2)
  )
  expect_true(is.finite(prepared$WT[1]))
  scaled <- center_scale(prepared, c("WT", "AGE", "CRCL"))
  expect_equal(apply_center_scale(prepared, scaled$params), scaled$data)
  model <- fit_covariate_model(
    scaled$data, "DV", "SubjectID", c("Time", "WT", "AGE")
  )
  expect_s3_class(model, "lme")
  expect_equal(nrow(model$data), nrow(d))
  expect_s3_class(plot_obs_vs_pred(model, scaled$data), "ggplot")
  expect_s3_class(plot_residuals(model), "ggplot")
})

test_that("installed report and app resources use the consolidated package", {
  template <- system.file("templates", "covariate-report.Rmd",
    package = "PharmaStatsR", mustWork = TRUE
  )
  launcher <- system.file("shiny", "covariate_diagnostics_app.R",
    package = "PharmaStatsR", mustWork = TRUE
  )
  template_text <- paste(readLines(template), collapse = "\n")
  launcher_text <- paste(readLines(launcher), collapse = "\n")
  expect_match(template_text, "PharmaStatsR::plot_obs_vs_pred", fixed = TRUE)
  expect_match(launcher_text, "PharmaStatsR:::build_diagnostics_app", fixed = TRUE)
  expect_false(grepl("pharmoCovR::", paste(template_text, launcher_text),
    fixed = TRUE
  ))
})
