#' Check the presence of required columns
#'
#' This historical function name is kept for existing scripts. It only checks
#' column names and does not determine ICH or other regulatory compliance.
#' For new code, use `pharma_check_columns()`.
#'
#' @param data A data frame to check.
#' @param required A nonempty character vector of unique, nonblank column
#'   names. Defaults to `c("subject", "treatment", "dose")`.
#'
#' @return `TRUE` if every required column exists; otherwise an error.
#' @export
#'
#' @examples
#' check_ich_columns(pharma_sample)
check_ich_columns <- function(data, required = c("subject", "treatment", "dose")) {
  pharma_check_columns(data, required)
}
