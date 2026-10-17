#' Build the diagnostics Shiny app
#'
#' Creates a `shiny::shinyApp` for interactive diagnostics using package
#' plotting helpers.
#'
#' @param model Optional fitted model object.
#' @param data Optional nonempty data frame with unique column names and
#'   `SubjectID`, `Time`, and `DV` columns. Time and DV must be real numeric
#'   vectors without infinite values. Missing observations are allowed.
#'
#' @return A `shiny.appobj` object.
#' @keywords internal
build_diagnostics_app <- function(model = NULL, data = NULL) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required to run the diagnostics app.")
  }

  if (!is.null(data)) {
    validate_diagnostics_data(data)
  }

  diagnostic_panel <- function(title, id, description) {
    shiny::tabPanel(
      title,
      shiny::tags$h3(title),
      shiny::tags$p(description),
      shiny::plotOutput(id),
      shiny::tags$details(
        shiny::tags$summary(paste("View numerical data:", title)),
        shiny::tags$p("Values are displayed to six significant digits."),
        shiny::tags$div(
          class = "diagnostics-table", tabindex = "0", role = "region",
          `aria-label` = paste(title, "data table"),
          shiny::uiOutput(paste0(id, "_data"))
        )
      )
    )
  }
  descriptions <- c(
    obs_pred = paste(
      "Observed responses against subject-specific fitted values.",
      "The diagonal marks equality; numerical data follow the plot."
    ),
    residuals = paste(
      "Raw and normalized residuals against time, in separate panels.",
      "Numerical data follow the plot."
    ),
    vpc = paste(
      "Observed 5th, 50th and 95th percentiles and median fitted values",
      "by time bin. This descriptive summary does not simulate predictive",
      "uncertainty. Numerical data follow the plot."
    )
  )
  ui <- shiny::fluidPage(
    title = "PharmaStatsR Diagnostics", lang = "en",
    shiny::tags$head(shiny::tags$style(shiny::HTML("
      .diagnostics-app :focus-visible { outline: 3px solid #174a7e !important; outline-offset: 3px; }
      .diagnostics-app .help-block, .diagnostics-app caption { color: #444; }
      .diagnostics-app .shiny-output-error-validation { color: #444; }
      .diagnostics-app .progress-bar-danger { background-color: #a12420; }
      .diagnostics-app a { color: #17578c; }
      .diagnostics-app input[type=file] { max-width: 100%; }
      .diagnostics-app summary { display: list-item; cursor: pointer; margin: 1em 0; }
      .diagnostics-table { overflow: auto; max-height: 24rem; margin: 0.5em 0; }
      .diagnostics-table th, .diagnostics-table td { white-space: nowrap; }
      .diagnostics-app #status, .diagnostics-app #source_name { overflow-wrap: anywhere; }
    "))),
    shiny::tags$div(
      class = "diagnostics-app",
      shiny::tags$a(
        href = "#diagnostics", class = "sr-only sr-only-focusable",
        "Skip to diagnostics"
      ),
      shiny::tags$header(shiny::tags$h1("PharmaStatsR Diagnostics")),
      shiny::fluidRow(
        shiny::column(4, shiny::tags$aside(
          class = "well", `aria-labelledby` = "controls-heading",
          shiny::tags$h2(id = "controls-heading", "Data and model"),
          shiny::tags$p(
            id = "upload-help", "Upload a CSV with SubjectID, Time and DV.",
            "Fits DV by Time with a random intercept for each subject."
          ),
          # A visible native file input uses Shiny's file binding and keeps
          # the file chooser keyboard-accessible.
          shiny::tags$div(
            class = "form-group shiny-input-container",
            shiny::tags$label(`for` = "csv", "Upload data (.csv)"),
            shiny::tags$div(
              class = "input-group",
              shiny::tags$input(
                id = "csv", name = "csv", type = "file", accept = ".csv",
                `aria-describedby` = "upload-help"
              )
            ),
            shiny::tags$div(
              id = "csv_progress", class = "progress active shiny-file-input-progress",
              role = "status", `aria-label` = "File upload status",
              `aria-live` = "polite", `aria-atomic` = "true",
              shiny::tags$div(class = "progress-bar")
            )
          ),
          shiny::textOutput("source_name"),
          shiny::numericInput("bins", "Time bins", value = 10, min = 2, step = 1),
          shiny::tags$div(
            id = "bins_feedback", class = "shiny-text-output",
            role = "status", `aria-live` = "polite", `aria-atomic` = "true"
          ),
          shiny::actionButton("fit", "Fit model"),
          shiny::tags$h3(id = "status-heading", "Model status"),
          shiny::tags$div(
            id = "status", class = "shiny-text-output",
            role = "status", `aria-live` = "polite", `aria-atomic` = "true",
            `aria-labelledby` = "status-heading"
          )
        )),
        shiny::column(8, shiny::tags$main(
          id = "diagnostics", tabindex = "-1", `aria-labelledby` = "diagnostics-heading",
          shiny::tags$h2(id = "diagnostics-heading", "Diagnostics"),
          shiny::tags$p("Fit a model, then choose a tab or open its numerical data."),
          shiny::tabsetPanel(
            id = "diagnostic_view",
            diagnostic_panel("Observed vs Predicted", "obs_pred", descriptions[["obs_pred"]]),
            diagnostic_panel("Residuals", "residuals", descriptions[["residuals"]]),
            diagnostic_panel("Binned summary", "vpc", descriptions[["vpc"]])
          )
        ))
      )
    )
  )

  server <- function(input, output, session) {
    rv_data <- shiny::reactiveVal(data)
    rv_model <- shiny::reactiveVal(model)
    rv_error <- shiny::reactiveVal(NULL)
    rv_source <- shiny::reactiveVal(if (is.null(data)) NULL else "preloaded data")
    plot_data <- shiny::reactive({
      d <- rv_data()
      shiny::req(!is.null(d))
      complete <- stats::complete.cases(d[c("SubjectID", "Time", "DV")])
      d[complete, , drop = FALSE]
    })

    shiny::observeEvent(input$csv, {
      upload <- input$csv
      if (is.null(upload$datapath)) {
        return()
      }
      # A new upload invalidates previous diagnostics even if reading fails.
      rv_data(NULL)
      rv_source(NULL)
      rv_model(NULL)
      rv_error(NULL)
      tryCatch(
        {
          d <- utils::read.csv(
            upload$datapath,
            check.names = FALSE, stringsAsFactors = FALSE
          )
          validate_diagnostics_data(d)
          rv_data(d)
          rv_source(upload$name)
        },
        error = function(e) {
          rv_error(paste("Upload failed:", conditionMessage(e)))
        }
      )
    })

    shiny::observeEvent(input$fit, {
      d <- rv_data()
      rv_model(NULL)
      if (is.null(d)) {
        if (is.null(rv_error())) {
          rv_error("Load a CSV before fitting a model.")
        }
        return()
      }
      rv_error(NULL)
      tryCatch(
        {
          validate_diagnostics_data(d)
          rv_model(fit_covariate_model(plot_data(), "DV", "SubjectID", "Time"))
        },
        error = function(e) {
          rv_error(paste("Fit failed:", conditionMessage(e)))
        }
      )
    })

    output$source_name <- shiny::renderText({
      source <- rv_source()
      if (is.null(source)) "" else paste("Data source:", source)
    })
    output$status <- shiny::renderText({
      diagnostics_status_text(rv_data(), rv_model(), rv_error())
    })

    observed_values <- shiny::reactive({
      m <- rv_model()
      shiny::req(!is.null(m))
      d <- plot_data()
      data.frame(
        Row = rownames(d), Time = d$Time, Observed = d$DV,
        Predicted = unname(stats::predict(m, d)), check.names = FALSE
      )
    })
    residual_plot <- shiny::reactive({
      m <- rv_model()
      shiny::req(!is.null(m))
      plot_residuals(m)
    })
    bins_valid <- shiny::reactive({
      bins <- input$bins
      is_numeric_vector(bins) && length(bins) == 1L &&
        is.finite(bins) && bins >= 2 && bins == floor(bins)
    })
    bins_message <- "Choose a whole number of time bins (at least 2)."
    output$bins_feedback <- shiny::renderText({
      if (bins_valid()) "" else bins_message
    })
    binned_plot <- shiny::reactive({
      m <- rv_model()
      shiny::req(!is.null(m))
      shiny::validate(shiny::need(bins_valid(), bins_message))
      plot_vpc(m, plot_data(), bins = input$bins)
    })
    output$obs_pred <- shiny::renderPlot(
      {
        m <- rv_model()
        shiny::req(!is.null(m))
        plot_obs_vs_pred(m, plot_data())
      },
      alt = descriptions[["obs_pred"]]
    )
    output$residuals <- shiny::renderPlot(
      {
        residual_plot()
      },
      alt = descriptions[["residuals"]]
    )
    output$vpc <- shiny::renderPlot(
      {
        binned_plot()
      },
      alt = descriptions[["vpc"]]
    )

    output$obs_pred_data <- shiny::renderUI({
      diagnostics_data_table(observed_values(), "Observed and fitted responses")
    })
    output$residuals_data <- shiny::renderUI({
      values <- residual_plot()$data
      values <- data.frame(
        Row = rep(rownames(rv_model()$data), 2L), values, check.names = FALSE
      )
      diagnostics_data_table(values, "Raw and normalized residuals")
    })
    output$vpc_data <- shiny::renderUI({
      values <- binned_plot()$data
      names(values) <- c(
        "Mean time", "Observed 5th percentile", "Observed median",
        "Observed 95th percentile", "Fitted median"
      )
      diagnostics_data_table(values, "Observed and fitted summaries by time bin")
    })
  }

  shiny::shinyApp(ui = ui, server = server)
}

# Render ordinary HTML tables so captions and column headers remain available
# to assistive technology. Tags escape all values, including supplied row names.
diagnostics_data_table <- function(data, caption) {
  formatted <- lapply(data, function(x) {
    if (is.numeric(x)) trimws(formatC(x, format = "g", digits = 6)) else as.character(x)
  })
  shiny::tags$table(
    class = "table table-striped",
    shiny::tags$caption(caption),
    shiny::tags$thead(shiny::tags$tr(lapply(names(data), function(name) {
      shiny::tags$th(scope = "col", name)
    }))),
    shiny::tags$tbody(lapply(seq_len(nrow(data)), function(i) {
      shiny::tags$tr(lapply(formatted, function(column) shiny::tags$td(column[i])))
    }))
  )
}

diagnostics_status_text <- function(data, model, error = NULL) {
  if (!is.null(error)) {
    return(error)
  }
  if (is.null(data)) {
    return("No data loaded.")
  }
  if (is.null(model)) {
    return("Data loaded. Click 'Fit model' to enable diagnostics.")
  }
  "Model ready."
}

validate_diagnostics_data <- function(data) {
  validate_data_frame_names(data)
  needed <- c("SubjectID", "Time", "DV")
  missing <- setdiff(needed, names(data))
  if (length(missing) > 0L) {
    stop(sprintf(
      "Missing required columns: %s", paste(missing, collapse = ", ")
    ))
  }
  if (nrow(data) == 0L) {
    stop("Data must contain at least one row")
  }
  validate_preprocessing_vars(data, c("Time", "DV"))
  validate_model_vectors(data, "SubjectID")
  invisible(TRUE)
}

#' Run interactive diagnostics app
#'
#' Launches a Shiny app for interactive inspection of model diagnostics.
#' CSV uploads require SubjectID, Time, and DV. Upload and fitting errors are
#' shown in the status panel. Every new upload clears the previous model;
#' failed uploads also clear the previous data. Corrected uploads can be fitted
#' without restarting the app. CSV column names are preserved and duplicates
#' are rejected. Preloaded data receive the same structural validation.
#'
#' The Fit model button fits DV by Time with a random subject intercept.
#' Rows missing SubjectID, Time, or DV are excluded from the built-in fit and
#' prediction plots; the original loaded data are retained in the session.
#' The binned summary shows observed percentiles and fitted medians; it is not
#' a simulation-based predictive check. A supplied model should correspond to
#' the supplied data.
#'
#' The app has visible keyboard focus, a skip link, and live status feedback.
#' Each plot has a text description and an expandable numerical table with
#' captions and column headers. Tables display six significant digits; Row
#' identifies the analysis data row name, not a subject identifier. Use Tab to
#' reach controls, Enter or Space to open numerical data, and arrow keys within
#' the diagnostic tabs (with current Shiny). Automated Chromium checks cover
#' the documented workflow, not all browsers or assistive technologies.
#'
#' @param model Optional fitted model object.
#' @param data Optional nonempty data frame with unique column names and
#'   `SubjectID`, `Time`, and `DV` columns. Time and DV must be real numeric
#'   vectors without infinite values. Missing observations are allowed.
#'
#' @return Invisibly returns the app object after launching.
#' @examples
#' \dontrun{
#' run_diagnostics_app()
#' }
#' @export
run_diagnostics_app <- function(model = NULL, data = NULL) {
  app <- build_diagnostics_app(model = model, data = data)
  shiny::runApp(app)
  invisible(app)
}
