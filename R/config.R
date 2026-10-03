#' Manage PharmaStatsR configuration
#'
#' `pharma_config()` gets or sets the process-local `pharma` option.
#' Only `log_level` is currently read by package code; the remaining fields
#' are stored for callers and are not applied by the analysis helpers.
#'
#' @param ... Named options to store. Supported names and defaults are:
#'   - `log_level` (**character**): logging verbosity ("DEBUG", "INFO",
#'     "WARN", "ERROR"; default "INFO").
#'   - `plot_theme`: stored label (default "minimal"); not applied to plots.
#'   - `default_ci`: stored value (default 0.95); not used for intervals.
#'   - `parallel_strategy`: stored label (default "sequential"); does not
#'     select a parallel backend.
#'   - `max_cores`: stored value; the detected default is an integer of at
#'     least one. It does not limit backend workers.
#'   - `cache_dir`: stored path (default `tempdir()`); no cache is created.
#'
#' @return A named list of current configuration values. The no-argument getter
#'   returns it visibly; a setter returns the updated list invisibly.
#' @details Only `log_level` is normalized and validated. Other named values
#'   are stored as supplied without type or range checks.
#' @examples
#' pharma_config(log_level = "DEBUG", default_ci = 0.9)
#' pharma_config()
#' @export
pharma_config <- function(...) {
  defaults <- list(
    log_level = "INFO",
    plot_theme = "minimal",
    default_ci = 0.95,
    parallel_strategy = "sequential",
    max_cores = .pharma_default_max_cores(),
    cache_dir = tempdir()
  )
  current <- getOption("pharma", defaults)
  new <- list(...)
  if (length(new) == 0) {
    return(current)
  }
  unknown <- setdiff(names(new), names(defaults))
  if (length(unknown) > 0) {
    stop("Unknown option(s): ", paste(unknown, collapse = ", "))
  }
  if ("log_level" %in% names(new)) {
    levels <- c("DEBUG", "INFO", "WARN", "ERROR")
    lvl <- toupper(new$log_level)
    if (!lvl %in% levels) {
      stop("`log_level` must be one of: ", paste(levels, collapse = ", "))
    }
    new$log_level <- lvl
  }
  current <- utils::modifyList(current, new)
  options(pharma = current)
  invisible(current)
}

.pharma_default_max_cores <- function(cores = parallel::detectCores()) {
  if (length(cores) != 1L || !is.numeric(cores) ||
      !is.finite(cores) || cores < 2L) {
    return(1L)
  }
  as.integer(cores) - 1L
}

#' Temporarily modify configuration options
#'
#' `with_pharma_config()` sets package options for the duration of `expr` and
#' restores the exact previous `pharma` option on exit, even when it was unset.
#'
#' @param options Named list of options to set.
#' @param expr Expression to evaluate while the options are active.
#' @return The result of `expr`.
#' @examples
#' with_pharma_config(list(log_level = "DEBUG"), {
#'   pharma_config()$log_level
#' })
#' @export
with_pharma_config <- function(options, expr) {
  old <- getOption("pharma")
  on.exit(base::options(pharma = old), add = TRUE)
  do.call(pharma_config, options)
  force(expr)
}
