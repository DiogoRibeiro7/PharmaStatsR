#' Apply saved centering and scaling parameters
#'
#' Transforms numeric columns using parameters previously estimated by
#' \code{\link{center_scale}}. No parameters are estimated from the new data.
#' Fit parameters on training data and reuse them for validation or future data.
#'
#' Each variable is transformed as \code{(x - mean) / sd}, matching parameter
#' rows to columns by their literal names. Missing values remain missing.
#' Empty, singleton, constant, and entirely missing new columns are allowed;
#' their means and standard deviations are not estimated again. Infinite input
#' values and unrepresentable transformed values raise an error.
#'
#' @param data A data frame containing the numeric variables to transform.
#' @param params A data frame with columns \code{var}, \code{mean}, and
#'   \code{sd}, such as the \code{params} returned by \code{center_scale()}.
#'   Variable names must be unique, nonmissing, nonempty character strings.
#'   Means must be finite real numbers, and standard deviations must be finite
#'   and strictly positive. Additional parameter columns are ignored. A valid
#'   zero-row parameter table leaves the data unchanged.
#'
#' @return A data frame with the selected columns transformed. Column order,
#'   row order, row names, and unselected columns are preserved.
#' @examples
#' training <- data.frame(WT = c(60, 70, 80))
#' fitted <- center_scale(training, "WT")
#' validation <- data.frame(WT = c(90, 100, NA))
#' apply_center_scale(validation, fitted$params)
#' @seealso \code{\link{center_scale}}, \code{\link[base]{scale}}
#' @export
apply_center_scale <- function(data, params) {
  validate_scaling_params(params)
  validate_preprocessing_vars(data, params$var)

  for (i in seq_len(nrow(params))) {
    variable <- params$var[i]
    column <- as.numeric(data[[variable]])
    center <- as.numeric(params$mean[i])
    spread <- as.numeric(params$sd[i])
    centered <- column - center
    transformed <- centered / spread
    # Opposite-sign extremes can overflow before division makes them finite.
    overflow <- which(is.infinite(centered))
    transformed[overflow] <- column[overflow] / spread - center / spread
    if (any(!is.finite(transformed) & !is.na(column))) {
      stop(sprintf(
        paste0(
          "Scaled values for '%s' cannot be represented; ",
          "rescale inputs and parameters"
        ),
        variable
      ))
    }
    data[[variable]] <- transformed
  }

  data
}

validate_scaling_params <- function(params) {
  if (!is.data.frame(params)) {
    stop("`params` must be a data.frame")
  }
  if (anyNA(names(params)) || any(names(params) == "") ||
    anyDuplicated(names(params))) {
    stop("`params` must have unique, nonmissing, nonempty column names")
  }
  if (!all(c("var", "mean", "sd") %in% names(params))) {
    stop("`params` must contain 'var', 'mean', and 'sd' columns")
  }
  variables <- params$var
  if (!is.character(variables) || !is.null(dim(variables)) ||
    anyNA(variables) || any(variables == "") || anyDuplicated(variables)) {
    stop(
      "`params$var` must contain unique, nonmissing, nonempty variable names"
    )
  }
  if (!is_numeric_vector(params$mean) || any(!is.finite(params$mean))) {
    stop("`params$mean` must contain finite real numbers")
  }
  if (!is_numeric_vector(params$sd) || any(!is.finite(params$sd)) ||
    any(params$sd <= 0)) {
    stop("`params$sd` must contain positive, finite real numbers")
  }
  invisible(TRUE)
}
