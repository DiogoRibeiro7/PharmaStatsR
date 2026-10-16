#' Visual predictive check from replicated response datasets
#'
#' Compare observed within-bin response quantiles with the distribution of the
#' same quantiles across supplied simulated datasets. This function summarizes
#' simulations; it does not fit a model or generate random numbers.
#'
#' @param data Nonempty data frame with unique column names and finite real
#'   numeric time and response columns. No rows are removed.
#' @param simulations Finite real numeric matrix with one row per row of `data`
#'   and at least two columns. Each column is a complete simulated response
#'   dataset in exactly the same row order as `data`. If row names are present,
#'   they must equal `rownames(data)` in order; no automatic matching occurs.
#' @param time,response Single column names; literal names are supported.
#' @param bins Positive integer number of requested time-quantile bins.
#'   Duplicate edges are collapsed and empty bins omitted. Constant time gives
#'   one bin. Actual bin counts can therefore be smaller than requested.
#' @param probs Strictly increasing numeric response probabilities between
#'   zero and one (exclusive), defaulting to the 5th, 50th and 95th percentiles.
#' @param level One number strictly between zero and one: central simulation
#'   interval coverage for each within-bin response quantile.
#'
#' @return A faceted `ggplot` object. Its `data` component contains one row per
#'   nonempty bin and probability: `bin`, `left`, `right`, `bin_time` (mean
#'   observation time), `n` (observed row count), `probability`, `observed`,
#'   `simulated` (median replicate quantile), `lower`, `upper`, and `nsim`.
#'   The `vpc_bins` attribute is a data frame mapping original row names (`row`)
#'   to bin numbers (`bin`). `vpc_settings` records `breaks`, `probs`, `level`,
#'   `nsim`, and `quantile_type`. Bin numbers index the original collapsed
#'   breaks and may have gaps when intervals are empty.
#' @details
#' Time edges and all response summaries use [stats::quantile()] type 7.
#' Intervals are right-closed, with the lowest endpoint included. For each bin
#' and probability, compute the response quantile separately in every replicate;
#' then take the median and the `(1 - level) / 2` and `(1 + level) / 2`
#' quantiles across these replicate statistics. Replicates are never pooled.
#' Each observation has equal weight within its bin, including repeated rows
#' from a subject; each replicate has equal weight in the simulation summaries.
#'
#' Ribbons describe variation of the simulated percentile statistic, not the
#' spread of individual responses, simultaneous coverage, a model-parameter
#' confidence interval, or a formal goodness-of-fit test. Their interpretation
#' depends on the supplied simulation design. Preserve the observation schedule
#' and any subject dependence when generating replicates. Parameter uncertainty
#' is represented only if included in those simulations. Two replicates are
#' accepted for deterministic checks, but useful tail summaries generally need
#' many more; assess Monte Carlo stability for the intended analysis.
#'
#' Missing or nonfinite observations and simulated values are rejected. Perform
#' any cohort selection jointly before calling. This helper has no censoring,
#' prediction correction, stratification, weighting, or model-specific adapters.
#' It is separate from [plot_vpc()], which remains a descriptive fitted-value
#' comparison without simulation.
#' @examples
#' set.seed(215)
#' d <- data.frame(Time = rep(0:3, 4))
#' subject <- rep(1:4, each = 4)
#' # Illustrative known Gaussian random-intercept process, not an estimated fit.
#' generate <- function() {
#'   2 + 0.5 * d$Time + rnorm(4, sd = 0.7)[subject] +
#'     rnorm(nrow(d), sd = 0.3)
#' }
#' d$DV <- generate()
#' simulations <- replicate(200, generate())
#' check <- plot_simulated_vpc(d, simulations, bins = 4)
#' check
#' head(check$data)
#' @export
plot_simulated_vpc <- function(data, simulations, time = "Time", response = "DV",
                               bins = 10L, probs = c(0.05, 0.5, 0.95),
                               level = 0.9) {
  validate_data_frame_names(data)
  if (nrow(data) == 0L) {
    stop("`data` must contain at least one row")
  }
  for (column in list(time = time, response = response)) {
    if (!is.character(column) || !is.null(dim(column)) ||
      length(column) != 1L || is.na(column) || !nzchar(column)) {
      stop("`time` and `response` must be single nonempty column names")
    }
  }
  validate_preprocessing_vars(data, unique(c(time, response)))
  if (any(!is.finite(data[[time]])) || any(!is.finite(data[[response]]))) {
    stop("Time and response must contain only finite observed values")
  }
  if (!is.matrix(simulations) || !is.numeric(simulations) ||
    is.complex(simulations) || nrow(simulations) != nrow(data) ||
    ncol(simulations) < 2L || any(!is.finite(simulations))) {
    stop(paste(
      "`simulations` must be a finite real numeric matrix with",
      "one row per data row and at least two replicate columns"
    ))
  }
  if (!is.null(rownames(simulations)) &&
    !identical(rownames(simulations), rownames(data))) {
    stop("Simulation row names must match data row names in the same order")
  }
  if (!is_numeric_vector(bins) || length(bins) != 1L || !is.finite(bins) ||
    bins < 1 || bins != floor(bins) || bins >= .Machine$integer.max) {
    stop("`bins` must be one positive integer below .Machine$integer.max")
  }
  if (!is_numeric_vector(probs) || length(probs) == 0L ||
    any(!is.finite(probs)) || any(probs <= 0 | probs >= 1) ||
    is.unsorted(probs, strictly = TRUE)) {
    stop("`probs` must be strictly increasing probabilities between 0 and 1")
  }
  if (!is_numeric_vector(level) || length(level) != 1L ||
    !is.finite(level) || level <= 0 || level >= 1) {
    stop("`level` must be one number strictly between 0 and 1")
  }

  quantiles <- function(x, p) {
    stats::quantile(x, probs = p, type = 7, names = FALSE)
  }
  edges <- unique(quantiles(data[[time]], seq(0, 1, length.out = bins + 1)))
  if (length(edges) == 1L) {
    row_bin <- rep(1L, nrow(data))
  } else {
    row_bin <- cut(data[[time]], edges, include.lowest = TRUE, labels = FALSE)
  }
  interval_probs <- c((1 - level) / 2, 0.5, (1 + level) / 2)
  summaries <- lapply(sort(unique(row_bin)), function(bin) {
    rows <- which(row_bin == bin)
    replicate_quantiles <- matrix(vapply(seq_len(ncol(simulations)), function(j) {
      quantiles(simulations[rows, j], probs)
    }, numeric(length(probs))), nrow = length(probs))
    intervals <- vapply(seq_along(probs), function(k) {
      quantiles(replicate_quantiles[k, ], interval_probs)
    }, numeric(3L))
    data.frame(
      bin = bin, left = edges[bin], right = edges[min(bin + 1L, length(edges))],
      bin_time = mean(data[[time]][rows]), n = length(rows), probability = probs,
      observed = quantiles(data[[response]][rows], probs),
      simulated = intervals[2L, ], lower = intervals[1L, ], upper = intervals[3L, ],
      nsim = ncol(simulations)
    )
  })
  summary <- do.call(rbind, summaries)
  line_data <- if (length(summaries) > 1L) summary else summary[FALSE, ]
  plot <- ggplot2::ggplot(summary, ggplot2::aes(x = bin_time)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper),
      fill = "#4477AA", alpha = 0.25
    ) +
    ggplot2::geom_linerange(ggplot2::aes(ymin = lower, ymax = upper),
      colour = "#4477AA", alpha = 0.5
    ) +
    ggplot2::geom_point(ggplot2::aes(y = simulated), shape = 1) +
    ggplot2::geom_line(ggplot2::aes(y = simulated, linetype = "Simulation median"),
      data = line_data
    ) +
    ggplot2::geom_line(ggplot2::aes(y = observed, linetype = "Observed"),
      data = line_data
    ) +
    ggplot2::geom_point(ggplot2::aes(y = observed)) +
    ggplot2::facet_wrap(~probability, labeller = ggplot2::label_both) +
    ggplot2::scale_linetype_manual(limits = c("Observed", "Simulation median"), values = c(
      "Observed" = "solid", "Simulation median" = "dashed"
    )) +
    ggplot2::labs(
      x = time, y = response, linetype = NULL,
      caption = paste0(
        "Ribbons: ", format(100 * level),
        "% simulation intervals for within-bin percentiles (",
        ncol(simulations), " replicates)."
      )
    ) +
    ggplot2::theme_minimal()
  attr(plot, "vpc_bins") <- data.frame(row = rownames(data), bin = row_bin)
  attr(plot, "vpc_settings") <- list(
    breaks = edges, probs = unname(probs), level = unname(level),
    nsim = ncol(simulations), quantile_type = 7L
  )
  plot
}
