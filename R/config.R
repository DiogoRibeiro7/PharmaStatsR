#' Manage PharmaStatsR configuration
#'
#' `pharma_config()` gets or sets package-wide options such as logging
#' verbosity and defaults used throughout the package.
#'
#' @param ... Named options to set. Supported options are:
#'   - `log_level` (**character**): logging verbosity ("DEBUG", "INFO",
#'     "WARN", "ERROR").
#'   - `plot_theme` (**character**): default ggplot2 theme to apply to
#'     visualisations.
#'   - `default_ci` (**numeric**): default confidence level for interval
#'     estimates.
#'   - `parallel_strategy` (**character**): parallel backend for resampling
#'     helpers.
#'   - `max_cores` (**integer**): maximum number of cores to utilise. The
#'     default is at least one, including when core detection is unavailable.
#'   - `cache_dir` (**character**): directory used for caching intermediate
#'     results.
#'
#' @return A named list of current configuration values.
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
#' restores the previous values on exit.
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
  old <- pharma_config()
  on.exit(do.call(pharma_config, old))
  do.call(pharma_config, options)
  force(expr)
}
