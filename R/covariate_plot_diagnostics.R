#' Observed vs. Predicted Plot
#'
#' Creates a scatter plot comparing observed responses to model predictions.
#'
#' Predictions use the model's native defaults: for `lme`, these include fitted
#' subject effects. The method must return one real numeric value per input
#' row, in input order. Matrices, lists, wrong lengths and infinite values raise
#' errors. Missing values are retained for ggplot2 to omit when drawing points.
#' An unrelated input column named `preds` cannot replace model predictions.
#'
#' @param model An object with a `predict` method returning a numeric vector.
#' @param data A uniquely named `data.frame` containing a real numeric `DV`
#'   column. Values must be finite or missing. Supply the column names expected
#'   by the native model, including repaired names when applicable.
#'
#' @return A `ggplot` object showing observed vs. predicted values.
#' @examples
#' df <- data.frame(
#'   SubjectID = rep(1:5, each = 2),
#'   Time = rep(0:1, times = 5),
#'   DV = rnorm(10),
#'   WT = rnorm(10, 70, 5)
#' )
#' model <- fit_covariate_model(df, "DV", "SubjectID", "Time")
#' plot_obs_vs_pred(model, df)
#' @export
plot_obs_vs_pred <- function(model, data) {
  validate_data_frame_names(data)
  if (!"DV" %in% names(data)) {
    stop("`data` must contain 'DV' column")
  }

  validate_diagnostic_values(data$DV, nrow(data), "DV")
  preds <- stats::predict(model, data)
  validate_diagnostic_values(preds, nrow(data), "Predictions")
  # Store predictions in a copy while retaining columns for plot customization.
  plotted <- data
  plotted$preds <- as.numeric(preds)

  ggplot2::ggplot(plotted, ggplot2::aes(x = preds, y = DV)) +
    ggplot2::geom_point() +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = "red") +
    ggplot2::labs(x = "Predicted", y = "Observed") +
    ggplot2::theme_minimal()
}

#' Residual Plots Over Time
#'
#' Generates raw and normalized residual plots over time for a fitted model.
#'
#' Both residual vectors must have one real numeric entry per row of
#' `model$data`, in its stored order. Missing values are retained; infinite
#' values and mismatched lengths raise errors. Use `na.exclude` when fitting
#' with omitted rows so residuals are padded to the original data length.
#' Native residual defaults are retained: `lme` uses the innermost subject
#' level, and normalized residuals account for its fitted residual covariance.
#'
#' @param model A fitted model object from `nlme::lme` or similar, with stored
#'   data containing a real numeric `Time` column (finite or missing). It must
#'   support both response and normalized residual vectors.
#'
#' @return A faceted `ggplot` object with residuals.
#' @examples
#' df <- data.frame(
#'   SubjectID = rep(1:5, each = 2),
#'   Time = rep(0:1, times = 5),
#'   DV = rnorm(10),
#'   WT = rnorm(10, 70, 5)
#' )
#' model <- fit_covariate_model(df, "DV", "SubjectID", "Time")
#' plot_residuals(model)
#' @export
plot_residuals <- function(model) {
  if (!is.data.frame(model$data) || !"Time" %in% names(model$data)) {
    stop("model$data must contain 'Time' column")
  }

  validate_data_frame_names(model$data)
  n <- nrow(model$data)
  validate_diagnostic_values(model$data$Time, n, "Time")
  raw_res <- stats::residuals(model, type = "response")
  norm_res <- stats::residuals(model, type = "normalized")
  validate_diagnostic_values(raw_res, n, "Response residuals")
  validate_diagnostic_values(norm_res, n, "Normalized residuals")
  df_raw <- data.frame(Time = model$data$Time, Residual = as.numeric(raw_res), Type = "Raw")
  df_norm <- data.frame(
    Time = model$data$Time,
    Residual = as.numeric(norm_res),
    Type = "Normalized"
  )
  df <- rbind(df_raw, df_norm)

  ggplot2::ggplot(df, ggplot2::aes(x = Time, y = Residual)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~Type, scales = "free_y") +
    ggplot2::labs(x = "Time", y = "Residual") +
    ggplot2::theme_minimal()
}

