#' Simulate population responses from a saved allometric oral model
#'
#' Draw replicated responses from [fit_nlmixr_allometric()], holding fitted
#' parameters and variances fixed. Each replicate draws fresh independent
#' log-absorption and log-clearance subject effects and additive normal residual
#' errors. Subjects seen during fitting are treated like new subjects. This is
#' an experimental population simulator without parameter uncertainty.
#'
#' @param object An intact native `nlmixr2FitData` result from
#'   [fit_nlmixr_allometric()], including a saved/restored fit. Its allometry
#'   metadata, stored model, fitted parameters and diagonal subject-effect
#'   covariance must be available. Correlated or additional effects are rejected.
#'   Older fits without starting-value metadata are supported.
#' @param newdata Data frame containing the original subject, time and weight
#'   names, with complete explicit oral dose histories. The event and schema
#'   requirements of [predict_nlmixr_allometric()] apply, including uppercase
#'   `EVID` and `AMT`, subject-constant weights, and no unsupported modifiers.
#'   Responses are ignored; training doses are never borrowed.
#' @param nsim Positive integer number of complete response replicates, default
#'   1000. At least two are needed for [plot_simulated_vpc()].
#'
#' @return A numeric matrix with one row per input row and `nsim` columns named
#'   `sim_1`, `sim_2`, etc. Input row order and nonempty row names are preserved.
#'   Dose rows contain `NA_real_`; observation rows contain simulated responses.
#'   The `simulation_parameters` attribute records fitted backend `theta`
#'   (log structural parameters and residual SD), log-subject-effect covariance
#'   `omega`, response-scale `sd_residual`,
#'   `reference_weight`, and fixed `exponents`. Starting values are not used.
#'   Empty input and schedules containing only doses return without drawing.
#'
#' @details For each replicate and subject, independent normal effects enter
#'   log absorption and log clearance with variances from the fitted covariance.
#'   All records for that subject share these effects. Volume retains its fixed
#'   weight scaling and has no random effect. Concentrations from the stored
#'   model receive independent additive normal errors on observation rows,
#'   including duplicate times. Negative simulated responses are retained:
#'   the fitted additive-error model has no truncation or censoring rule.
#'
#'   Call `set.seed()` to reproduce simulations under the same R RNG settings.
#'   The helper consumes the current R stream. For each replicate, it draws
#'   absorption effects for subjects in order of first appearance, then clearance
#'   effects in that order, then residuals in input observation-row order.
#'   Dose-only subjects receive effects when other subjects have observations;
#'   an entirely dose-only batch draws nothing. Relabeling IDs while preserving
#'   their grouping preserves seeded results. Reordering or splitting schedules
#'   can change realized draws. Solver changes to R's random stream are
#'   isolated; the solver evaluates the supplied effects without residual draws.
#'
#'   Inputs are validated before drawing. Numerical overflow or backend failure
#'   during generation may consume the requested draws and raises an error.
#'   Keep the complete relevant dose history in every call. Missing historical
#'   doses cannot be inferred. No fitted individual effects, refitting,
#'   parameter uncertainty, missingness, dropout or censoring are simulated.
#'   To use [plot_simulated_vpc()], select the same observation rows from the
#'   data and matrix after simulation, preserving dimensions with `drop = FALSE`.
#' @examples
#' \dontrun{
#' d <- nlmixr2data::theo_sd
#' fit <- fit_nlmixr_allometric(d, weight = "WT", control = list(seed = 99))
#' set.seed(227)
#' responses <- simulate_nlmixr_allometric(fit, d, nsim = 200)
#' attr(responses, "simulation_parameters")
#' observed <- d$EVID == 0
#' plot_simulated_vpc(d[observed, ], responses[observed, , drop = FALSE],
#'   time = "TIME", response = "DV", bins = 4
#' )
#' }
#' @seealso [fit_nlmixr_allometric()], [predict_nlmixr_allometric()]
#' @export
simulate_nlmixr_allometric <- function(object, newdata, nsim = 1000L) {
  # Loading/restoring native model fields can touch the backend random stream.
  # Validation must not consume or initialize the caller's R random state.
  setup <- allometric_preserve_rng(function() {
    if (!requireNamespace("nlmixr2est", quietly = TRUE)) {
      stop("Package 'nlmixr2est' is required for simulate_nlmixr_allometric()")
    }
    saved <- allometric_simulation_components(object)
    if (!is_numeric_vector(nsim) || length(nsim) != 1L || !is.finite(nsim) ||
      nsim < 1 || nsim != floor(nsim) || nsim >= .Machine$integer.max) {
      stop("`nsim` must be one positive integer below .Machine$integer.max")
    }
    events <- allometric_prediction_events(saved, newdata)
    subjects <- unique(events$ID)
    if (max(nrow(events), 6 * length(subjects)) * as.double(nsim) >= .Machine$integer.max) {
      stop("The requested simulation matrix or parameter table is too large")
    }
    list(saved = saved, events = events, subjects = subjects)
  })
  saved <- setup$saved
  events <- setup$events
  observations <- which(events$EVID == 0L)
  result <- matrix(NA_real_, nrow(events), nsim,
    dimnames = list(rownames(newdata), paste0("sim_", seq_len(nsim)))
  )
  attr(result, "simulation_parameters") <- list(
    theta = saved$theta, omega = saved$omega,
    sd_residual = saved$theta[["add.sd"]],
    reference_weight = saved$metadata$reference_weight,
    exponents = saved$metadata$exponents
  )
  if (!length(observations)) {
    return(result)
  }
  nsubject <- length(setup$subjects)
  # Consecutive IDs and parameter blocks follow first appearance. The backend
  # repeats each complete event schedule for successive parameter blocks.
  events$ID <- match(events$ID, setup$subjects)
  events$PSR_ROW <- seq_len(nrow(events))
  parameters <- as.data.frame(as.list(saved$theta))
  parameters <- parameters[rep(1L, nsubject * nsim), , drop = FALSE]
  parameters$eta.ka <- parameters$eta.cl <- 0
  for (replicate in seq_len(nsim)) {
    rows <- seq_len(nsubject) + (replicate - 1) * nsubject
    parameters$eta.ka[rows] <- stats::rnorm(nsubject, sd = sqrt(saved$omega[1L, 1L]))
    parameters$eta.cl[rows] <- stats::rnorm(nsubject, sd = sqrt(saved$omega[2L, 2L]))
    result[observations, replicate] <- stats::rnorm(length(observations), sd = saved$theta[["add.sd"]])
  }
  natural <- c(exp(parameters$tka + parameters$eta.ka), exp(parameters$tcl + parameters$eta.cl))
  if (any(!is.finite(natural) | natural <= 0)) {
    stop("Simulated absorption and clearance must be positive and finite; inspect the fitted scale")
  }
  solved <- allometric_preserve_rng(function() {
    nlmixr2est::rxSolve(saved$ui,
      params = parameters, events = events, sigma = NA, simVariability = FALSE,
      returnType = "data.frame", keep = "PSR_ROW", warnIdSort = FALSE, idFactor = FALSE
    )
  })
  if (is.data.frame(solved) && nsim == 1 && !"sim.id" %in% names(solved)) {
    solved$sim.id <- rep(1, nrow(solved))
  }
  if (!is.data.frame(solved) || !all(c("PSR_ROW", "sim.id", "pred") %in% names(solved)) ||
    nrow(solved) != length(observations) * nsim ||
    !is_numeric_vector(solved$PSR_ROW) || any(!solved$PSR_ROW %in% observations) ||
    !is_numeric_vector(solved$sim.id) || any(!is.finite(solved$sim.id)) ||
    any(solved$sim.id < 1 | solved$sim.id > nsim | solved$sim.id != floor(solved$sim.id)) ||
    !is_numeric_vector(solved$pred) || any(!is.finite(solved$pred))) {
    stop("Allometric simulation must return one finite concentration per observation and replicate")
  }
  index <- solved$PSR_ROW + (solved$sim.id - 1) * nrow(events)
  if (anyDuplicated(index)) {
    stop("Allometric simulation returned duplicate observation/replicate records")
  }
  result[index] <- result[index] + solved$pred
  if (any(!is.finite(result[observations, , drop = FALSE]))) {
    stop("Simulated responses are not finite; inspect the fitted model and input scale")
  }
  result
}

allometric_simulation_components <- function(object) {
  saved <- allometric_prediction_components(object)
  omega <- object$omega
  effects <- c("eta.ka", "eta.cl")
  if (!is.matrix(omega) || !is.numeric(omega) || is.complex(omega) ||
    !identical(dim(omega), c(2L, 2L)) ||
    !identical(dimnames(omega), list(effects, effects)) ||
    any(!is.finite(omega)) || any(diag(omega) < 0) ||
    any(omega[row(omega) != col(omega)] != 0)) {
    stop("Simulation requires a finite nonnegative diagonal covariance for eta.ka and eta.cl")
  }
  saved$omega <- omega
  saved
}

allometric_preserve_rng <- function(code) {
  present <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (present) state <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  on.exit({
    if (present) {
      assign(".Random.seed", state, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  })
  code()
}
