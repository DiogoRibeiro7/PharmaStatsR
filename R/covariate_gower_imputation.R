prepare_gower_predictors <- function(data) {
  lapply(data, function(column) {
    if (is.ordered(column)) {
      column <- as.numeric(column)
    }
    if (!is.numeric(column)) {
      return(as.character(column))
    }
    # Calculate integer ranges in double precision to avoid integer overflow.
    column <- as.numeric(column)
    observed <- column[!is.na(column)]
    if (length(observed) == 0L) {
      return(column)
    }
    limits <- range(observed)
    span <- limits[2L] - limits[1L]
    if (span == 0) {
      column[!is.na(column)] <- 0
      return(column)
    }
    if (!is.finite(span)) {
      # Halving first keeps the range of finite extreme values representable.
      column <- column / 2
      limits <- limits / 2
      span <- limits[2L] - limits[1L]
    }
    (column - limits[1L]) / span
  })
}

gower_imputation_distances <- function(predictors, donors, recipient,
                                       weights = rep(1, length(predictors))) {
  totals <- numeric(length(donors))
  weight_sums <- numeric(length(donors))
  scales <- numeric(length(donors))
  for (j in seq_along(predictors)) {
    if (weights[j] == 0) {
      next
    }
    column <- predictors[[j]]
    if (is.numeric(column)) {
      contribution <- abs(column[donors] - column[recipient])
    } else {
      contribution <- as.numeric(column[donors] != column[recipient])
    }
    observed <- !is.na(contribution)
    # Scale within each pair so large weights cannot overflow, while a tiny
    # weight still counts if it is the only jointly observed predictor.
    next_scale <- pmax(scales[observed], weights[j])
    previous <- scales[observed] / next_scale
    current <- weights[j] / next_scale
    totals[observed] <- totals[observed] * previous +
      contribution[observed] * current
    weight_sums[observed] <- weight_sums[observed] * previous + current
    scales[observed] <- next_scale
  }
  distances <- rep(NA_real_, length(donors))
  comparable <- weight_sums > 0
  distances[comparable] <- totals[comparable] / weight_sums[comparable]
  distances
}
