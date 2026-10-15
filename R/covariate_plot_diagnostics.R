#' Observed vs. Predicted Plot
#'
#' Creates a scatter plot comparing observed responses to model predictions.
#'
#' @param model An object with a `predict` method.
#' @param data A `data.frame` containing the observed response column `DV`.
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
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame")
  }
  if (!"DV" %in% names(data)) {
    stop("`data` must contain 'DV' column")
  }

  preds <- stats::predict(model, data)

  ggplot2::ggplot(data, ggplot2::aes(x = preds, y = DV)) +
    ggplot2::geom_point() +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = "red") +
    ggplot2::labs(x = "Predicted", y = "Observed") +
    ggplot2::theme_minimal()
}

#' Residual Plots Over Time
#'
#' Generates raw and normalized residual plots over time for a fitted model.
#'
#' @param model A fitted model object from `nlme::lme` or similar.
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
  if (is.null(model$data) || !"Time" %in% names(model$data)) {
    stop("model$data must contain 'Time' column")
  }

  raw_res <- stats::residuals(model, type = "response")
  norm_res <- stats::residuals(model, type = "normalized")
  df_raw <- data.frame(Time = model$data$Time, Residual = raw_res, Type = "Raw")
  df_norm <- data.frame(
    Time = model$data$Time,
    Residual = norm_res,
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
#' @param model A fitted model with a `predict` method.
#' @param data A `data.frame` containing `Time` and `DV` columns.
#' @param bins Number of bins to divide the time variable into.
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
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame")
  }
  if (!all(c("Time", "DV") %in% names(data))) {
    stop("`data` must contain 'Time' and 'DV' columns")
  }

  data$pred <- stats::predict(model, data)

  bin_edges <- stats::quantile(
    data$Time,
    probs = seq(0, 1, length.out = bins + 1),
    na.rm = TRUE
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
    na.rm = TRUE
  )
  obs_med <- tapply(
    data$DV,
    data$bin,
    stats::quantile,
    probs = 0.5,
    na.rm = TRUE
  )
  obs_p95 <- tapply(
    data$DV,
    data$bin,
    stats::quantile,
    probs = 0.95,
    na.rm = TRUE
  )

  pred_med <- tapply(
    data$pred,
    data$bin,
    stats::quantile,
    probs = 0.5,
    na.rm = TRUE
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
