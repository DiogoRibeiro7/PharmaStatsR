#' Fisher exact test for a 2-by-2 count table
#'
#' Perform an exact conditional test for a 2-by-2 table and return the
#' conditional maximum-likelihood odds-ratio estimate and confidence interval
#' from `stats::fisher.test()`.
#'
#' @param x A numeric 2-by-2 matrix or table of nonnegative whole-number counts.
#'   Rows define the two treatment/exposure groups and columns the two binary
#'   outcome levels.
#' @param alternative Character string: `"two.sided"`, `"less"`, or
#'   `"greater"`.
#' @param conf.level Confidence level for the odds-ratio interval.
#'
#' @return An object of class `htest` returned by `stats::fisher.test()`.
#' @details
#' Row 1 versus row 2 and column 1 versus column 2 define the odds-ratio
#' orientation. Swapping either pair reverses the odds ratio. Every row and
#' column margin must be positive. Zero cells are allowed.
#'
#' The odds-ratio estimate returned by `stats::fisher.test()` is the
#' conditional maximum-likelihood estimate, not necessarily the raw
#' cross-product ratio `x[1,1] * x[2,2] / (x[1,2] * x[2,1])`.
#' @export
#'
#' @examples
#' tab <- matrix(c(1, 9, 11, 3), 2, byrow = TRUE)
#' pharma_fisher_test(tab)
pharma_fisher_test <- function(
    x,
    alternative = c("two.sided", "less", "greater"),
    conf.level = 0.95) {
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
  if (sum(x) == 0 || any(rowSums(x) == 0) || any(colSums(x) == 0)) {
    stop("x must have positive total, row margins, and column margins",
         call. = FALSE)
  }

  alternative <- match.arg(alternative)

  if (!is.numeric(conf.level) || length(conf.level) != 1L ||
      is.na(conf.level) || !is.finite(conf.level) ||
      conf.level <= 0 || conf.level >= 1) {
    stop("conf.level must be one finite number strictly between 0 and 1",
         call. = FALSE)
  }

  stats::fisher.test(
    x,
    alternative = alternative,
    conf.level = conf.level
  )
}
