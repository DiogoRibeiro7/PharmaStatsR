 #' Manage PharmaTestSuite configuration
 #'
 #' `pharma_config()` gets or sets package-wide options such as logging
 #' verbosity and defaults used throughout the package.
 #'
 #' @param ... Named options to set. Supported options are:
 #'   - `log_level`: logging verbosity ("DEBUG", "INFO", "WARN", "ERROR").
 #'   - `plot_theme`: default ggplot2 theme to apply to visualisations.
 #'   - `default_ci`: default confidence level for interval estimates.
 #'   - `parallel_strategy`: parallel backend for resampling helpers.
 #'   - `max_cores`: maximum number of cores to utilise.
 #'   - `cache_dir`: directory used for caching intermediate results.
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
     max_cores = max(parallel::detectCores() - 1, 1),
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
   current <- modifyList(current, new)
   options(pharma = current)
   invisible(current)
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
#'   pharma_log("debug message", level = "DEBUG")
#' })
#' @export
with_pharma_config <- function(options, expr) {
  old <- pharma_config()
  on.exit(do.call(pharma_config, old))
  do.call(pharma_config, options)
  force(expr)
}