#' Binned observed and fitted-value comparison
#'
#' Compares observed percentiles and median fitted values across time bins.
#' The observed ribbon describes the data distribution. This function does not
#' simulate new observations or estimate predictive uncertainty, so it is not
#' a simulation-based visual predictive check. The function name is retained
#' for compatibility.
#'
#' Bin edges and observed percentiles use R's type-7 sample quantiles.
#' Duplicate edges are collapsed; intervals are right-closed and include the
#' lowest time. Each x coordinate is the mean observed time in that bin, not
#' the midpoint of its edges. At least two distinct observed times are needed.
#' Missing times do not enter summaries. Within each bin, missing observations
#' and predictions are removed separately, so their summaries can use different
#' rows. A bin with no values for a summary has a missing result.
#'
#' Native prediction defaults are retained. Predictions must be a real numeric
#' vector with one value per input row, in input order; recycling and matrix
#' predictions are rejected. Infinite data or predictions raise errors.
#'
#' @param model A fitted model with a `predict` method returning a numeric vector.
#' @param data A uniquely named `data.frame` containing real numeric `Time` and
#'   `DV` columns, finite or missing, and the native model's required columns.
#' @param bins Positive integer number of requested time bins. Duplicate edges
#'   can reduce the number of bins; empty bins can have missing summaries.
#'
#' @return A `ggplot` object with observed ribbons and predicted median line.
#' @examples
#' df <- data.frame(
#'   SubjectID = rep(1:5, each = 2),
#'   Time = rep(0:1, times = 5),
#'   DV = rnorm(10),
#'   WT = rnorm(10, 70, 5)
#' )
#' model <- fit_covariate_model(df, "DV", "SubjectID", "Time")
#' plot_vpc(model, df, bins = 2)
#' @export
plot_vpc <- function(model, data, bins = 10) {
  validate_data_frame_names(data)
  if (!all(c("Time", "DV") %in% names(data))) {
    stop("`data` must contain 'Time' and 'DV' columns")
  }

  validate_diagnostic_values(data$Time, nrow(data), "Time")
  validate_diagnostic_values(data$DV, nrow(data), "DV")
  if (!is_numeric_vector(bins) || length(bins) != 1L || !is.finite(bins) ||
    bins < 1 || bins != floor(bins) || bins >= .Machine$integer.max) {
    stop("`bins` must be a positive integer smaller than .Machine$integer.max")
  }
  if (length(unique(data$Time[!is.na(data$Time)])) < 2L) {
    stop("Unable to create VPC bins: 'Time' must contain at least 2 unique values")
  }
  predictions <- stats::predict(model, data)
  validate_diagnostic_values(predictions, nrow(data), "Predictions")
  data$pred <- as.numeric(predictions)

  bin_edges <- stats::quantile(
    data$Time,
    probs = seq(0, 1, length.out = bins + 1),
    na.rm = TRUE, type = 7
  )
  bin_edges <- unique(as.numeric(bin_edges))
  if (length(bin_edges) < 2) {
    stop(
      "Unable to create VPC bins: 'Time' must contain at least 2 unique values"
    )
  }
  data$bin <- cut(data$Time, breaks = bin_edges, include.lowest = TRUE)

  bins_mid <- tapply(data$Time, data$bin, mean)

  obs_p5 <- tapply(
    data$DV,
    data$bin,
    stats::quantile,
    probs = 0.05,
    na.rm = TRUE, type = 7
  )
  obs_med <- tapply(
    data$DV,
    data$bin,
    stats::quantile,
    probs = 0.5,
    na.rm = TRUE, type = 7
  )
  obs_p95 <- tapply(
    data$DV,
    data$bin,
    stats::quantile,
    probs = 0.95,
    na.rm = TRUE, type = 7
  )

  pred_med <- tapply(
    data$pred,
    data$bin,
    stats::quantile,
    probs = 0.5,
    na.rm = TRUE, type = 7
  )

  df <- data.frame(
    bin = as.numeric(bins_mid),
    obs_p5 = as.numeric(obs_p5),
    obs_med = as.numeric(obs_med),
    obs_p95 = as.numeric(obs_p95),
    pred_med = as.numeric(pred_med)
  )

  ggplot2::ggplot(df, ggplot2::aes(x = bin)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = obs_p5, ymax = obs_p95),
      fill = "grey80"
    ) +
    ggplot2::geom_line(ggplot2::aes(y = obs_med), colour = "black") +
    ggplot2::geom_line(ggplot2::aes(y = pred_med), colour = "blue") +
    ggplot2::labs(x = "Time", y = "DV") +
    ggplot2::theme_minimal()
}

# Shared shape checks prevent data.frame assignment from recycling predictions.
validate_diagnostic_values <- function(values, n, label) {
  if (!is_numeric_vector(values) || length(values) != n || any(is.infinite(values))) {
    stop(sprintf(
      "%s must be a real numeric vector with one value per data row, finite or missing",
      label
    ))
  }
  invisible(TRUE)
}
