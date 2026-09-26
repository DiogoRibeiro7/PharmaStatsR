#' Report required columns in a dataset
#'
#' Returns a row count and records which column names were checked. A
#' successful report means only that all required columns are present.
#' It does not assess data values or regulatory compliance.
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
#' pharma_column_report(pharma_sample, "Treatment difference")
pharma_column_report <- function(data,
                                 estimand,
                                 required = c(
                                   "subject", "treatment",
                                   "dose", "response"
                                 )) {
  if (!is.character(estimand) ||
      length(estimand) != 1L ||
      is.na(estimand) ||
      !nzchar(trimws(estimand))) {
    stop("`estimand` must be a nonempty character string", call. = FALSE)
  }
  pharma_check_columns(data, required)

  list(
    estimand = estimand,
    n = nrow(data),
    required_columns = required,
    columns_present = TRUE
  )
}
