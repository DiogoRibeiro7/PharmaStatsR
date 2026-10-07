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

#' Cluster bootstrap for a user-supplied statistic
#'
#' Sample the observed clusters with replacement, taking every row from each
#' selected cluster. The number of rows can change between replicates when
#' clusters have different sizes.
#'
#' @param data Data frame to resample. Missing values outside the cluster IDs
#'   are passed to `statistic` for the caller to handle.
#' @param cluster Single character column name or an atomic vector of cluster
#'   IDs with one value per row. Character vectors of length greater than one
#'   are treated as IDs, not as column names. At least two observed clusters
#'   are required; cluster IDs cannot be missing.
#' @param statistic Function receiving a resampled data frame as its first
#'   argument and any additional arguments from `...`.
#' @param R Positive whole number of bootstrap replicates.
#' @param progress Single nonmissing logical flag for interactive progress.
#' @param ... Additional arguments forwarded to `statistic`.
#' @param resample_id Optional new column name. When supplied, each selected
#'   copy of a cluster gets a distinct integer ID in this column, including
#'   when the same original cluster is selected more than once. Pass by name.
#'
#' @return A list of `R` statistics, including any `NULL` callback values;
#'   set a seed for reproducible resampling.
#' @export
#'
#' @examples
#' stat <- function(d) mean(d$response)
#' set.seed(42)
#' res <- pharma_block_bootstrap(pharma_sample, "subject", stat, R = 10)
pharma_block_bootstrap <- function(data, cluster, statistic, R = 1000,
                                   progress = interactive(), ...,
                                   resample_id = NULL) {
  pharma_log("INFO", "Running pharma_block_bootstrap")
  if (!is.data.frame(data) || nrow(data) == 0L) {
    stop("`data` must be a nonempty data frame", call. = FALSE)
  }
  if (!is.function(statistic)) {
    stop("`statistic` must be a function", call. = FALSE)
  }
  if (!is.numeric(R) || length(R) != 1L || is.na(R) ||
      !is.finite(R) || R < 1 || R != floor(R) ||
      R > .Machine$integer.max) {
    stop("`R` must be a positive whole number", call. = FALSE)
  }
  if (!is.logical(progress) || length(progress) != 1L || is.na(progress)) {
    stop("`progress` must be a single nonmissing logical value", call. = FALSE)
  }

  # Keep the callback input a base data frame, regardless of optional packages.
  data <- as.data.frame(data)
  if (!is.null(resample_id) &&
      (!is.character(resample_id) || length(resample_id) != 1L ||
       is.na(resample_id) || !nzchar(resample_id) ||
       resample_id %in% names(data))) {
    stop("`resample_id` must be a new, nonempty column name", call. = FALSE)
  }
  if (is.character(cluster) && length(cluster) == 1L) {
    check_dataset(data, cluster)
    clust <- data[[cluster]]
  } else {
    clust <- cluster
  }
  if (!is.atomic(clust) || !is.null(dim(clust)) ||
      length(clust) != nrow(data) || anyNA(clust)) {
    stop("`cluster` must be a nonmissing atomic vector with one ID per row",
         call. = FALSE)
  }

  # Dropping unused factor levels prevents sampling clusters with no rows.
  groups <- split(seq_len(nrow(data)), clust, drop = TRUE)
  n_clusters <- length(groups)
  if (n_clusters < 2L) {
    stop("`cluster` must contain at least two observed clusters",
         call. = FALSE)
  }

  results <- vector("list", as.integer(R))
  prog <- if (progress) pharma_progress(R, "Bootstrap") else NULL
  for (i in seq_len(R)) {
    sampled <- sample.int(n_clusters, n_clusters, replace = TRUE)
    indices <- unlist(groups[sampled], use.names = FALSE)
    boot_dat <- data[indices, , drop = FALSE]
    if (!is.null(resample_id)) {
      # Copies of the same source cluster must remain distinct for grouping.
      boot_dat[[resample_id]] <- rep(seq_along(sampled),
                                      times = lengths(groups)[sampled])
    }
    # Single-bracket assignment retains a NULL statistic as one replicate.
    results[i] <- list(statistic(boot_dat, ...))
    if (!is.null(prog)) {
      prog$update()
    }
  }
  if (!is.null(prog)) {
    prog$finish()
  }
  results
}

.pharma_validate_future_workers <- function(workers) {
  if (!is.numeric(workers) || length(workers) != 1L ||
      is.na(workers) || !is.finite(workers) ||
      workers < 1 || workers > 2) {
    stop("`plan` must configure one or two workers", call. = FALSE)
  }
  invisible(as.integer(workers))
}

#' Row bootstrap with reproducible future workers
#'
#' Resample individual rows with replacement and evaluate `statistic` for
#' each replicate using future.apply. Each replicate has the original row
#' count. Parallel-safe random streams make seeded results reproducible
#' across future backends; the caller's previous future plan is restored.
#'
#' @param data Nonempty data frame of independent observational units. Missing
#'   values are passed to `statistic` for the caller to handle.
#' @param statistic Function receiving a resampled base data frame as its first
#'   argument.
#' @param R Positive whole number of bootstrap replicates.
#' @param plan Future strategy name, function, or call accepted by
#'   `future::plan()`; defaults to `"multisession"`. The configured strategy
#'   must expose no more than two workers; plans above that limit are rejected
#'   before bootstrap futures are launched.
#' @param ... Additional arguments passed to `statistic`.
#'
#' @return A list with one statistic per bootstrap replicate. Set a seed
#'   before calling for reproducibility across future strategies.
#' @export
#'
#' @examples
#' if (requireNamespace("future.apply", quietly = TRUE)) {
#'   set.seed(42)
#'   stat <- function(d) mean(d$response)
#'   pharma_parallel_bootstrap(pharma_sample, stat, R = 10,
#'                             plan = "sequential")
#' }
pharma_parallel_bootstrap <- function(data, statistic, R = 1000,
                                      plan = "multisession", ...) {
  pharma_log("INFO", "Running pharma_parallel_bootstrap")
  if (!is.data.frame(data) || nrow(data) == 0L) {
    stop("`data` must be a nonempty data frame", call. = FALSE)
  }
  if (!is.function(statistic)) {
    stop("`statistic` must be a function", call. = FALSE)
  }
  if (!is.numeric(R) || length(R) != 1L || is.na(R) ||
      !is.finite(R) || R < 1 || R != floor(R) ||
      R > .Machine$integer.max) {
    stop("`R` must be a positive whole number", call. = FALSE)
  }
  if (!(is.function(plan) || is.call(plan) ||
        (is.character(plan) && length(plan) == 1L &&
         !is.na(plan) && nzchar(plan)))) {
    stop("`plan` must be a single strategy name, function, or call",
         call. = FALSE)
  }
  .pharma_require_optional("future", "pharma_parallel_bootstrap")
  .pharma_require_optional("future.apply", "pharma_parallel_bootstrap")

  data <- as.data.frame(data)
  old_plan <- future::plan()
  on.exit(future::plan(old_plan), add = TRUE)
  if (identical(plan, "multisession")) {
    future::plan(plan, workers = 2L)
  } else {
    future::plan(plan)
  }
  .pharma_validate_future_workers(future::nbrOfWorkers())

  future.apply::future_lapply(seq_len(R), function(i) {
    indices <- sample.int(nrow(data), nrow(data), replace = TRUE)
    boot_data <- data[indices, , drop = FALSE]
    statistic(boot_data, ...)
  }, future.seed = TRUE)
}
