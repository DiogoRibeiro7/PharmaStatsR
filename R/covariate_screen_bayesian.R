#' Select covariates via approximate Bayesian model evidence
#'
#' Uses a BIC-based approximation to Bayes factors for covariate selection.
#' For each candidate covariate, compares a univariate model against an
#' intercept-only model and returns covariates whose approximate Bayes factor
#' meets a threshold. Each comparison uses ordinary linear regression on the
#' same complete-case rows; it does not account for repeated measurements or
#' adjust for the other candidate covariates.
#'
#' For Gaussian models on the same \eqn{n} rows, the score is
#' \eqn{\log(BF_{10}) = [n\log(RSS_0/RSS_1) - (p_1-p_0)\log(n)]/2},
#' where \eqn{RSS} is residual sum of squares and \eqn{p} is the fitted
#' regression rank, including the intercept. A categorical candidate is one
#' whole term, with a penalty for its additional fitted coefficients. The
#' threshold is \code{min_bf} (\eqn{t}), and the comparison is inclusive: \eqn{\log(BF_{10}) \ge \log(t)}.
#' This is an asymptotic BIC approximation, not an exact Bayes factor or a
#' posterior inclusion probability. It assumes independent Gaussian errors
#' with constant variance; repeated measurements are treated as independent.
#'
#' The response must be a real numeric vector; candidates may be real numeric,
#' logical, character, or factor vectors. At least three complete-case rows are
#' required. Infinite numeric values and constant variables on retained rows
#' are rejected. Unused factor levels are dropped before fitting.
#' Column names are interpreted literally, including spaces or formula
#' operators. Duplicate column names, duplicate candidates, and using the
#' response as a candidate are rejected. An empty candidate selection returns
#' `character(0)` without fitting.
#' Every fitted model must have positive residual degrees of freedom and a
#' finite BIC. Saturated categorical models and non-finite BIC values raise
#' an error naming the affected model; no partial selection is returned.
#' A non-finite BIC can indicate a zero residual variance or numerical
#' underflow/overflow: review exact fits and rescale extreme response units.
#' Finite near-perfect fits are not rejected by a near-zero variance cutoff.
#'
#' @param data A `data.frame` containing the response and covariates.
#' @param response Name of the response variable as a string.
#' @param covariates Character vector of unique covariate column names.
#' @param min_bf Finite, positive Bayes factor threshold. Default is `3`.
#'
#' @return Character vector of selected covariate names.
#' @examples
#' set.seed(123)
#' df <- data.frame(
#'   DV = rnorm(100),
#'   x1 = rnorm(100),
#'   x2 = rnorm(100)
#' )
#' screen_covariates_bayesian(df, "DV", c("x1", "x2"))
#' @export
screen_covariates_bayesian <- function(data, response, covariates, min_bf = 3) {
  if (!is_numeric_vector(min_bf) || length(min_bf) != 1L ||
    !is.finite(min_bf) || min_bf <= 0) {
    stop("`min_bf` must be a positive number and finite")
  }

  data <- prepare_screening_data(data, response, covariates)
  if (is.null(data)) {
    return(character(0))
  }

  null_formula <- stats::as.formula(".screen_response ~ 1")
  null_model <- stats::lm(null_formula, data = data)
  null_bic <- screening_finite_bic(null_model, "intercept-only model")

  selected <- character(0)
  for (i in seq_along(covariates)) {
    alt_formula <- stats::reformulate(
      names(data)[i + 1L],
      response = ".screen_response"
    )
    alt_model <- stats::lm(alt_formula, data = data)
    alt_bic <- screening_finite_bic(
      alt_model, sprintf("candidate '%s'", covariates[i])
    )

    # BIC approximation: log(BF10) <U+2248> (BIC0 - BIC1) / 2
    # Compare on the log scale so strong evidence cannot overflow exp().
    log_bf10 <- (null_bic - alt_bic) / 2
    if (log_bf10 >= log(min_bf)) {
      selected <- c(selected, covariates[i])
    }
  }

  unname(selected)
}

screening_finite_bic <- function(model, context) {
  if (stats::df.residual(model) <= 0L) {
    stop(sprintf(
      "BIC screening %s needs positive residual degrees of freedom", context
    ))
  }
  value <- stats::BIC(model)
  if (!is.finite(value)) {
    stop(sprintf(
      paste0(
        "BIC screening %s has a non-finite BIC; ",
        "review exact fits and rescale extreme response values"
      ),
      context
    ))
  }
  value
}
