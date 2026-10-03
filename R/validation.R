#' Validate common inputs
#'
#' Centralizes checks for data frames, formulas, and required columns
#' used across the package.
#'
#' @param data **data.frame** to validate.
#' @param formula Optional **formula** to verify against `data`.
#' @param required_cols Optional **character** vector of required column names.
#'
#' @return Invisible `TRUE` if all checks pass.
#' @details Checks the data frame and the presence of named variables only.
#'   It does not check missing values, column types, or the study design.
#' @keywords internal
validate_inputs <- function(data, formula = NULL, required_cols = NULL) {
  if (!is.data.frame(data)) {
    stop("'data' must be a data frame")
  }

  if (!is.null(formula)) {
    if (!inherits(formula, "formula")) {
      stop("'formula' must be a valid formula")
    }
    vars <- all.vars(formula)
    missing <- setdiff(vars, names(data))
    if (length(missing) > 0) {
      stop(
        "Formula uses variables not in data: ",
        paste(missing, collapse = ", ")
      )
    }
  }

  if (!is.null(required_cols)) {
    missing <- setdiff(required_cols, names(data))
    if (length(missing) > 0) {
      stop(
        "Missing required columns: ",
        paste(missing, collapse = ", ")
      )
    }
  }

  invisible(TRUE)
}
