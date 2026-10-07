#' Cochran-Mantel-Haenszel test for stratified 2-by-2 tables
#'
#' Test conditional association across strata and estimate the common
#' Mantel-Haenszel odds ratio for a 2-by-2-by-K array of counts.
#'
#' @param x A numeric 2-by-2-by-K array of nonnegative whole-number counts.
#'   Rows define the two exposure or treatment groups, columns define the two
#'   outcome levels, and the third dimension defines strata.
#' @param correct Logical; apply the continuity correction to the CMH statistic.
#' @param conf.level Confidence level for the common odds-ratio interval.
#'
#' @return An object of class `htest` returned by `stats::mantelhaen.test()`.
#' @details
#' Every stratum must have positive row and column margins so it contributes
#' conditional information. The common odds ratio compares row 1 versus row 2
#' for column 1 versus column 2. Swapping either pair reverses the odds ratio.
#' A common-odds-ratio summary requires a substantively meaningful shared
#' effect across strata; this helper does not test effect homogeneity.
#' @export
#'
#' @examples
#' tab <- array(0, dim = c(2, 2, 3))
#' tab[, , 1] <- matrix(c(12, 8, 5, 15), 2, byrow = TRUE)
#' tab[, , 2] <- matrix(c(20, 10, 10, 20), 2, byrow = TRUE)
#' tab[, , 3] <- matrix(c(8, 12, 4, 16), 2, byrow = TRUE)
#' pharma_cmh_test(tab, correct = FALSE)
pharma_cmh_test <- function(x, correct = TRUE, conf.level = 0.95) {
  if (!is.array(x) || length(dim(x)) != 3L ||
      !identical(as.integer(dim(x)[1:2]), c(2L, 2L)) ||
      dim(x)[3L] < 1L) {
    stop("x must be a numeric 2-by-2-by-K array", call. = FALSE)
  }
  if (!is.numeric(x) || anyNA(x) || !all(is.finite(x)) ||
      any(x < 0) || any(x != floor(x))) {
    stop("x must contain finite nonnegative whole-number counts",
         call. = FALSE)
  }
  if (!is.logical(correct) || length(correct) != 1L || is.na(correct)) {
    stop("correct must be one non-missing logical value", call. = FALSE)
  }
  if (!is.numeric(conf.level) || length(conf.level) != 1L ||
      is.na(conf.level) || !is.finite(conf.level) ||
      conf.level <= 0 || conf.level >= 1) {
    stop("conf.level must be one finite number strictly between 0 and 1",
         call. = FALSE)
  }

  for (k in seq_len(dim(x)[3L])) {
    tab <- x[, , k, drop = TRUE]
    if (sum(tab) == 0 ||
        any(rowSums(tab) == 0) || any(colSums(tab) == 0)) {
      stop(
        "Each stratum must have positive total, row margins, and column margins",
        call. = FALSE
      )
    }
  }

  stats::mantelhaen.test(
    x,
    correct = correct,
    conf.level = conf.level
  )
}
