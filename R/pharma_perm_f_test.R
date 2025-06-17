#' Permutation-based F-test
#'
#' Conduct a permutation-based F-test for linear models, useful for complex designs where standard assumptions may not hold.
#'
#' The test permutes the response vector to compute an empirical distribution of the F statistic.
#'
#' @param formula Model formula specifying the linear model.
#' @param data Data frame containing the variables in the model.
#' @param R Number of permutations.
#' @param ... Additional arguments passed to \code{stats::lm}.
#'
#' @return A list with the observed F statistic, the permutation distribution and the p-value.
#' @export
#'
#' @examples
#' pharma_perm_f_test(response ~ treatment * period, data = pharma_crossover, R = 50)
pharma_perm_f_test <- function(formula, data, R = 1000, ...) {
  model <- stats::lm(formula, data = data, ...)
  an <- stats::anova(model)
  f_col <- grep("^F", names(an), value = TRUE)
  if (length(f_col) == 0) {
    stop("Model must produce an F statistic")
  }
  obs <- an[[f_col]][1]
  if (is.na(obs)) {
    stop("F statistic could not be computed")
  }
  response_var <- all.vars(formula)[1]
  perm_stats <- numeric(R)
  for (i in seq_len(R)) {
    perm_data <- data
    perm_data[[response_var]] <- sample(perm_data[[response_var]])
    perm_mod <- stats::lm(formula, data = perm_data, ...)
    perm_an <- stats::anova(perm_mod)
    perm_stats[i] <- perm_an$"F"[1]
  }
  p_val <- mean(c(obs, perm_stats) >= obs)
  list(statistic = obs, perm = perm_stats, p.value = p_val)
}
