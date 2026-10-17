local_edition(3)

make_diagnostics_data <- function() {
  set.seed(42)
  d <- data.frame(SubjectID = rep(1:8, each = 3), Time = rep(0:2, 8))
  d$DV <- 3 + 0.5 * d$Time + rep(rnorm(8), each = 3) + rnorm(24, sd = 0.2)
  d[["body mass"]] <- 60 + d$SubjectID
  d
}

make_diagnostics_upload <- function(data) {
  path <- tempfile(fileext = ".csv")
  utils::write.csv(data, path, row.names = FALSE)
  data.frame(
    name = basename(path), size = file.info(path)$size,
    type = "text/csv", datapath = path
  )
}

test_that("CSV uploads can be fitted and all diagnostics render", {
  skip_if_not_installed("shiny")
  d <- make_diagnostics_data()
  upload <- make_diagnostics_upload(d)
  replacement <- d
  replacement$DV <- replacement$DV + 5
  next_upload <- make_diagnostics_upload(replacement)
  on.exit(unlink(c(upload$datapath, next_upload$datapath)), add = TRUE)
  app <- PharmaStatsR:::build_diagnostics_app()
  shiny::testServer(app, {
    session$flushReact()
    expect_identical(output$status, "No data loaded.")
    session$setInputs(fit = 1)
    expect_match(output$status, "Load a CSV")
    session$setInputs(csv = upload, bins = 2)
    expect_match(output$status, "Data loaded")
    expect_equal(rv_data(), d)
    expect_identical(output$source_name, paste("Data source:", upload$name))
    expect_null(rv_model())
    session$setInputs(fit = 2)
    expect_identical(output$status, "Model ready.")
    expect_s3_class(rv_model(), "lme")
    expect_match(output$obs_pred$src, "^data:image/png;base64,")
    expect_match(output$residuals$src, "^data:image/png;base64,")
    expect_match(output$vpc$src, "^data:image/png;base64,")

    previous_model <- rv_model()
    session$setInputs(bins = 3)
    expect_identical(rv_model(), previous_model)
    expect_match(output$vpc$src, "^data:image/png;base64,")
    session$setInputs(csv = next_upload)
    expect_null(rv_model())
    expect_equal(rv_data(), replacement)
    expect_match(output$status, "Data loaded")
    expect_error(output$obs_pred, class = "shiny.silent.error")
    expect_error(output$residuals, class = "shiny.silent.error")
    expect_error(output$vpc, class = "shiny.silent.error")
    session$setInputs(fit = 3)
    expect_identical(output$status, "Model ready.")
    expect_equal(rv_model()$data$DV, replacement$DV)
  })
})

test_that("invalid CSV uploads clear old data and models and allow recovery", {
  skip_if_not_installed("shiny")
  d <- make_diagnostics_data()
  model <- fit_covariate_model(d, "DV", "SubjectID", "Time")
  valid <- make_diagnostics_upload(d)
  missing <- make_diagnostics_upload(d[c("SubjectID", "Time")])
  duplicate_data <- d
  names(duplicate_data)[4] <- "DV"
  duplicate <- make_diagnostics_upload(duplicate_data)
  empty <- make_diagnostics_upload(d[FALSE, ])
  unreadable <- make_diagnostics_upload(d)
  writeLines(character(), unreadable$datapath)
  uploads <- list(missing, duplicate, empty, unreadable)
  paths <- c(valid$datapath, vapply(uploads, function(x) x$datapath, ""))
  on.exit(unlink(paths), add = TRUE)
  expected <- c(
    "Missing required.*DV", "unique column names", "at least one row",
    "no lines available"
  )
  app <- PharmaStatsR:::build_diagnostics_app(model, d)
  shiny::testServer(app, {
    session$setInputs(bins = 2)
    expect_identical(output$status, "Model ready.")
    for (i in seq_along(uploads)) {
      session$setInputs(csv = uploads[[i]])
      expect_match(output$status, "^Upload failed:")
      expect_match(output$status, expected[i])
      expect_null(rv_data())
      expect_identical(output$source_name, "")
      expect_null(rv_model())
      error_status <- output$status
      session$setInputs(fit = i)
      expect_identical(output$status, error_status)
    }
    session$setInputs(csv = valid)
    expect_match(output$status, "Data loaded")
    session$setInputs(fit = 10)
    expect_identical(output$status, "Model ready.")
    expect_s3_class(rv_model(), "lme")
  })
})

