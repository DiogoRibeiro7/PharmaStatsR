#' Center and scale covariates
#'
#' Applies mean centering and standard deviation scaling to the specified
#' numeric variables in a data frame. The function returns the transformed
#' data along with the parameters used for each variable.
#' Missing values (`NA` or `NaN`) are omitted when estimating the parameters
#' and remain missing in the result. Each selected variable must have at least
#' two observed values, a finite mean, and a finite, positive sample standard
#' deviation. Constant columns and infinite values are rejected.
#' The sample standard deviation uses the observed count minus one. If its
#' direct computation is zero or non-finite, normalized intermediate values
#' are used to avoid variance underflow/overflow where the final standard
#' deviation is representable. A non-finite direct mean is recomputed after
#' normalizing the original values. Ordinary finite estimates are unchanged.
#' Centering precedes normalization when possible, preserving small differences
#' at large offsets. Transformation uses the same arithmetic as
#' [apply_center_scale()], including its overflow-safe subtraction fallback.
#' Floating-point precision still limits the estimated mean, spread and output;
#' differences already lost in the input cannot be recovered.
#'
#' To reuse these parameters for new data without refitting, pass the returned
#' \code{params} to \code{\link{apply_center_scale}}.
#'
#' @param data A `data.frame` containing the variables to transform.
#' @param vars Character vector of unique numeric column names to transform.
#'
#' @return A list with two elements: `data`, the transformed data frame, and
#'   `params`, a data frame with columns `var`, `mean`, and `sd` describing the
#'   transformation parameters for each variable.
#' @examples
#' df <- data.frame(wt = c(60, 70, 80))
#' res <- center_scale(df, "wt")
#' res$data
#' res$params
#' @seealso \code{\link{apply_center_scale}}
#' @export
center_scale <- function(data, vars) {
  validate_preprocessing_vars(data, vars)

  params <- data.frame(
    var = character(), mean = numeric(), sd = numeric(),
    stringsAsFactors = FALSE
  )

  for (v in vars) {
    column <- data[[v]]
    if (sum(!is.na(column)) < 2L) {
      stop(sprintf(
        "Variable '%s' needs at least two observed values for scaling", v
      ))
    }
    col_mean <- mean(column, na.rm = TRUE)
    if (!is.finite(col_mean)) {
      # Mean correction can overflow on platforms without wider accumulators.
      magnitude <- max(abs(column), na.rm = TRUE)
      col_mean <- magnitude * mean(column / magnitude, na.rm = TRUE)
    }
    col_sd <- scaling_sample_sd(column, col_mean)
    if (!is.finite(col_mean) || !is.finite(col_sd) || col_sd <= 0) {
      stop(sprintf(
        paste0(
          "Variable '%s' needs a finite mean and a positive, finite ",
          "standard deviation for scaling"
        ),
        v
      ))
    }
    params <- rbind(params, data.frame(var = v, mean = col_mean, sd = col_sd))
  }

  list(data = apply_center_scale(data, params), params = params)
}

# Keep ordinary results; normalize only when direct variance arithmetic fails.
scaling_sample_sd <- function(column, center) {
  spread <- stats::sd(column, na.rm = TRUE)
  if (is.finite(spread) && spread > 0) {
    return(spread)
  }
  if (!is.finite(center)) {
    return(spread)
  }

  observed <- column[!is.na(column)]
  deviations <- observed - center
  # Opposite-sign extremes can overflow subtraction. Scaling the original
  # values is then safe; otherwise centered differences retain more precision.
  values <- if (any(!is.finite(deviations))) observed else deviations
  magnitude <- max(abs(values))
  if (magnitude == 0) {
    return(spread)
  }
  magnitude * stats::sd(values / magnitude)
}
