#' Internal utility functions
#'
#' Helper functions used across the package.
#'
#' @param data **data.frame** to validate.
#' @param required_columns **character** vector of required column names.
#' @return Invisible `TRUE` when all required columns are present.
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
#' @param x **numeric** vector to validate.
#' @param name **character** string used in error messages.
#' @return Invisible `TRUE` when validation succeeds.
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
#' @param x **numeric** scalar to validate.
#' @param name **character** string used in error messages.
#' @param lower **numeric** lower bound (exclusive).
#' @param upper **numeric** upper bound (exclusive).
#' @return Invisible `TRUE` when validation succeeds.
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
#' @param level **character** log level for the message.
#' @param msg **character** string to output.
#' @return Invisible `NULL`.
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

#' Display progress for long-running operations
#'
#' Creates a simple progress reporter that outputs status messages to the
#' console when running interactively.
#'
#' @param max_value **integer** total number of steps.
#' @param msg **character** base message to display with progress updates.
#' @return A list with `update` and `finish` functions.
#' @keywords internal
pharma_progress <- function(max_value, msg = "Progress") {
  if (!interactive()) {
    return(NULL)
  }
  env <- new.env(parent = emptyenv())
  env$current <- 0
  env$max <- max_value
  env$start <- Sys.time()
  list(
    update = function(value = NULL, message = NULL) {
      if (!is.null(value)) {
        env$current <- value
      } else {
        env$current <- env$current + 1
      }
      elapsed <- difftime(Sys.time(), env$start, units = "secs")
      pct <- env$current / env$max * 100
      base_msg <- if (!is.null(message)) message else msg
      cat(sprintf("\r%s: %.1f%% (%d/%d) - %.1fs elapsed", base_msg, pct, env$current, env$max, elapsed))
      if (env$current >= env$max) {
        cat("\n")
      }
      utils::flush.console()
    },
    finish = function(message = "Complete") {
      elapsed <- difftime(Sys.time(), env$start, units = "secs")
      cat(sprintf("\r%s: 100%% - %.1fs elapsed\n", message, elapsed))
      utils::flush.console()
    }
  )
}
