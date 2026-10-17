#' Simulate replicated responses from a covariate mixed model
#'
#' Draw complete response replicates under the Gaussian random-intercept model
#' fitted by [fit_covariate_model()]. Estimated fixed effects and variance
#' components are held fixed. Each replicate draws fresh subject intercepts and
#' independent residual errors, including for identifiers seen during fitting.
#' These are population replications, not predictions conditional on fitted
#' subject effects or simulations incorporating parameter uncertainty.
#'
#' @param object An intact native `lme` result from [fit_covariate_model()],
#'   including a saved/restored fit and its original-name mapping. Only a single
#'   random intercept with independent, constant-variance residuals is supported.
#'   Random slopes, nested groups, nonlinear fits, residual correlation, and
#'   residual variance weights are rejected.
#' @param newdata Data frame containing the original covariate and subject-ID
#'   columns. No response column is required. All selected values must be
#'   observed; numeric values must be finite. Covariate types and categorical
#'   levels follow [predict_covariate_model()]. IDs may be numeric, logical,
#'   character, or factor; only their grouping within `newdata` matters.
#' @param nsim Positive integer number of complete response replicates, default
#'   1000. At least two are needed for [plot_simulated_vpc()].
#'
#' @return A numeric matrix with one row per input row and `nsim` columns named
#'   `sim_1`, `sim_2`, etc. Nonempty input row names and row order are preserved.
#'   Its `simulation_parameters` attribute contains the named fixed-effect
#'   `mean` vector, `sd_subject`, and `sd_residual`, all on the response scale.
#'   Empty input returns a zero-row matrix without consuming random numbers.
#'   The fitted object and input data are not modified.
#' @details
#' For observation i in subject g and replicate r, the response is
#' `mean[i] + b[g, r] + e[i, r]`, where subject effects have variance
#' `sd_subject^2` and residuals have variance `sd_residual^2`. Distinct subject
#' effects, residuals, and replicates are independent. Rows with the same ID
#' share their subject draw, even when they are not adjacent. Random-intercept
#' variance is extracted at full precision with [nlme::getVarCov()].
#'
#' This helper consumes the current R random stream. Call `set.seed()` before
#' simulation to reproduce a run under the same R RNG settings. For each
#' replicate, draws occur first for subjects in order of first appearance,
#' then for residuals in input row order. Reordering or subsetting rows can
#' change the realized draws under the same seed. Invalid inputs are checked
#' before drawing; a numerical overflow during generation raises an error.
#'
#' New and previously fitted identifiers have the same simulation meaning:
#' fresh zero-mean random effects. This does not use fitted BLUPs, refit the
#' model, sample parameter uncertainty, or reproduce missingness, censoring,
#' dropout, or dosing events. Supply the intended observation schedule and
#' select any complete-case cohort explicitly. Use [plot_simulated_vpc()] to
#' compare the resulting replicate percentiles with observed responses. This
#' is an experimental model-specific simulator, not a model validation test.
#' @examples
#' time <- rep(c(-1, 0, 1), 4)
#' d <- data.frame(
#'   id = rep(1:4, each = 3), Time = time,
#'   DV = 2 + 1.5 * time + rep(c(-3, -1, 1, 3), each = 3) +
#'     rep(c(1, -2, 1), 4)
#' )
#' fit <- fit_covariate_model(d, "DV", "id", "Time")
#' set.seed(217)
#' responses <- simulate_covariate_model(fit, d, nsim = 200)
#' attr(responses, "simulation_parameters")
#' plot_simulated_vpc(d, responses, bins = 3)
#' @seealso [fit_covariate_model()], [predict_covariate_model()]
#' @export
simulate_covariate_model <- function(object, newdata, nsim = 1000L) {
  loadNamespace("nlme")
  if (inherits(object, "nlme")) {
    stop("Simulation requires a linear random-intercept model")
  }
  mapping <- covariate_lme_mapping(object)
  structure <- object$modelStruct
  random <- structure$reStruct
  id <- mapping$original[mapping$role == "id"]
  backend_id <- mapping$model[mapping$role == "id"]
  if (!inherits(structure, "lmeStruct") ||
    !identical(names(structure), "reStruct") || length(random) != 1L ||
    !identical(names(random), backend_id)) {
    stop("Simulation requires one random intercept and independent constant-variance residuals")
  }
  if (!is_numeric_vector(object$sigma) || length(object$sigma) != 1L ||
    !is.finite(object$sigma) || object$sigma <= 0) {
    stop("The fitted residual standard deviation must be finite and positive")
  }
  covariance <- tryCatch(nlme::getVarCov(object, type = "random.effects"),
    error = function(e) stop("The fitted random-intercept covariance is invalid")
  )
  if (!is.matrix(covariance) || !identical(dim(covariance), c(1L, 1L)) ||
    !identical(rownames(covariance), "(Intercept)") ||
    !identical(colnames(covariance), "(Intercept)")) {
    stop("Simulation supports only a single random intercept, without random slopes")
  }
  if (!is.numeric(covariance) || is.complex(covariance) ||
    !is.finite(covariance[1L, 1L]) || covariance[1L, 1L] < 0) {
    stop("The fitted random-intercept variance must be finite and nonnegative")
  }
  if (!is_numeric_vector(nsim) || length(nsim) != 1L || !is.finite(nsim) ||
    nsim < 1 || nsim != floor(nsim) || nsim >= .Machine$integer.max) {
    stop("`nsim` must be one positive integer below .Machine$integer.max")
  }
  validate_model_covariates(newdata, id)
  validate_model_vectors(newdata, id)
  subject <- newdata[[id]]
  if (anyNA(subject) || (is_numeric_vector(subject) && any(!is.finite(subject)))) {
    stop("Simulation subject identifiers must be observed and finite")
  }
  fixed_mean <- predict_covariate_model(object, newdata, level = 0L)
  if (as.double(nrow(newdata)) * nsim >= .Machine$integer.max) {
    stop("The requested simulation matrix is too large")
  }
  sd_subject <- sqrt(as.numeric(covariance[1L, 1L]))
  sd_residual <- object$sigma
  result <- matrix(NA_real_, nrow(newdata), nsim,
    dimnames = list(rownames(newdata), paste0("sim_", seq_len(nsim)))
  )
  if (nrow(newdata) > 0L) {
    subjects <- unique(subject)
    group <- match(subject, subjects)
    for (replicate in seq_len(nsim)) {
      intercepts <- stats::rnorm(length(subjects), sd = sd_subject)
      residuals <- stats::rnorm(nrow(newdata), sd = sd_residual)
      result[, replicate] <- fixed_mean + intercepts[group] + residuals
    }
    if (any(!is.finite(result))) {
      stop("Simulated responses are not finite; inspect the fitted model and input scale")
    }
  }
  attr(result, "simulation_parameters") <- list(
    mean = fixed_mean, sd_subject = sd_subject, sd_residual = sd_residual
  )
  result
}
