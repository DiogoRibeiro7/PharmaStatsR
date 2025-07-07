#' Generate a regulatory validation report
#'
#' Creates a simple summary verifying that a dataset contains the
#' necessary columns for ICH E9(R1) estimand specification. The function
#' reports basic counts and returns a list describing compliance status.
#'
#' @param data A data frame to validate.
#' @param estimand Character string describing the target estimand.
#' @param required Character vector of columns required for the report.
#'   Defaults to `c("subject", "treatment", "dose", "response")`.
#'
#' @return A list with elements `estimand`, `n` and `compliant`.
#' @export
#'
#' @examples
#' pharma_validation_report(pharma_sample, "Treatment difference")
pharma_validation_report <- function(data,
                                     estimand,
                                     required = c(
                                       "subject", "treatment",
                                       "dose", "response"
                                     )) {
  check_ich_columns(data, required = required)
  list(
    estimand = estimand,
    n = nrow(data),
    compliant = TRUE
  )
}