test_that("incomplete observations use the same cohort for fitting and plots", {
  skip_if_not_installed("shiny")
  d <- make_diagnostics_data()
  d$Time[1] <- NA
  d$DV[2] <- NA
  d$SubjectID[3] <- NA
  # Missing unused covariates must not exclude additional observations.
  d[["body mass"]][4] <- NA
  upload <- make_diagnostics_upload(d)
  on.exit(unlink(upload$datapath), add = TRUE)
  app <- PharmaStatsR:::build_diagnostics_app()
  shiny::testServer(app, {
    session$setInputs(csv = upload, bins = 2)
    session$setInputs(fit = 1)
    expect_identical(output$status, "Model ready.")
    expect_equal(rv_data(), d)
    expect_equal(nrow(rv_model()$data), nrow(d) - 3L)
    expect_equal(rv_model()$data$DV, d$DV[-(1:3)])
    expect_match(output$obs_pred$src, "^data:image/png;base64,")
    expect_match(output$residuals$src, "^data:image/png;base64,")
    expect_match(output$vpc$src, "^data:image/png;base64,")
  })
})

test_that("model validation failures explain the problem and allow recovery", {
  skip_if_not_installed("shiny")
  d <- make_diagnostics_data()
  bad <- d
  bad$DV <- 1
  upload <- make_diagnostics_upload(d)
  on.exit(unlink(upload$datapath), add = TRUE)
  app <- PharmaStatsR:::build_diagnostics_app(data = bad)
  shiny::testServer(app, {
    session$setInputs(fit = 1, bins = 2)
    expect_match(output$status, "^Fit failed:.*response.*must vary")
    expect_null(rv_model())
    expect_identical(rv_data(), bad)
    session$setInputs(csv = upload)
    expect_match(output$status, "Data loaded")
    session$setInputs(fit = 2)
    expect_identical(output$status, "Model ready.")
    expect_match(output$obs_pred$src, "^data:image/png;base64,")
  })
})

test_that("backend errors clear the previous model and expose the reason", {
  skip_if_not_installed("shiny")
  d <- make_diagnostics_data()
  model <- fit_covariate_model(d, "DV", "SubjectID", "Time")
  local_mocked_bindings(
    fit_covariate_model = function(...) stop("optimizer did not converge")
  )
  app <- PharmaStatsR:::build_diagnostics_app(model, d)
  shiny::testServer(app, {
    session$setInputs(bins = 2)
    expect_identical(output$status, "Model ready.")
    session$setInputs(fit = 1)
    expect_identical(output$status, "Fit failed: optimizer did not converge")
    expect_null(rv_model())
    expect_identical(rv_data(), d)
  })
})

test_that("invalid bins show a message and recover without losing a fit", {
  skip_if_not_installed("shiny")
  d <- make_diagnostics_data()
  model <- fit_covariate_model(d, "DV", "SubjectID", "Time")
  app <- PharmaStatsR:::build_diagnostics_app(model, d)
  shiny::testServer(app, {
    for (bins in list(NULL, NA_real_, Inf, "two", 1, 2.5)) {
      session$setInputs(bins = bins)
      expect_error(
        output$vpc, "whole number of time bins",
        class = "validation"
      )
      expect_identical(rv_model(), model)
    }
    session$setInputs(bins = 2)
    expect_match(output$vpc$src, "^data:image/png;base64,")
    expect_identical(output$status, "Model ready.")
  })
})

test_that("cancelled uploads preserve data and invalid preload fails early", {
  skip_if_not_installed("shiny")
  d <- make_diagnostics_data()
  app <- PharmaStatsR:::build_diagnostics_app(data = d)
  shiny::testServer(app, {
    session$setInputs(csv = list(name = "cancelled.csv"))
    expect_identical(rv_data(), d)
    expect_identical(output$source_name, "Data source: preloaded data")
    expect_match(output$status, "Data loaded")
  })
  expect_error(
    PharmaStatsR:::build_diagnostics_app(data = data.frame(Time = 0, DV = 1)),
    "Missing required columns: SubjectID"
  )
})


