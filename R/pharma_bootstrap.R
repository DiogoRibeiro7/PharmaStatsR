#' Bootstrap utilities
#'
#' Collection of bootstrap helpers including wild, block, and parallel bootstrap methods.
#'
#' @name pharma_bootstrap
NULL

#' Wild bootstrap for linear models
#'
#' Applies the Rademacher wild bootstrap to obtain resampled coefficient
#' estimates for a linear model.
#'
#' @param formula Model formula for `lm`.
#' @param data Data frame containing the variables.
#' @param R Number of bootstrap replicates.
#'
#' @return A matrix of bootstrap coefficients with one row per replicate.
#' @export
#'
#' @examples
#' res <- pharma_wild_bootstrap(response ~ treatment, data = pharma_sample, R = 10)
#' head(res)
pharma_wild_bootstrap <- function(formula, data, R = 1000) {
  pharma_log("INFO", "Running pharma_wild_bootstrap")
  if (!inherits(formula, "formula")) {
    stop("`formula` must be a valid formula, e.g., response ~ predictor")
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame; got ", class(data)[1])
  }
  check_dataset(data, all.vars(formula))
  mf <- stats::model.frame(formula, data)
  if (anyNA(mf)) {
    stop("Variables in `data` used by `formula` contain NA values; remove or impute them before calling `pharma_wild_bootstrap`")
  }
  response <- mf[[1]]
  if (!is.numeric(response)) {
    stop("Response variable must be numeric")
  }
  if (!all(is.finite(response))) {
    stop("Response variable must contain only finite values")
  }
  if (!is.numeric(R) || length(R) != 1 || R <= 0 || !is.finite(R)) {
    stop("`R` must be a positive integer; got ", R)
  }
  R <- as.integer(R)
  fit <- stats::lm(formula, data = mf)
  X <- stats::model.matrix(fit)
  fitted <- stats::fitted(fit)
  res <- stats::residuals(fit)
  coef_mat <- matrix(NA_real_, nrow = R, ncol = length(stats::coef(fit)))
  for (i in seq_len(R)) {
    w <- sample(c(-1, 1), length(res), replace = TRUE)
    y_star <- fitted + res * w
    coef_mat[i, ] <- stats::lm.fit(x = X, y = y_star)$coefficients
  }
  colnames(coef_mat) <- names(stats::coef(fit))
  coef_mat
}

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
#' stat <- function(d) stats::coef(stats::lm(response ~ treatment, data = d))[2]
#' res <- pharma_block_bootstrap(pharma_sample, "subject", stat, R = 10)
pharma_block_bootstrap <- function(data, cluster, statistic, R = 1000, ...) {
  pharma_log("INFO", "Running pharma_block_bootstrap")
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame; got ", class(data)[1])
  }
  if (nrow(data) == 0) {
    stop("`data` must have at least one row")
  }
  if (anyNA(data)) {
    stop("`data` contains NA values; remove or impute them before calling `pharma_block_bootstrap`")
  }
  if (!is.function(statistic)) {
    stop("`statistic` must be a function; got ", class(statistic)[1])
  }
  if (!is.numeric(R) || length(R) != 1 || R <= 0 || !is.finite(R)) {
    stop("`R` must be a positive integer; got ", R)
  }
  R <- as.integer(R)
  if (is.character(cluster)) {
    check_dataset(data, cluster)
    clust <- data[[cluster]]
  } else {
    clust <- cluster
  }
  if (length(clust) != nrow(data)) {
    stop(
      "`cluster` must be a column name or vector of length ", nrow(data),
      "; got length ", length(clust)
    )
  }
  if (anyNA(clust)) {
    stop("`cluster` cannot contain NA values")
  }
  groups <- split(seq_len(nrow(data)), clust)
  uniq <- names(groups)
  results <- vector("list", R)
  for (i in seq_len(R)) {
    sampled <- sample(uniq, length(uniq), replace = TRUE)
    indices <- unlist(groups[sampled], use.names = FALSE)
    boot_dat <- data[indices, , drop = FALSE]
    results[[i]] <- statistic(boot_dat, ...)
  }
  results
}

#' Parallel bootstrap using future.apply
#'
#' Perform bootstrap resampling of a statistic using parallel workers via the
#' `future` framework. This function mirrors `pharma_block_bootstrap` but
#' distributes iterations across the available workers for speed.
#'
#' @param data A data frame containing the sample.
#' @param statistic Function computing the statistic of interest. It must accept
#'   the data frame as its first argument.
#' @param R Integer. Number of bootstrap replicates.
#' @param plan Character or call to define the future plan. Defaults to
#'   `"multisession"`.
#' @param ... Additional arguments passed to `statistic`.
#'
#' @return A list of bootstrap statistics with length `R`.
#' @export
#'
#' @examples
#' stat <- function(d) mean(d$response)
#' pharma_parallel_bootstrap(pharma_sample, stat, R = 10)
pharma_parallel_bootstrap <- function(data, statistic, R = 1000,
                                      plan = "multisession", ...) {
  pharma_log("INFO", "Running pharma_parallel_bootstrap")
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame; got ", class(data)[1])
  }
  if (nrow(data) == 0) {
    stop("`data` must have at least one row")
  }
  if (anyNA(data)) {
    stop("`data` contains NA values; remove or impute them before calling `pharma_parallel_bootstrap`")
  }
  if (!is.function(statistic)) {
    stop("`statistic` must be a function; got ", class(statistic)[1])
  }
  if (!is.numeric(R) || length(R) != 1 || R <= 0 || !is.finite(R)) {
    stop("`R` must be a positive integer; got ", R)
  }
  R <- as.integer(R)
  if (!is.character(plan) && !is.call(plan) && !is.function(plan)) {
    stop("`plan` must be a string, function, or call understood by future::plan, e.g., 'multisession'; got ", class(plan)[1])
  }
  old_plan <- future::plan()
  on.exit(future::plan(old_plan), add = TRUE)
  future::plan(plan)
  future.apply::future_lapply(seq_len(R), function(i) {
    indices <- sample(nrow(data), nrow(data), replace = TRUE)
    boot_data <- data[indices, , drop = FALSE]
    statistic(boot_data, ...)
  })
}
