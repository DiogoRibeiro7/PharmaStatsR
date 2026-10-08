#' Woolf test for homogeneity of stratified odds ratios
#'
#' Test whether stratum-specific 2-by-2 odds ratios are homogeneous on the
#' log-odds-ratio scale using inverse-variance weighting.
#'
#' @param x A numeric 2-by-2-by-K array of strictly positive whole-number
#'   counts, with K >= 2.
#'
#' @return An object of class `htest` containing Woolf's chi-square statistic,
#'   degrees of freedom, p-value, stratum log odds ratios, variances, weights,
#'   pooled log odds ratio, and pooled odds ratio.
#' @export
pharma_woolf_test <- function(x) {
  if (!is.array(x) || length(dim(x)) != 3L ||
      !identical(as.integer(dim(x)[1:2]), c(2L, 2L)) ||
      dim(x)[3L] < 2L) {
    stop("x must be a numeric 2-by-2-by-K array with K >= 2", call. = FALSE)
  }
  if (!is.numeric(x) || anyNA(x) || !all(is.finite(x)) ||
      any(x <= 0) || any(x != floor(x))) {
    stop(
      "x must contain finite strictly positive whole-number counts",
      call. = FALSE
    )
  }

  k <- dim(x)[3L]
  log_or <- variance <- weight <- numeric(k)

  for (s in seq_len(k)) {
    tab <- x[, , s, drop = TRUE]
    a <- tab[1, 1]
    b <- tab[1, 2]
    c <- tab[2, 1]
    d <- tab[2, 2]

    log_or[s] <- log(a * d / (b * c))
    variance[s] <- 1 / a + 1 / b + 1 / c + 1 / d
    weight[s] <- 1 / variance[s]
  }

  pooled_log_or <- sum(weight * log_or) / sum(weight)
  contributions <- weight * (log_or - pooled_log_or)^2
  statistic <- sum(contributions)
  df <- k - 1L
  p_value <- stats::pchisq(statistic, df = df, lower.tail = FALSE)

  structure(
    list(
      statistic = c("Woolf chi-squared" = statistic),
      parameter = c(df = df),
      p.value = p_value,
      method = "Woolf test for homogeneity of odds ratios",
      data.name = deparse(substitute(x)),
      stratum.log.odds.ratio = log_or,
      stratum.variance = variance,
      stratum.weight = weight,
      pooled.log.odds.ratio = pooled_log_or,
      pooled.odds.ratio = exp(pooled_log_or),
      stratum.contributions = contributions
    ),
    class = "htest"
  )
}
