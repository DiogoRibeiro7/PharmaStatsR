#' Screen linear and generalized linear model diagnostics
#'
#' Report residuals, standardized residuals, Cook's distances, leverage,
#' and a logical flag for observations exceeding either screening cutoff.
#'
#' @param model A fitted univariate `lm` or `glm` object.
#' @param threshold One finite positive cutoff for the absolute standardized
#'   residual. Defaults to 3.
#' @param cook_cutoff Optional finite positive Cook's-distance cutoff.
#'   If `NULL`, use `4 / stats::nobs(model)`; `nobs()` counts observations
#'   used in the fit, rather than rows padded by `na.exclude`.
#'
#' @return A data frame with `residual`, `std_resid`, `cook_d`,
#'   `leverage`, and `flag`. A flag is `TRUE` when either cutoff is
#'   exceeded. Omitted observations restored by `na.exclude` have
#'   unavailable measures and an `NA` flag.
#' @details
#' For `glm`, default raw residuals are deviance residuals and default
#' standardized residuals are Pearson residuals, as defined by the
#' corresponding `stats` methods. Cook's distances and leverage come from
#' those same fitted-model methods. Thresholds are descriptive screening
#' heuristics, not tests or automatic rules for excluding observations.
#' @export
#'
#' @examples
#' fit <- lm(response ~ treatment + dose, data = pharma_sample)
#' diagnostics <- pharma_model_diagnostics(fit)
#' head(diagnostics)
pharma_model_diagnostics <- function(model, threshold = 3,
                                     cook_cutoff = NULL) {
  if (!inherits(model, c("lm", "glm")) || inherits(model, "mlm")) {
    stop("model must be a univariate 'lm' or 'glm' object", call. = FALSE)
  }
  positive_scalar <- function(x) {
    is.numeric(x) && length(x) == 1L && is.finite(x) && x > 0
  }
  if (!positive_scalar(threshold)) {
    stop("threshold must be one finite positive number", call. = FALSE)
  }
  if (!is.null(cook_cutoff) && !positive_scalar(cook_cutoff)) {
    stop("cook_cutoff must be NULL or one finite positive number",
         call. = FALSE)
  }
  if (is.null(cook_cutoff)) {
    cook_cutoff <- 4 / stats::nobs(model)
  }

  residual <- stats::residuals(model)
  std_resid <- stats::rstandard(model)
  cook_d <- stats::cooks.distance(model)
  leverage <- stats::hatvalues(model)
  lengths <- c(length(residual), length(std_resid),
               length(cook_d), length(leverage))
  if (any(lengths != lengths[[1L]])) {
    stop("model diagnostic measures have incompatible row counts",
         call. = FALSE)
  }

  # Keep NA flags for rows omitted and restored by na.exclude.
  flag <- abs(std_resid) > threshold | cook_d > cook_cutoff
  data.frame(
    residual = residual,
    std_resid = std_resid,
    cook_d = cook_d,
    leverage = leverage,
    flag = flag
  )
}
