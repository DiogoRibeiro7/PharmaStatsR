validate_nlmixr_inputs <- function(data, response, id, covariates) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame")
  }
  needed <- c(response, id, covariates)
  if (!all(needed %in% names(data))) {
    missing <- setdiff(needed, names(data))
    stop(sprintf("Variables not found: %s", paste(missing, collapse = ", ")))
  }
  if (!"Time" %in% names(data) && !"TIME" %in% names(data)) {
    stop("`data` must contain a time column named 'Time' or 'TIME'")
  }
  invisible(TRUE)
}

prepare_nlmixr_data <- function(data, response, id, covariates) {
  fit_data <- data
  fit_data$ID <- fit_data[[id]]
  fit_data$DV <- fit_data[[response]]
  if ("Time" %in% names(fit_data)) {
    fit_data$TIME <- fit_data$Time
  }

  if (length(covariates) > 0) {
    warning(
      "`covariates` are currently not incorporated by the internal example ",
      "nlmixr2 model and will be ignored"
    )
  }
  fit_data
}

#' Fit mixed-effects model using nlmixr2
#'
#' Provides a wrapper around `nlmixr2est` to fit an example one-compartment
#' pharmacometric model using SAEM. Dose records must be supplied in the input
#' data, using the event and amount columns expected by `nlmixr2est`.
#'
#' @param data A `data.frame` containing response, subject ID, time, dosing
#'   events, and any requested covariate columns.
#' @param response Name of the response variable.
#' @param id Name of the subject identifier column.
#' @param covariates Character vector of covariate column names. Currently
#'   validated for presence but not used by the internal example model.
#'
#' @return An object of class `nlmixr2FitData` from the SAEM fit.
#' @details The example performs a full stochastic approximation
#'   expectation-maximization (SAEM) fit and can take more than five seconds.
#'   Run it explicitly with
#'   `example("fit_nlmixr_model", package = "PharmaStatsR", run.donttest = TRUE)`.
#' @examples
#' \donttest{
#' # A full SAEM fit is a lengthy example; estimation defaults are unchanged.
#' if (requireNamespace("nlmixr2est", quietly = TRUE) &&
#'   requireNamespace("nlmixr2data", quietly = TRUE)) {
#'   fit <- fit_nlmixr_model(nlmixr2data::theo_sd, "DV", "ID", character(0))
#'   head(fit$PRED)
#' }
#' }
#' @export
fit_nlmixr_model <- function(data, response, id, covariates) {
  # Basic input validation.
  validate_nlmixr_inputs(data, response, id, covariates)

  # Ensure the estimation backend is available.
  if (!requireNamespace("nlmixr2est", quietly = TRUE)) {
    stop("Package 'nlmixr2est' is required for this function")
  }

  # nlmixr interprets this DSL; its bindings are not ordinary R assignments.
  # nolint start: object_usage_linter, object_name_linter.
  model <- function() {
    ini({
      tka <- 0
      tcl <- 0
      tv <- 1
      eta.ka ~ 1
      eta.cl ~ 1
      add.sd <- 1
    })
    model({
      ka <- exp(tka + eta.ka)
      cl <- exp(tcl + eta.cl)
      v <- exp(tv)
      linCmt() ~ add(add.sd)
    })
  }
  # nolint end: object_usage_linter, object_name_linter.

  # Standardize required nlmixr2 columns for the example model.
  fit_data <- prepare_nlmixr_data(data, response, id, covariates)

  # Fit the model.
  nlmixr2est::nlmixr2(
    model,
    data = fit_data,
    est = "saem",
    control = nlmixr2est::saemControl(print = 0)
  )
}
