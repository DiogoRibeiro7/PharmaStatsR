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

  ui <- shiny::fluidPage(
    shiny::titlePanel("PharmaStatsR Diagnostics"),
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        shiny::helpText(
          "Upload a CSV with SubjectID, Time and DV.",
          "Fits DV by Time with a random intercept for each subject."
        ),
        shiny::fileInput("csv", "Upload data (.csv)", accept = c(".csv")),
        shiny::numericInput("bins", "Time bins", value = 10, min = 2, step = 1),
        shiny::actionButton("fit", "Fit model"),
        shiny::hr(),
        shiny::verbatimTextOutput("status")
      ),
      shiny::mainPanel(
        shiny::tabsetPanel(
          shiny::tabPanel(
            "Observed vs Predicted",
            shiny::plotOutput("obs_pred")
          ),
          shiny::tabPanel("Residuals", shiny::plotOutput("residuals")),
          shiny::tabPanel(
            "Binned summary",
            shiny::helpText(
              "Observed percentiles and fitted medians;",
              "this plot does not simulate predictive uncertainty."
            ),
            shiny::plotOutput("vpc")
          )
        )
      )
    )
  )

  server <- function(input, output, session) {
    rv_data <- shiny::reactiveVal(data)
    rv_model <- shiny::reactiveVal(model)
    rv_error <- shiny::reactiveVal(NULL)
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

    output$status <- shiny::renderText({
      diagnostics_status_text(rv_data(), rv_model(), rv_error())
    })

    output$obs_pred <- shiny::renderPlot({
      m <- rv_model()
      shiny::req(!is.null(m))
      d <- plot_data()
      plot_obs_vs_pred(m, d)
    })

    output$residuals <- shiny::renderPlot({
      m <- rv_model()
      shiny::req(!is.null(m))
      plot_residuals(m)
    })

    output$vpc <- shiny::renderPlot({
      m <- rv_model()
      shiny::req(!is.null(m))
      d <- plot_data()
      bins <- input$bins
      valid_bins <- is_numeric_vector(bins) && length(bins) == 1L &&
        is.finite(bins) && bins >= 2 && bins == floor(bins)
      shiny::validate(shiny::need(
        valid_bins, "Choose a whole number of time bins (at least 2)."
      ))
      plot_vpc(m, d, bins = bins)
    })
  }

  shiny::shinyApp(ui = ui, server = server)
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