test_that("numerical tables retain analysis rows and plotted values", {
  skip_if_not_installed("shiny")
  d <- make_diagnostics_data()
  d$DV[2] <- NA_real_
  rownames(d) <- paste0("row-", seq_len(nrow(d)))
  app <- PharmaStatsR:::build_diagnostics_app(data = d)
  # Parse ordinary table cells without adding a package dependency.
  cells <- function(output) {
    html <- as.character(output$html)
    matches <- regmatches(html, gregexpr("<td>[^<]*</td>", html))[[1]]
    sub("</td>$", "", sub("^<td>", "", matches))
  }
  shiny::testServer(app, {
    session$setInputs(fit = 1, bins = 2)
    observed <- matrix(cells(output$obs_pred_data), ncol = 4, byrow = TRUE)
    expect_identical(observed[, 1], rownames(d)[-2])
    expect_equal(as.numeric(observed[, 2]), d$Time[-2])
    plotted <- ggplot2::ggplot_build(plot_obs_vs_pred(rv_model(), plot_data()))$data[[1]]
    expect_equal(as.numeric(observed[, 3]), plotted$y, tolerance = 1e-5)
    expect_equal(as.numeric(observed[, 4]), plotted$x, tolerance = 1e-5)

    residual <- matrix(cells(output$residuals_data), ncol = 4, byrow = TRUE)
    expect_identical(residual[, 1], rep(rownames(d)[-2], 2L))
    expect_equal(as.numeric(residual[, 2]), rep(d$Time[-2], 2L))
    expect_equal(
      as.numeric(residual[, 3]),
      c(
        unname(residuals(rv_model(), type = "response")),
        unname(residuals(rv_model(), type = "normalized"))
      ),
      tolerance = 1e-5
    )
    expect_identical(residual[, 4], rep(c("Raw", "Normalized"), each = 23))

    binned <- matrix(as.numeric(cells(output$vpc_data)), ncol = 5, byrow = TRUE)
    expect_equal(unname(binned), unname(as.matrix(plot_vpc(rv_model(), plot_data(), bins = 2)$data)), tolerance = 1e-5)
    expect_match(output$obs_pred$alt, "subject-specific")
    expect_match(output$residuals$alt, "Raw and normalized")
    expect_match(output$vpc$alt, "does not simulate predictive")
    session$setInputs(bins = 1)
    expect_match(output$bins_feedback, "whole number")
    expect_error(output$vpc_data, "whole number", class = "validation")
    session$setInputs(bins = 3)
    expect_identical(output$bins_feedback, "")
    expect_match(output$vpc_data$html, "<table")

    # Replacement data invalidate all three text alternatives along with plots.
    upload <- make_diagnostics_upload(make_diagnostics_data())
    on.exit(unlink(upload$datapath), add = TRUE)
    session$setInputs(csv = upload)
    expect_error(output$obs_pred_data, class = "shiny.silent.error")
    expect_error(output$residuals_data, class = "shiny.silent.error")
    expect_error(output$vpc_data, class = "shiny.silent.error")
  })
})

test_that("table captions, headers and row names are escaped as text", {
  skip_if_not_installed("shiny")
  values <- data.frame(Row = "<script>alert(1)</script>", value = 1.23456789)
  names(values)[2] <- "A & B"
  html <- as.character(PharmaStatsR:::diagnostics_data_table(values, "<Values>"))
  expect_match(html, "<caption>&lt;Values&gt;</caption>", fixed = TRUE)
  expect_match(html, '<th scope="col">A &amp; B</th>', fixed = TRUE)
  expect_match(html, "&lt;script&gt;alert(1)&lt;/script&gt;", fixed = TRUE)
  expect_false(grepl("<script>", html, fixed = TRUE))
  expect_match(html, "<td>1.23457</td>", fixed = TRUE)
})
