#' McNemar test for paired binary counts
#'
#' Test marginal homogeneity in a paired 2-by-2 binary table using the two
#' discordant cells. Returns the usual chi-square approximation and a
#' two-sided exact binomial p-value.
#'
#' @param x A numeric 2-by-2 matrix or table of nonnegative whole-number paired
#'   counts. Rows represent the first condition and columns the second.
#' @param correct Logical; apply the continuity correction to the asymptotic
#'   chi-square statistic.
#'
#' @return An object of class `htest` with the asymptotic statistic and
#'   `p.value`, plus `exact.p.value`, `discordant`, and
#'   `n.discordant`.
#' @details
#' Only the off-diagonal counts matter. With `b = x[1, 2]` and
#' `c = x[2, 1]`, the uncorrected statistic is
#' `(b - c)^2 / (b + c)`. The continuity-corrected version replaces the
#' numerator by `(abs(b - c) - 1)^2` when discordant pairs exist.
#' The exact two-sided p-value doubles the smaller binomial tail under
#' `Binomial(b + c, 0.5)`, capped at one. With no discordant pairs, both
#' p-values are one and the statistic is zero.
#' @export
#'
#' @examples
#' tab <- matrix(c(30, 12, 4, 24), nrow = 2, byrow = TRUE)
#' pharma_mcnemar_test(tab)
pharma_mcnemar_test <- function(x, correct = TRUE) {
  if (!(is.matrix(x) || inherits(x, "table")) ||
      !identical(as.integer(dim(x)), c(2L, 2L))) {
    stop("x must be a numeric 2-by-2 matrix or table", call. = FALSE)
  }
  x <- as.matrix(x)
  if (!is.numeric(x) || anyNA(x) || !all(is.finite(x)) ||
      any(x < 0) || any(x != floor(x))) {
    stop("x must contain finite nonnegative whole-number counts",
         call. = FALSE)
  }
  if (!is.logical(correct) || length(correct) != 1L || is.na(correct)) {
    stop("correct must be one non-missing logical value", call. = FALSE)
  }

  b <- unname(x[1L, 2L])
  c <- unname(x[2L, 1L])
  n_discordant <- b + c

  if (n_discordant == 0) {
    statistic <- 0
    asymptotic_p <- 1
    exact_p <- 1
  } else {
    difference <- abs(b - c)
    numerator <- if (correct) {
      max(difference - 1, 0)^2
    } else {
      difference^2
    }
    statistic <- numerator / n_discordant
    asymptotic_p <- stats::pchisq(
      statistic,
      df = 1,
      lower.tail = FALSE
    )
    exact_p <- min(
      1,
      2 * stats::pbinom(min(b, c), size = n_discordant, prob = 0.5)
    )
  }

  structure(
    list(
      statistic = c("McNemar's chi-squared" = statistic),
      parameter = c(df = 1),
      p.value = asymptotic_p,
      exact.p.value = exact_p,
      discordant = c(row1_col2 = b, row2_col1 = c),
      n.discordant = n_discordant,
      method = if (correct) {
        "McNemar's chi-squared test with continuity correction"
      } else {
        "McNemar's chi-squared test"
      },
      data.name = deparse(substitute(x))
    ),
    class = "htest"
  )
}
