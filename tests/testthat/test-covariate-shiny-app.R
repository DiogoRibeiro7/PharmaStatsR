local_edition(3)

library(testthat)

test_that("build_diagnostics_app returns a shiny app object", {
  skip_if_not_installed("shiny")
  app <- PharmaStatsR:::build_diagnostics_app()
  expect_s3_class(app, "shiny.appobj")
})

test_that("build_diagnostics_app handles preloaded inputs", {
  skip_if_not_installed("shiny")
  d <- data.frame(
    SubjectID = rep(1:4, each = 2),
    Time = rep(0:1, times = 4),
    DV = rnorm(8)
  )
  m <- fit_covariate_model(d, "DV", "SubjectID", "Time")
  app <- PharmaStatsR:::build_diagnostics_app(model = m, data = d)
  expect_s3_class(app, "shiny.appobj")
})

test_that("run_diagnostics_app returns app object while runApp is mocked", {
  skip_if_not_installed("shiny")
  local_mocked_bindings(
    runApp = function(app, ...) invisible(NULL),
    .package = "shiny"
  )
  app <- run_diagnostics_app()
  expect_s3_class(app, "shiny.appobj")
})

test_that("build_diagnostics_app errors when shiny is unavailable", {
  local_mocked_bindings(
    requireNamespace = function(pkg, quietly = TRUE) {
      if (identical(pkg, "shiny")) {
        return(FALSE)
      }
      base::requireNamespace(pkg, quietly = quietly)
    },
    .package = "base"
  )
  expect_error(
    PharmaStatsR:::build_diagnostics_app(),
    "Package 'shiny' is required"
  )
})
