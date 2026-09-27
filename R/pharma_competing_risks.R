#' Fine–Gray competing-risks regression
#'
#' Fit a proportional subdistribution hazards model for one event type via
#' [cmprsk::crr()]. The response uses the familiar `Surv(time, status)`
#' formula shape, but the original numeric event codes are passed directly
#' to `crr()` without constructing a survival response.
#'
#' @param formula A two-sided formula with an unnamed
#'   `survival::Surv(time, status)` response and at least one predictor.
#'   `time` and `status` must evaluate to finite numeric vectors.
#' @param data A data frame containing all response and predictor variables.
#'   Missing values in variables used by the model are rejected.
#' @param failcode Finite whole-number status code for the event of interest.
#' @param cencode Finite whole-number status code for censoring, distinct from
#'   `failcode`. Other status codes denote competing events.
#' @param ... Additional arguments passed to [cmprsk::crr()].
#'
#' @return A `crr` object; coefficients are log subdistribution hazard ratios.
#' @details
#' The function constructs a model matrix for the predictors and removes an
#' intercept only when one is present. It requires complete model variables
#' so response times, statuses, and model-matrix rows stay aligned. It does
#' not support `Surv(start, stop, status)` or factor status codes.
#' @references
#' Fine JP, Gray RJ (1999). A proportional hazards model for the
#' subdistribution of a competing risk. Journal of the American Statistical
#' Association 94:496–509. doi:10.1080/01621459.1999.10474144
#' @export
#'
#' @examples
#' if (requireNamespace("cmprsk", quietly = TRUE)) {
#'   df <- data.frame(
#'     time = seq_len(90) / 10,
#'     status = rep(0:2, 30),
#'     treatment = rep(c(0, 1), 45)
#'   )
#'   pharma_competing_risks(survival::Surv(time, status) ~ treatment, df)
#' }
pharma_competing_risks <- function(formula, data, failcode = 1, cencode = 0, ...) {
  validate_inputs(data, formula)
  if (!requireNamespace("cmprsk", quietly = TRUE)) {
    stop("Package 'cmprsk' is required for pharma_competing_risks()",
         call. = FALSE)
  }

  response <- formula[[2L]]
  if (length(formula) != 3L || !is.call(response) ||
      length(response) != 3L ||
      !(identical(response[[1L]], as.name("Surv")) ||
        identical(response[[1L]], quote(survival::Surv))) ||
      any(nzchar(names(response)[-1L]))) {
    stop("formula must use an unnamed Surv(time, status) response",
         call. = FALSE)
  }
  valid_code <- function(x) {
    is.numeric(x) && length(x) == 1L && is.finite(x) && x %% 1 == 0
  }
  if (!valid_code(failcode) || !valid_code(cencode) ||
      failcode == cencode) {
    stop("failcode and cencode must be distinct finite whole numbers",
         call. = FALSE)
  }

  # Read the raw cause codes: Surv() would recode 0/1/2 as a binary event.
  time <- eval(response[[2L]], envir = data, enclos = environment(formula))
  status <- eval(response[[3L]], envir = data, enclos = environment(formula))
  if (!is.numeric(time) || length(time) != nrow(data) ||
      any(!is.finite(time))) {
    stop("time must be a finite numeric vector with one value per row",
         call. = FALSE)
  }
  if (!is.numeric(status) || length(status) != nrow(data) ||
      any(!is.finite(status)) || any(status %% 1 != 0)) {
    stop("status must be a finite numeric vector of whole-number event codes",
         call. = FALSE)
  }
  if (!any(status == failcode)) {
    stop("failcode must occur in status", call. = FALSE)
  }

  predictors <- stats::delete.response(stats::terms(formula))
  model_data <- stats::model.frame(
    predictors, data = data, na.action = stats::na.fail
  )
  covariates <- stats::model.matrix(predictors, model_data)
  if (attr(predictors, "intercept") == 1L) {
    covariates <- covariates[, colnames(covariates) != "(Intercept)",
                             drop = FALSE]
  }
  if (ncol(covariates) == 0L || any(!is.finite(covariates))) {
    stop("formula must produce at least one finite predictor",
         call. = FALSE)
  }
  cmprsk::crr(
    ftime = time, fstatus = status, cov1 = covariates,
    failcode = failcode, cencode = cencode, ...
  )
}
