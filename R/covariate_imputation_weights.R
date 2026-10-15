prepare_imputation_weights <- function(weights, predictors) {
  result <- stats::setNames(rep(1, length(predictors)), predictors)
  if (is.null(weights)) {
    return(result)
  }
  if (!is_numeric_vector(weights) || any(!is.finite(weights)) ||
    any(weights < 0)) {
    stop("`weights` must be a numeric vector of finite, nonnegative values")
  }
  if (length(weights) == 0L) {
    return(result)
  }
  weight_names <- names(weights)
  if (is.null(weight_names) || anyNA(weight_names) ||
    any(weight_names == "") || anyDuplicated(weight_names)) {
    stop("`weights` must have unique, nonmissing, nonempty predictor names")
  }
  if (!all(weight_names %in% predictors)) {
    unknown <- setdiff(weight_names, predictors)
    stop(sprintf(
      "Weights refer to unselected predictors: %s",
      paste(unknown, collapse = ", ")
    ))
  }
  result[weight_names] <- weights
  result
}
