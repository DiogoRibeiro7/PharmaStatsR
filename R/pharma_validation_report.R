#' Report required columns in a dataset
#'
#' This historical function name is kept for existing scripts. It returns
#' the same column-presence report as `pharma_column_report()`, not a
#' regulatory validation or an ICH E9(R1) compliance decision. The old
#' `compliant` field has been removed because column presence alone cannot
#' justify that conclusion.
#'
#' @param data A data frame to check.
#' @param estimand A nonempty character string describing the intended estimand.
#'   The description is recorded, not assessed.
#' @param required A nonempty character vector of unique, nonblank column
#'   names. Defaults to `c("subject", "treatment", "dose", "response")`.
#'
#' @return A list with `estimand`, `n`, `required_columns`, and
#'   `columns_present = TRUE`. Missing columns cause an error.
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
  pharma_column_report(data, estimand, required)
}
