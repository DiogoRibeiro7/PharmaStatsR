#' Stuart-Maxwell test for marginal homogeneity
#'
#' Test marginal homogeneity in a paired square categorical table with three
#' or more categories.
#'
#' @param x A numeric K-by-K matrix or table of nonnegative whole-number counts,
#'   with K >= 3.
#' @return An object of class `htest` containing the Stuart-Maxwell statistic.
#' @export
pharma_stuart_maxwell_test <- function(x) {
  data_name <- deparse(substitute(x))
  if (!(is.matrix(x) || inherits(x,"table")) || length(dim(x)) != 2L ||
      nrow(x) != ncol(x) || nrow(x) < 3L) {
    stop("x must be a square K-by-K matrix or table with K >= 3", call. = FALSE)
  }
  x <- as.matrix(x)
  if (!is.numeric(x) || anyNA(x) || !all(is.finite(x)) ||
      any(x < 0) || any(x != floor(x))) {
    stop("x must contain finite nonnegative whole-number counts", call. = FALSE)
  }
  if (sum(x) == 0) stop("x must contain at least one paired observation", call. = FALSE)
  row_margins <- rowSums(x); col_margins <- colSums(x)
  if (any(row_margins + col_margins == 0)) {
    stop("Every category must appear in at least one row or column margin", call. = FALSE)
  }
  k <- nrow(x)
  differences <- row_margins - col_margins
  covariance <- matrix(0, k, k)
  for (i in seq_len(k)) covariance[i,i] <- row_margins[i] + col_margins[i] - 2*x[i,i]
  for (i in seq_len(k-1L)) {
    for (j in (i+1L):k) {
      covariance[i,j] <- -(x[i,j] + x[j,i]); covariance[j,i] <- covariance[i,j]
    }
  }
  keep <- seq_len(k-1L)
  d <- differences[keep]
  v <- covariance[keep,keep,drop=FALSE]
  if (qr(v)$rank < k-1L) stop("Stuart-Maxwell covariance matrix is singular for this table", call. = FALSE)
  statistic <- as.numeric(crossprod(d, solve(v, d)))
  if (abs(statistic) < sqrt(.Machine$double.eps)) statistic <- 0
  structure(
    list(
      statistic = c("Stuart-Maxwell chi-squared" = statistic),
      parameter = c(df = k-1L),
      p.value = stats::pchisq(statistic, df=k-1L, lower.tail=FALSE),
      method = "Stuart-Maxwell test for marginal homogeneity",
      data.name = data_name,
      marginal.differences = differences,
      covariance = covariance
    ),
    class = "htest"
  )
}
