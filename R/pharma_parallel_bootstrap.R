#' Parallel bootstrap using future.apply
#'
#' Perform bootstrap resampling of a statistic using parallel workers via the
#' `future` framework. This function mirrors \code{pharma_block_bootstrap} but
#' distributes iterations across the available workers for speed.
#'
#' @param data A data frame containing the sample.
#' @param statistic Function computing the statistic of interest. It must accept
#'   the data frame as its first argument.
#' @param R Integer. Number of bootstrap replicates.
#' @param plan Character or call to define the future plan. Defaults to
#'   \code{"multisession"}.
#' @param ... Additional arguments passed to \code{statistic}.
#'
#' @return A list of bootstrap statistics with length \code{R}.
#' @export
#'
#' @examples
#' stat <- function(d) mean(d$response)
#' pharma_parallel_bootstrap(pharma_sample, stat, R = 10)
pharma_parallel_bootstrap <- function(data, statistic, R = 1000,
                                      plan = "multisession", ...) {
  # Save current plan and restore on exit
  old_plan <- future::plan()
  on.exit(future::plan(old_plan), add = TRUE)
  future::plan(plan)

  # Perform bootstrap in parallel
  future.apply::future_lapply(seq_len(R), function(i) {
    indices <- sample(nrow(data), nrow(data), replace = TRUE)
    boot_data <- data[indices, , drop = FALSE]
    statistic(boot_data, ...)
  })
}
