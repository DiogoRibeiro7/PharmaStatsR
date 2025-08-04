#' Internal utility functions
#'
#' Helper functions used across the package.
#'
#' @keywords internal
check_dataset <- function(data, required_columns) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame; got ", class(data)[1])
  }
  missing <- setdiff(required_columns, colnames(data))
  if (length(missing) > 0) {
    stop(
      "Dataset is missing required column(s): ", paste(missing, collapse = ", "),
      ". Add the missing column(s) or check `required_columns`."
    )
  }
  invisible(TRUE)
}

#' Validate a numeric vector
#'
#' Ensures an argument is a numeric vector with no missing or infinite values.
#'
#' @param x Object to validate.
#' @param name Argument name used in error messages.
#' @keywords internal
check_numeric_vector <- function(x, name) {
  if (!is.numeric(x) || !is.vector(x)) {
    stop("`", name, "` must be a numeric vector")
  }
  if (length(x) == 0) {
    stop("`", name, "` must contain at least one value")
  }
  if (anyNA(x)) {
    stop("`", name, "` cannot contain NA values")
  }
  if (!all(is.finite(x))) {
    stop("`", name, "` must contain only finite values")
  }
  invisible(TRUE)
}

#' Validate a numeric scalar
#'
#' Ensures an argument is a finite numeric scalar within optional bounds.
#'
#' @param x Object to validate.
#' @param name Argument name used in error messages.
#' @param lower Lower bound (exclusive).
#' @param upper Upper bound (exclusive).
#' @keywords internal
check_numeric_scalar <- function(x, name, lower = -Inf, upper = Inf) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x)) {
    stop("`", name, "` must be a finite numeric scalar")
  }
  if (x <= lower || x >= upper) {
    stop("`", name, "` must be in (", lower, ", ", upper, ")")
  }
  invisible(TRUE)
}

#' Log package events
#'
#' Simple logging utility with verbosity controlled by
#' `pharma_config()` via the `log_level` option. Levels in increasing
#' order are "DEBUG", "INFO", "WARN", and "ERROR".
#'
#' @param level Log level for the message.
#' @param msg The message to output.
#' @keywords internal
pharma_log <- function(level = "INFO", msg) {
  levels <- c("DEBUG", "INFO", "WARN", "ERROR")
  current <- getOption("pharma", list(log_level = "INFO"))$log_level
  level <- toupper(level)
  if (!level %in% levels) {
    stop("Unknown log level: ", level)
  }
  if (match(level, levels) >= match(toupper(current), levels)) {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    base::message(sprintf("[%s] %s - %s", level, timestamp, msg))
  }
  invisible(NULL)
}
