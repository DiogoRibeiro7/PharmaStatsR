#' Cochran Q test for repeated binary outcomes
#'
#' Compare marginal binary response rates across two or more matched conditions.
#'
#' @param x A subject-by-condition matrix or data frame containing only 0/1
#'   values and no missingness. Rows are matched subjects and columns are
#'   repeated conditions.
#' @return An object of class `htest` with Cochran's Q statistic.
#' @export
pharma_cochran_q_test <- function(x) {
  data_name <- deparse(substitute(x))
  if (is.data.frame(x)) x <- as.matrix(x)
  if (!is.matrix(x) || nrow(x) < 1L || ncol(x) < 2L) {
    stop("x must be a subject-by-condition matrix or data frame with at least two conditions", call. = FALSE)
  }
  if (!(is.numeric(x) || is.logical(x)) || anyNA(x) ||
      !all(is.finite(x)) || any(!(x %in% c(0, 1)))) {
    stop("x must contain only complete binary 0/1 values", call. = FALSE)
  }
  x <- matrix(as.numeric(x), nrow = nrow(x), ncol = ncol(x), dimnames = dimnames(x))
  k <- ncol(x)
  condition_totals <- colSums(x)
  subject_totals <- rowSums(x)
  total <- sum(condition_totals)
  denominator <- k * total - sum(subject_totals^2)
  numerator <- (k - 1) * (k * sum(condition_totals^2) - total^2)
  if (denominator == 0) {
    statistic <- 0
    p_value <- 1
  } else {
    statistic <- numerator / denominator
    p_value <- stats::pchisq(statistic, df = k - 1, lower.tail = FALSE)
  }
  structure(
    list(
      statistic = c("Cochran's Q" = statistic),
      parameter = c(df = k - 1),
      p.value = p_value,
      method = "Cochran's Q test",
      data.name = data_name,
      condition.totals = condition_totals,
      subject.totals = subject_totals
    ),
    class = "htest"
  )
}
