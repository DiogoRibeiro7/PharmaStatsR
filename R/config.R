#' Manage PharmaTestSuite configuration
#'
#' `pharma_config()` gets or sets package-wide options such as logging verbosity.
#'
#' @param ... Named options to set. Supported options are:
#'   - `log_level`: logging verbosity ("DEBUG", "INFO", "WARN", "ERROR").
#'
#' @return A named list of current configuration values.
#' @examples
#' pharma_config(log_level = "DEBUG")
#' pharma_config()
#' @export
pharma_config <- function(...) {
  defaults <- list(log_level = "INFO")
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
