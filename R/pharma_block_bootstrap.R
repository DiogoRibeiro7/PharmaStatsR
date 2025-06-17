#' Block bootstrap for clustered data
#'
#' Resample clusters with replacement to compute bootstrap replicates of a
#' user-supplied statistic.
#'
#' @param data Data frame.
#' @param cluster Vector or column name defining clusters.
#' @param statistic Function computing the statistic of interest. It must accept
#'   the data frame as its first argument.
#' @param R Number of bootstrap replicates.
#' @param ... Additional arguments passed to `statistic`.
#'
#' @return A list of bootstrap statistics with length `R`.
#' @export
#'
#' @examples
#' stat <- function(d) coef(lm(response ~ treatment, data = d))[2]
#' res <- pharma_block_bootstrap(pharma_sample, "subject", stat, R = 10)
pharma_block_bootstrap <- function(data, cluster, statistic, R = 1000, ...) {
  clust <- if (is.character(cluster)) data[[cluster]] else cluster
  uniq <- unique(clust)
  results <- vector("list", R)
  for (i in seq_len(R)) {
    sampled <- sample(uniq, length(uniq), replace = TRUE)
    indices <- unlist(lapply(sampled, function(g) which(clust == g)))
    boot_dat <- data[indices, , drop = FALSE]
    results[[i]] <- statistic(boot_dat, ...)
  }
  results
}
