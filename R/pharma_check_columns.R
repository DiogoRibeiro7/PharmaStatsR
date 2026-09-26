#' Check the presence of required columns
#'
#' Checks column names in a data frame. It does not examine values, study
#' design, an estimand, or regulatory compliance.
#'
#' @param data A data frame to check.
#' @param required A nonempty character vector of unique, nonblank column names.
#'
#' @return `TRUE` if every required column exists; otherwise an error.
#' @export
#'
#' @examples
#' pharma_check_columns(pharma_sample, c("subject", "treatment"))
pharma_check_columns <- function(data, required) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame", call. = FALSE)
  }
  if (!is.character(required) ||
      length(required) == 0L ||
      anyNA(required) ||
      any(!nzchar(trimws(required))) ||
      anyDuplicated(required) > 0L) {
    stop("`required` must contain unique, nonblank column names", call. = FALSE)
  }

  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop("Missing required columns: ", paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  TRUE
}
