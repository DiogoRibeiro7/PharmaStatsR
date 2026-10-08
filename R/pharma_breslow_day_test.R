#' Breslow-Day test for homogeneity of stratified odds ratios
#'
#' Test whether stratum-specific 2-by-2 odds ratios are compatible with a
#' common odds ratio across strata.
#'
#' @param x A numeric 2-by-2-by-K array of nonnegative whole-number counts,
#'   with K >= 2. Rows define the two exposure or treatment groups, columns
#'   define the two outcome levels, and the third dimension defines strata.
#' @param tarone Logical; apply Tarone's adjustment to the Breslow-Day
#'   statistic. Defaults to `FALSE` to preserve the unadjusted test.
#'
#' @return An object of class `htest` containing the selected homogeneity
#'   statistic, degrees of freedom, p-value, Mantel-Haenszel common odds ratio,
#'   fitted upper-left counts, stratum variances, the unadjusted Breslow-Day
#'   statistic, and the Tarone correction.
#' @details
#' The common odds ratio is estimated with the Mantel-Haenszel cross-product
#' estimator. Within each stratum, the fitted upper-left count is the unique
#' count compatible with the fixed margins and that common odds ratio. The
#' unadjusted statistic sums squared observed-minus-fitted deviations divided
#' by the large-sample conditional variance. With `tarone = TRUE`, Tarone's
#' correction subtracts the squared sum of observed-minus-fitted deviations
#' divided by the sum of their variances.
#' @export
#'
#' @examples
#' x <- array(0, dim = c(2, 2, 2))
#' x[, , 1] <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
#' x[, , 2] <- matrix(c(2, 8, 8, 2), 2, byrow = TRUE)
#' pharma_breslow_day_test(x)
#' pharma_breslow_day_test(x, tarone = TRUE)
pharma_breslow_day_test <- function(x, tarone = FALSE) {
  if (!is.array(x) || length(dim(x)) != 3L ||
      !identical(as.integer(dim(x)[1:2]), c(2L, 2L)) ||
      dim(x)[3L] < 2L) {
    stop("x must be a numeric 2-by-2-by-K array with K >= 2", call. = FALSE)
  }
  if (!is.numeric(x) || anyNA(x) || !all(is.finite(x)) ||
      any(x < 0) || any(x != floor(x))) {
    stop(
      "x must contain finite nonnegative whole-number counts",
      call. = FALSE
    )
  }
  if (!is.logical(tarone) || length(tarone) != 1L || is.na(tarone)) {
    stop("tarone must be one non-missing logical value", call. = FALSE)
  }

  k <- dim(x)[3L]
  mh_num <- mh_den <- numeric(k)

  for (s in seq_len(k)) {
    tab <- x[, , s, drop = TRUE]
    if (sum(tab) == 0 ||
        any(rowSums(tab) == 0) || any(colSums(tab) == 0)) {
      stop(
        "Each stratum must have positive total, row margins, and column margins",
        call. = FALSE
      )
    }

    n <- sum(tab)
    mh_num[s] <- tab[1, 1] * tab[2, 2] / n
    mh_den[s] <- tab[1, 2] * tab[2, 1] / n
  }

  common_or <- sum(mh_num) / sum(mh_den)
  if (!is.finite(common_or) || common_or <= 0) {
    stop(
      "The Mantel-Haenszel common odds ratio must be finite and positive",
      call. = FALSE
    )
  }

  fitted <- variance <- contributions <- differences <- numeric(k)

  for (s in seq_len(k)) {
    tab <- x[, , s, drop = TRUE]
    n <- sum(tab)
    r1 <- sum(tab[1, ])
    c1 <- sum(tab[, 1])

    lower <- max(0, r1 + c1 - n)
    upper <- min(r1, c1)

    score <- function(a) {
      b <- r1 - a
      c <- c1 - a
      d <- n - r1 - c1 + a
      a * d - common_or * b * c
    }

    f_lower <- score(lower)
    f_upper <- score(upper)

    if (abs(f_lower) <= sqrt(.Machine$double.eps)) {
      a_hat <- lower
    } else if (abs(f_upper) <= sqrt(.Machine$double.eps)) {
      a_hat <- upper
    } else {
      a_hat <- stats::uniroot(
        score,
        interval = c(lower, upper),
        tol = .Machine$double.eps^0.5
      )$root
    }

    b_hat <- r1 - a_hat
    c_hat <- c1 - a_hat
    d_hat <- n - r1 - c1 + a_hat

    if (any(c(a_hat, b_hat, c_hat, d_hat) <= 0)) {
      stop(
        "Breslow-Day variance is undefined for a fitted boundary table",
        call. = FALSE
      )
    }

    var_hat <- 1 / (
      1 / a_hat + 1 / b_hat + 1 / c_hat + 1 / d_hat
    )
    difference <- tab[1, 1] - a_hat

    fitted[s] <- a_hat
    variance[s] <- var_hat
    differences[s] <- difference
    contributions[s] <- difference^2 / var_hat
  }

  unadjusted <- sum(contributions)
  tarone_correction <- sum(differences)^2 / sum(variance)
  statistic <- if (tarone) unadjusted - tarone_correction else unadjusted

  if (statistic < 0 && abs(statistic) < sqrt(.Machine$double.eps)) {
    statistic <- 0
  }
  if (!is.finite(statistic) || statistic < 0) {
    stop("Adjusted Breslow-Day statistic is undefined", call. = FALSE)
  }

  df <- k - 1L
  p_value <- stats::pchisq(statistic, df = df, lower.tail = FALSE)
  statistic_name <- if (tarone) {
    "Tarone-adjusted Breslow-Day chi-squared"
  } else {
    "Breslow-Day chi-squared"
  }

  structure(
    list(
      statistic = stats::setNames(statistic, statistic_name),
      parameter = c(df = df),
      p.value = p_value,
      method = if (tarone) {
        "Tarone-adjusted Breslow-Day test for homogeneity of odds ratios"
      } else {
        "Breslow-Day test for homogeneity of odds ratios"
      },
      data.name = deparse(substitute(x)),
      common.odds.ratio = common_or,
      fitted.upper.left = fitted,
      stratum.variance = variance,
      stratum.difference = differences,
      stratum.contributions = contributions,
      unadjusted.statistic = unadjusted,
      tarone.correction = tarone_correction,
      tarone = tarone
    ),
    class = "htest"
  )
}
