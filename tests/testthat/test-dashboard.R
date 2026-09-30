test_that("pharma_dashboard returns path", {
  path <- pharma_dashboard(launch = FALSE)
  expect_true(file.exists(path))
})

test_that("dashboard paths work without optional launch packages", {
  testthat::local_mocked_bindings(
    .pharma_dashboard_available = function(package) FALSE
  )
  expect_true(file.exists(pharma_dashboard(launch = FALSE)))
  expect_true(file.exists(pharma_interim_dashboard(launch = FALSE)))
})

test_that("dashboard launch reports each missing optional package", {
  check_missing <- function(missing) {
    testthat::local_mocked_bindings(
      .pharma_dashboard_available = function(package) package != missing
    )
    for (dashboard in list(pharma_dashboard, pharma_interim_dashboard)) {
      expect_error(dashboard(launch = TRUE),
                   paste0("optional packages: ", missing,
                          "\\. Install with"))
    }
  }
  for (missing in c("rmarkdown", "flexdashboard", "shiny")) {
    check_missing(missing)
  }
})

test_that("dashboard launch passes bundled files to rmarkdown", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("flexdashboard")
  skip_if_not_installed("shiny")

  launched <- character()
  testthat::local_mocked_bindings(
    .pharma_dashboard_run = function(path) {
      launched <<- c(launched, path)
    }
  )
  pharma_dashboard(launch = TRUE)
  pharma_interim_dashboard(launch = TRUE)
  expect_identical(launched, c(
    pharma_dashboard(launch = FALSE),
    pharma_interim_dashboard(launch = FALSE)
  ))
})
