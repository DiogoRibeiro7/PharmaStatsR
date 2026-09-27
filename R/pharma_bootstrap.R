#' Bootstrap utilities
#'
#' Collection of bootstrap helpers including wild, block, and parallel bootstrap methods.
#'
#' @name pharma_bootstrap
NULL

#' Wild bootstrap coefficient draws for a linear model
#'
#' Keep the fitted design fixed and independently multiply each raw residual by
#' a Rademacher sign (-1 or 1) before refitting the response. Uses the complete
#' model frame from the original data, including transformed terms and offsets.
#'
#' @param formula Two-sided linear-model formula with a numeric vector response.
#'   All variables must be columns of `data`.
#' @param data Data frame containing the model variables; missing values in
#'   variables used by the model are rejected rather than silently dropped.
#' @param R Positive whole number of bootstrap coefficient draws.
#'
#' @return Numeric matrix with one row per bootstrap draw and one column per
#'   original model coefficient. Set a seed before calling for reproducibility.
#' @export
#'
#' @examples
#' set.seed(42)
#' draws <- pharma_wild_bootstrap(response ~ treatment, pharma_sample, R = 20)
#' head(draws)
pharma_wild_bootstrap <- function(formula, data, R = 1000) {
  pharma_log("INFO", "Running pharma_wild_bootstrap")
  if (!inherits(formula, "formula") || length(formula) != 3L) {
    stop("`formula` must be a two-sided formula", call. = FALSE)
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame", call. = FALSE)
  }
  if (!is.numeric(R) || length(R) != 1L || is.na(R) ||
      !is.finite(R) || R < 1 || R != floor(R) ||
      R > .Machine$integer.max) {
    stop("`R` must be a positive whole number", call. = FALSE)
  }
  check_dataset(data, all.vars(formula))

  # na.fail prevents the fitted model from silently changing the analysis rows.
  fit <- stats::lm(formula, data = data, na.action = stats::na.fail,
                   x = TRUE, model = TRUE, singular.ok = FALSE)
  response <- stats::model.response(fit$model)
  if (!is.numeric(response) || !is.null(dim(response)) ||
      !all(is.finite(response))) {
    stop("`formula` must have one finite numeric response vector", call. = FALSE)
  }
  X <- fit$x
  if (ncol(X) == 0L || fit$df.residual < 1L) {
    stop("Model needs coefficients and positive residual degrees of freedom",
         call. = FALSE)
  }

  fitted <- stats::fitted(fit)
  residuals <- stats::residuals(fit)
  coefficients <- matrix(NA_real_, nrow = as.integer(R), ncol = ncol(X),
                         dimnames = list(NULL, colnames(X)))
  for (i in seq_len(R)) {
    signs <- sample(c(-1, 1), length(residuals), replace = TRUE)
    y_star <- fitted + residuals * signs
    # lm.fit applies the original formula offset during every refit.
    coefficients[i, ] <- stats::lm.fit(X, y_star, offset = fit$offset,
                                       singular.ok = FALSE)$coefficients
  }
  coefficients
}

#' Block bootstrap for clustered data
#'
#' Resample clusters with replacement to compute bootstrap replicates of a
#' user-supplied statistic.
#'
#' @param data **data.frame** to resample.
#' @param cluster **character** or **vector** defining clusters.
#' @param statistic **function** computing the statistic of interest. It must accept
#'   the data frame as its first argument.
#' @param R **integer** number of bootstrap replicates.
#' @param progress **logical**; display a progress indicator when `TRUE` (default
#'   `interactive()`).
#' @param ... additional arguments passed to `statistic`.
#'
#' @return A list of bootstrap statistics with length `R`.
#' @export
#'
#' @examples
#' stat <- function(d) stats::coef(stats::lm(response ~ treatment, data = d))[2]
#' res <- pharma_block_bootstrap(pharma_sample, "subject", stat, R = 10)
pharma_block_bootstrap <- function(data, cluster, statistic, R = 1000,
                                   progress = interactive(), ...) {
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
  prog <- if (progress) pharma_progress(R, "Bootstrap") else NULL
  for (i in seq_len(R)) {
    sampled_clusters <- sample.int(length(uniq), length(uniq), replace = TRUE)
    sampled_groups <- uniq[sampled_clusters]
    indices <- unlist(groups[sampled_groups], use.names = FALSE)
    if (nrow(data) > 10000 && requireNamespace("data.table", quietly = TRUE)) {
      dt <- data.table::as.data.table(data)
      boot_dat <- dt[indices]
    } else {
      boot_dat <- data[indices, , drop = FALSE]
    }
    results[[i]] <- statistic(boot_dat, ...)
    if (!is.null(prog)) {
      prog$update()
    }
  }
  if (!is.null(prog)) {
    prog$finish()
  }
  results
}

#' Parallel bootstrap using future.apply
#'
#' Perform bootstrap resampling of a statistic using parallel workers via the
#' `future` framework. This function mirrors `pharma_block_bootstrap` but
#' distributes iterations across the available workers for speed.
#'
#' @param data **data.frame** containing the sample.
#' @param statistic **function** computing the statistic of interest. It must accept
#'   the data frame as its first argument.
#' @param R **integer** number of bootstrap replicates.
#' @param plan **character**, **function**, or call defining the future plan. Defaults to
#'   `"multisession"`.
#' @param ... additional arguments passed to `statistic`.
#'
#' @return A list of bootstrap statistics with length `R`.
#' @export
#'
#' @examples
#' if (requireNamespace("future.apply", quietly = TRUE)) {
#' stat <- function(d) mean(d$response)
#' pharma_parallel_bootstrap(pharma_sample, stat, R = 10)
#' }

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
