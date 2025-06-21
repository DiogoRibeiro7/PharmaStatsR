#' Model diagnostics and QC
#'
#' Compute residual diagnostics and influence measures for a fitted model.
#'
#' @param model An object of class `lm` or `glm`.
#' @param threshold Numeric. Standardized residual cutoff for flagging observations.
#'
#' @return A data frame with residuals, standardized residuals, Cook's distance,
#'   leverage, and a logical flag for potential outliers.
#' @export
#'
#' @examples
#' fit <- lm(response ~ treatment + dose, data = pharma_sample)
#' diag <- pharma_model_diagnostics(fit)
#' head(diag)
pharma_model_diagnostics <- function(model, threshold = 3) {
  if (!inherits(model, c("lm", "glm"))) {
    stop("model must be of class 'lm' or 'glm'")
  }

  # Compute diagnostic measures
  res <- stats::residuals(model)
  std_res <- stats::rstandard(model)
  cook <- stats::cooks.distance(model)
  lev <- stats::hatvalues(model)

  # Flag observations with large residuals or influence
  flags <- abs(std_res) > threshold | cook > 4 / length(res)

  data.frame(
    residual = res,
    std_resid = std_res,
    cook_d = cook,
    leverage = lev,
    flag = flags
  )
}
