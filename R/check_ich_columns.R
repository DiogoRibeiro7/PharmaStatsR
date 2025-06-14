#' Check dataset for basic ICH compliance
#'
#' This helper verifies that a dataset contains key columns commonly required for
#' regulatory submissions under ICH guidelines.
#'
#' @param data A data frame to check.
#' @param required Character vector of required column names.
#'   Defaults to `c("subject", "treatment", "dose")`.
#'
#' @return `TRUE` if all required columns are present; otherwise an error is
#'   thrown listing the missing columns.
#' @export
#'
#' @examples
#' check_ich_columns(pharma_sample)
check_ich_columns <- function(data, required = c("subject", "treatment", "dose")) {
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    stop("Missing required columns: ", paste(missing, collapse = ", "))
  }
  TRUE
}
