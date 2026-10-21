# Preserve finite base estimates; normalize only after arithmetic failure.
# Callers validate real numeric inputs and define their own all-missing policy.
preprocessing_mean <- function(x, na.rm = FALSE) {
  value <- mean(x, na.rm = na.rm)
  if (is.finite(value)) {
    return(value)
  }
  observed <- if (na.rm) x[!is.na(x)] else x
  if (length(observed) == 0L || any(!is.finite(observed))) {
    return(value)
  }
  magnitude <- max(abs(observed))
  magnitude * mean(observed / magnitude)
}
