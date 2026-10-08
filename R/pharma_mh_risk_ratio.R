#' Mantel-Haenszel common risk ratio for stratified cohorts
#'
#' Estimate a common cohort-style risk ratio across 2-by-2 strata using the
#' Mantel-Haenszel estimator and Greenland-Robins log-scale variance.
#'
#' @param x A numeric 2-by-2-by-K array of nonnegative whole-number counts.
#'   Rows define the two exposure or treatment groups, column 1 is the event,
#'   column 2 is the non-event, and the third dimension defines strata.
#' @param conf.level Confidence level for the Wald interval.
#'
#' @return An object of class `htest` containing the common risk ratio,
#'   log-scale standard error, Wald confidence interval, z statistic,
#'   two-sided p-value, and stratum R/S/T components.
#' @export
pharma_mh_risk_ratio <- function(x, conf.level = 0.95) {
  if (!is.array(x) || length(dim(x)) != 3L ||
      !identical(as.integer(dim(x)[1:2]), c(2L, 2L)) ||
      dim(x)[3L] < 1L) {
    stop("x must be a numeric 2-by-2-by-K array", call. = FALSE)
  }
  if (!is.numeric(x) || anyNA(x) || !all(is.finite(x)) ||
      any(x < 0) || any(x != floor(x))) {
    stop("x must contain finite nonnegative whole-number counts", call. = FALSE)
  }
  if (!is.numeric(conf.level) || length(conf.level) != 1L ||
      is.na(conf.level) || !is.finite(conf.level) ||
      conf.level <= 0 || conf.level >= 1) {
    stop("conf.level must be one finite number strictly between 0 and 1", call. = FALSE)
  }

  k <- dim(x)[3L]
  r_comp <- s_comp <- t_comp <- numeric(k)

  for (s in seq_len(k)) {
    tab <- x[, , s, drop = TRUE]
    if (sum(tab) == 0 || any(rowSums(tab) == 0)) {
      stop("Each stratum must have positive total and row margins", call. = FALSE)
    }

    a <- tab[1, 1]
    b <- tab[1, 2]
    c <- tab[2, 1]
    d <- tab[2, 2]

    r1 <- a + b
    r2 <- c + d
    n <- r1 + r2
    m1 <- a + c

    r_comp[s] <- a * r2 / n
    s_comp[s] <- c * r1 / n
    t_comp[s] <- (r1 * r2 * m1 - a * c * n) / n^2
  }

  sum_r <- sum(r_comp)
  sum_s <- sum(s_comp)
  if (sum_r <= 0 || sum_s <= 0) {
    stop(
      "The Mantel-Haenszel risk ratio is undefined when either weighted event total is zero",
      call. = FALSE
    )
  }

  estimate <- sum_r / sum_s
  var_log <- sum(t_comp) / (sum_r * sum_s)
  if (!is.finite(var_log) || var_log <= 0) {
    stop("The log risk-ratio variance is undefined", call. = FALSE)
  }

  se_log <- sqrt(var_log)
  z <- log(estimate) / se_log
  p_value <- 2 * stats::pnorm(-abs(z))
  z_alpha <- stats::qnorm(1 - (1 - conf.level) / 2)
  conf_int <- exp(log(estimate) + c(-1, 1) * z_alpha * se_log)
  attr(conf_int, "conf.level") <- conf.level

  structure(
    list(
      statistic = c(Z = z),
      parameter = NULL,
      p.value = p_value,
      estimate = c("common risk ratio" = estimate),
      conf.int = conf_int,
      null.value = c("risk ratio" = 1),
      alternative = "two.sided",
      method = "Mantel-Haenszel common risk ratio",
      data.name = deparse(substitute(x)),
      log.standard.error = se_log,
      log.variance = var_log,
      r.components = r_comp,
      s.components = s_comp,
      t.components = t_comp
    ),
    class = "htest"
  )
}
