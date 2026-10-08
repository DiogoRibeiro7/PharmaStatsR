#' Bowker test of symmetry for paired categorical tables
#'
#' Test symmetry of off-diagonal paired-category counts in a square
#' contingency table.
#'
#' @param x A numeric K-by-K matrix or table of nonnegative whole-number counts,
#'   with K >= 2.
#' @return An object of class `htest` containing Bowker's chi-square statistic
#'   and the effective degrees of freedom from informative off-diagonal pairs.
#' @details
#' For each unordered category pair `i < j`, the contribution is
#' `(x[i,j] - x[j,i])^2 / (x[i,j] + x[j,i])` when the denominator is
#' positive. Pairs with zero counts in both directions do not contribute a
#' degree of freedom.
#' @export
pharma_bowker_test <- function(x) {
  data_name <- deparse(substitute(x))
  if (!(is.matrix(x) || inherits(x, "table")) || length(dim(x)) != 2L ||
      nrow(x) != ncol(x) || nrow(x) < 2L) {
    stop("x must be a square K-by-K matrix or table with K >= 2", call. = FALSE)
  }

  x <- as.matrix(x)
  if (!is.numeric(x) || anyNA(x) || !all(is.finite(x)) ||
      any(x < 0) || any(x != floor(x))) {
    stop("x must contain finite nonnegative whole-number counts", call. = FALSE)
  }
  if (sum(x) == 0) {
    stop("x must contain at least one paired observation", call. = FALSE)
  }

  k <- nrow(x)
  contributions <- numeric()
  labels <- character()

  for (i in seq_len(k - 1L)) {
    for (j in (i + 1L):k) {
      denominator <- x[i, j] + x[j, i]
      if (denominator > 0) {
        contributions <- c(
          contributions,
          (x[i, j] - x[j, i])^2 / denominator
        )
        labels <- c(labels, paste0(i, ":", j))
      }
    }
  }

  if (length(contributions) == 0L) {
    stop(
      "At least one off-diagonal category pair must contain an observation",
      call. = FALSE
    )
  }

  names(contributions) <- labels
  statistic <- sum(contributions)
  df <- length(contributions)
  p_value <- stats::pchisq(statistic, df = df, lower.tail = FALSE)

  structure(
    list(
      statistic = c("Bowker chi-squared" = statistic),
      parameter = c(df = df),
      p.value = p_value,
      method = "Bowker test of symmetry",
      data.name = data_name,
      pair.contributions = contributions
    ),
    class = "htest"
  )
}
