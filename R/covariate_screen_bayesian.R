#' Select covariates via approximate Bayesian model evidence
#'
#' Uses a BIC-based approximation to Bayes factors for covariate selection.
#' For each candidate covariate, compares a univariate model against an
#' intercept-only model and returns covariates whose approximate Bayes factor
#' meets a threshold. Each comparison uses ordinary linear regression on the
#' same complete-case rows; it does not account for repeated measurements or
#' adjust for the other candidate covariates.
#'
#' The response must be a real numeric vector; candidates may be real numeric,
#' logical, character, or factor vectors. At least three complete-case rows are
#' required. Infinite numeric values and constant variables on retained rows
#' are rejected. Unused factor levels are dropped before fitting.
#' Column names are interpreted literally, including spaces or formula
#' operators. Duplicate column names, duplicate candidates, and using the
#' response as a candidate are rejected. An empty candidate selection returns
#' `character(0)` without fitting.
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
  null_bic <- stats::BIC(null_model)

  selected <- character(0)
  for (i in seq_along(covariates)) {
    alt_formula <- stats::reformulate(
      names(data)[i + 1L],
      response = ".screen_response"
    )
    alt_model <- stats::lm(alt_formula, data = data)
    alt_bic <- stats::BIC(alt_model)

    # BIC approximation: log(BF10) <U+2248> (BIC0 - BIC1) / 2
    # Compare on the log scale so strong evidence cannot overflow exp().
    log_bf10 <- (null_bic - alt_bic) / 2
    if (!is.na(log_bf10) && log_bf10 >= log(min_bf)) {
      selected <- c(selected, covariates[i])
    }
  }

  unname(selected)
}
