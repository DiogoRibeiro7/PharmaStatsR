#' Predict from a saved weight-allometric oral model
#'
#' Evaluates the fitted structural model from [fit_nlmixr_allometric()] at zero
#' subject effects, using the original column names. These typical-subject
#' population predictions are not marginal means integrated over random effects.
#' No fitted subject effects, residual noise, or parameter uncertainty are added.
#' This is an experimental point-prediction API.
#'
#' @param object An intact native `nlmixr2FitData` result from
#'   [fit_nlmixr_allometric()], including an RDS-restored result. The stored model,
#'   fitted parameters, reference weight, and original-name mapping are required.
#'   Older fits without starting-value metadata are supported.
#' @param newdata Data frame with the original subject, time, and weight columns,
#'   plus uppercase `EVID` and `AMT`. Supply the complete explicit oral dose
#'   history relevant to each subject's predictions in every call. Training
#'   doses are never borrowed. The response column is unnecessary and ignored
#'   if present. Event, type, weight, and unit rules are those of
#'   [fit_nlmixr_allometric()], except that one subject, one observation,
#'   dose-only schedules, and zero rows are allowed. Every nonempty subject
#'   schedule must include a dose. Unsupported event modifiers are rejected.
#'
#' @details The saved reference weight and fitted parameters are reused;
#'   nothing is estimated from `newdata`. Subject IDs define independent dosing
#'   histories, whether or not those IDs occurred during fitting. Events may be
#'   interleaved or unsorted, and duplicate observation times are retained.
#'   Weight must be finite, positive, and constant within each subject on all
#'   dose and observation rows. A response, even a missing or nonnumeric one,
#'   has no effect on prediction. Other unselected columns are ignored, except
#'   for unsupported event modifiers.
#'
#'   The optional `nlmixr2est` backend is loaded for native method registration,
#'   including after restoration in a new R session. Its solver evaluates the
#'   stored model with subject effects and residual simulation disabled. Rows
#'   are mapped back using an internal record identifier; incomplete or
#'   nonfinite backend results raise an error. No simulation or intervals are
#'   provided, and predictions do not establish model adequacy.
#'
#' @return A numeric vector named by `rownames(newdata)`, in input order, with
#'   one entry per row. Observation rows contain concentrations; dose rows
#'   contain `NA_real_`. Empty input with the required schema returns a named
#'   zero-length numeric vector. Input data are not modified.
#' @examples
#' \dontrun{
#' fit <- fit_nlmixr_allometric(nlmixr2data::theo_sd,
#'   weight = "WT",
#'   control = list(seed = 99)
#' )
#' schedule <- data.frame(
#'   ID = 1, TIME = c(0, 0.5, 1, 2, 4), WT = 70,
#'   EVID = c(1, 0, 0, 0, 0), AMT = c(100, 0, 0, 0, 0)
#' )
#' predict_nlmixr_allometric(fit, schedule)
#' saved <- tempfile(fileext = ".rds")
#' saveRDS(fit, saved)
#' predict_nlmixr_allometric(readRDS(saved), schedule)
#' }
#' @seealso [fit_nlmixr_allometric()], [nlmixr2est::rxSolve()]
#' @export
predict_nlmixr_allometric <- function(object, newdata) {
  if (!requireNamespace("nlmixr2est", quietly = TRUE)) {
    stop("Package 'nlmixr2est' is required for predict_nlmixr_allometric()")
  }
  saved <- allometric_prediction_components(object)
  events <- allometric_prediction_events(saved, newdata)
  values <- stats::setNames(rep(NA_real_, nrow(events)), rownames(newdata))
  observations <- which(events$EVID == 0L)
  if (!length(observations)) {
    return(values)
  }
  # The selected columns have already been mapped, so this name cannot
  # overwrite a user-selected column, even if its original name is PSR_ROW.
  events$PSR_ROW <- seq_len(nrow(events))
  solved <- nlmixr2est::rxSolve(saved$ui,
    params = saved$theta, events = events,
    omega = NA, sigma = NA, returnType = "data.frame",
    keep = "PSR_ROW", warnIdSort = FALSE, idFactor = FALSE
  )
  if (!is.data.frame(solved) || !all(c("PSR_ROW", "pred") %in% names(solved)) ||
    !is_numeric_vector(solved$PSR_ROW) || anyNA(solved$PSR_ROW) ||
    anyDuplicated(solved$PSR_ROW) || length(solved$PSR_ROW) != length(observations) ||
    !setequal(solved$PSR_ROW, observations) || !is_numeric_vector(solved$pred) ||
    any(!is.finite(solved$pred))) {
    stop("Allometric predictions must contain one finite value per observation row")
  }
  values[solved$PSR_ROW] <- solved$pred
  values
}

allometric_prediction_components <- function(object) {
  invalid <- function() stop("Invalid allometric fit; use an intact result from fit_nlmixr_allometric()")
  if (!inherits(object, "nlmixr2FitData") || !is.data.frame(object)) invalid()
  metadata <- attr(object, "allometry", exact = TRUE)
  if (!is.list(metadata)) invalid()
  reference <- metadata$reference_weight
  mapping <- metadata$column_map
  if (!is_numeric_vector(reference) || length(reference) != 1L ||
    !is.finite(reference) || reference <= 0 ||
    !identical(metadata$exponents, c(cl = 0.75, v = 1)) ||
    !is.data.frame(mapping) || !valid_encoding_names(names(mapping)) ||
    !all(c("role", "original", "model") %in% names(mapping)) ||
    !identical(mapping$role, c("response", "id", "time", "weight")) ||
    !identical(mapping$model, c("DV", "ID", "TIME", "WT")) ||
    !valid_encoding_names(mapping$original) ||
    any(mapping$original %in% c("EVID", "AMT", "CMT"))) {
    invalid()
  }
  # Read native fields only after the backend has registered its methods.
  ui <- object$ui
  theta <- object$theta
  if (!inherits(ui, "rxUi") || !is_numeric_vector(theta) ||
    !identical(names(theta), c("tka", "tcl", "tv", "add.sd")) ||
    any(!is.finite(theta)) || theta[["add.sd"]] < 0) {
    invalid()
  }
  natural <- exp(theta[c("tka", "tcl", "tv")])
  if (any(!is.finite(natural) | natural <= 0)) invalid()
  # Compare structure, including the saved reference, but not initialization:
  # fitted estimates may differ from both the UI starts and metadata$initial.
  expected <- as.list(body(allometric_nlmixr_model(reference))[[3L]][[2L]])[-1L]
  if (!isTRUE(all.equal(ui$lstExpr, expected)) ||
    !identical(ui$covariates, "WT")) {
    invalid()
  }
  list(metadata = metadata, ui = ui, theta = theta)
}

allometric_prediction_events <- function(saved, newdata) {
  columns <- stats::setNames(
    saved$metadata$column_map$original,
    saved$metadata$column_map$role
  )
  prepare_allometric_data(newdata,
    weight = columns[["weight"]], reference_weight = saved$metadata$reference_weight,
    response = columns[["response"]], id = columns[["id"]], time = columns[["time"]],
    prediction = TRUE
  )
}
