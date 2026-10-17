#' Fit a weight-allometric one-compartment oral model
#'
#' Fits a prespecified nonlinear mixed-effects model with first-order absorption
#' using SAEM in `nlmixr2est`. Clearance scales with body weight to the fixed
#' power 0.75, and volume scales linearly. The exponents are assumptions, not
#' estimated covariate effects. This function does not select covariates.
#'
#' @param data A nonempty data frame of explicit oral bolus dosing and
#'   observation records. Uppercase `EVID` and `AMT` columns are required.
#'   `EVID` is 0 for observations and 1 or 101 for doses; doses require positive
#'   amounts and observations require zero amounts. Optional `CMT` must be 1
#'   for doses and 2 for observations. Infusion, additional-dose, steady-state,
#'   missing-observation, censoring, and multiple-endpoint modifier columns
#'   (`RATE`, `DUR`, `II`, `ADDL`, `SS`, `MDV`, `CENS`, `LIMIT`, `DVID`) are
#'   rejected rather than silently ignored. Other unselected columns are ignored.
#' @param weight Name of a real numeric, finite, positive body-weight column.
#'   Weight must be present and exactly constant within each subject across
#'   dosing and observation records. No interpolation or imputation is performed.
#' @param reference_weight Positive finite scalar in the same units as weight,
#'   default 70. It defines the reference clearance and volume parameters.
#' @param response Name of the real numeric response column, default `"DV"`.
#'   Observations must be finite; missing dosing responses are allowed and
#'   replaced by zero in the backend data. No observation is silently dropped.
#' @param id Name of the positive integer subject identifier column, default
#'   `"ID"`. At least two subjects, each with a dose and two observations, are
#'   required. These checks do not guarantee identifiability or convergence.
#' @param time Name of the finite, nonnegative numeric time column, default
#'   `"TIME"`. The backend can reorder event records.
#' @param control Named list of arguments to [nlmixr2est::saemControl()].
#'   Defaults are those of the backend with `print = 0`; set `seed` explicitly
#'   for a recorded stochastic fit. Unknown control names are rejected.
#' @param initial Named list of positive finite scalar starting values. Allowed
#'   names are `ka`, `cl`, `v`, `eta_ka_var`, `eta_cl_var`, and `residual_sd`.
#'   Unspecified values default to 1, except `v = exp(1)`. `ka`, `cl`, and `v`
#'   are on their natural scales, with clearance and volume at
#'   `reference_weight` and zero subject effects; they are logged internally.
#'   `eta_ka_var` and `eta_cl_var` are variances of the log-scale subject
#'   effects, not standard deviations or coefficients of variation.
#'   `residual_sd` is a standard deviation on the response scale. These are
#'   starting values for estimation, not fixed parameters or fitted estimates.
#'
#' @details With `r = weight / reference_weight`, the model is
#'   `ka = exp(tka + eta.ka)`, `cl = exp(tcl + eta.cl) * r^0.75`, and
#'   `v = exp(tv) * r`. Subject effects on log absorption and log clearance
#'   are independent zero-mean normal effects. Volume has no random effect.
#'   The response has additive normal error. At the reference weight and zero
#'   random effects, `exp(tcl)` and `exp(tv)` are apparent clearance and volume
#'   (bioavailability is implicitly one). Input dose, response, weight and time
#'   units must be consistent; no unit conversion is done.
#'
#'   Response, id, time and weight names are treated literally and must be
#'   distinct. Only those columns and the supported event columns reach the
#'   backend, under names `DV`, `ID`, `TIME`, `WT`, `EVID`, `AMT`, and `CMT`.
#'   Native prediction/simulation methods require these backend names and raw
#'   weight in `WT`, including on dosing records. The reference weight is a
#'   literal in the stored model; it is not recomputed from prediction data.
#'   SAEM controls, random streams, convergence and uncertainty are backend
#'   behavior. The wrapper does not restore RNG state or certify an optimum.
#'   Supply alternative `initial` values to investigate sensitivity to starts;
#'   there is no automatic multi-start search or selection. Changing the
#'   reference weight without changing initial clearance and volume changes
#'   the starting concentration curve. For an equivalent starting model, scale
#'   `cl` by `(new_reference / old_reference)^0.75` and `v` by
#'   `new_reference / old_reference`. All starts must be strictly positive;
#'   zero starts do not fix or remove a variance component.
#'
#' @return A native `nlmixr2FitData` object. Attribute `allometry` records
#'   `reference_weight`, the fixed `exponents`, a named numeric `initial` vector
#'   containing all six resolved natural-scale starts, and a `column_map` data frame
#'   with `role`, `original`, and `model` columns. Native fit tables can omit
#'   dose records and reorder observations; they are not input-row predictions.
#' @seealso [fit_nlmixr_model()] for the unchanged example-only wrapper.
#' @examples
#' \dontrun{
#' fit <- fit_nlmixr_allometric(nlmixr2data::theo_sd,
#'   weight = "WT",
#'   reference_weight = 70, control = list(seed = 99),
#'   initial = list(ka = 1.5, cl = 3.2, v = 32)
#' )
#' attr(fit, "allometry")
#' head(fit$PRED)
#' }
#' @export
fit_nlmixr_allometric <- function(data, weight, reference_weight = 70,
                                  response = "DV", id = "ID", time = "TIME",
                                  control = list(), initial = list()) {
  fit_data <- prepare_allometric_data(data, weight, reference_weight, response, id, time)
  starts <- allometric_initial_values(initial)
  if (!is.list(control) || is.object(control) ||
    (length(control) > 0L && (is.null(names(control)) ||
      anyNA(names(control)) || any(!nzchar(names(control))) || anyDuplicated(names(control))))) {
    stop("`control` must be a list of uniquely named SAEM control arguments")
  }
  if (!requireNamespace("nlmixr2est", quietly = TRUE)) {
    stop("Package 'nlmixr2est' is required for fit_nlmixr_allometric()")
  }
  unknown <- setdiff(names(control), setdiff(names(formals(nlmixr2est::saemControl)), "..."))
  if (length(unknown)) {
    stop("Unknown SAEM control arguments: ", paste(unknown, collapse = ", "))
  }
  settings <- utils::modifyList(list(print = 0), control, keep.null = TRUE)
  fit <- nlmixr2est::nlmixr2(
    allometric_nlmixr_model(reference_weight, starts),
    data = fit_data, est = "saem",
    control = do.call(nlmixr2est::saemControl, settings)
  )
  attr(fit, "allometry") <- list(
    reference_weight = unname(reference_weight), exponents = c(cl = 0.75, v = 1),
    initial = starts,
    column_map = data.frame(
      role = c("response", "id", "time", "weight"),
      original = c(response, id, time, weight), model = c("DV", "ID", "TIME", "WT"),
      stringsAsFactors = FALSE
    )
  )
  fit
}

prepare_allometric_data <- function(data, weight, reference_weight, response, id, time) {
  validate_data_frame_names(data)
  selected <- list(response = response, id = id, time = time, weight = weight)
  for (role in names(selected)) {
    name <- selected[[role]]
    if (!is.character(name) || length(name) != 1L || !is.null(dim(name)) ||
      is.na(name) || !nzchar(name)) {
      stop("`", role, "` must name one column")
    }
  }
  columns <- unlist(selected, use.names = FALSE)
  if (anyDuplicated(columns) || any(columns %in% c("EVID", "AMT", "CMT"))) {
    stop("Response, id, time, weight, and event columns must be distinct")
  }
  missing <- setdiff(c(columns, "EVID", "AMT"), names(data))
  if (length(missing)) stop("Variables not found: ", paste(missing, collapse = ", "))
  modifiers <- intersect(toupper(names(data)), c(
    "RATE", "DUR", "II", "ADDL", "SS", "MDV", "CENS", "LIMIT", "DVID"
  ))
  if (length(modifiers)) {
    stop("Unsupported event modifier columns: ", paste(modifiers, collapse = ", "))
  }
  if (!is_numeric_vector(reference_weight) || length(reference_weight) != 1L ||
    !is.finite(reference_weight) || reference_weight <= 0) {
    stop("`reference_weight` must be one positive finite number")
  }
  if (!nrow(data)) stop("`data` must contain dosing and observation records")
  for (name in c(id, time, weight, "EVID", "AMT")) {
    x <- data[[name]]
    if (!is_numeric_vector(x) || any(!is.finite(x))) {
      stop("`", name, "` must contain finite real numeric values")
    }
  }
  subject <- data[[id]]
  if (any(subject <= 0 | subject != floor(subject) | subject > .Machine$integer.max)) {
    stop("Subject identifiers must be positive integers within R's integer range")
  }
  if (length(unique(subject)) < 2L) stop("At least two subjects are required")
  if (any(data[[time]] < 0)) stop("Time must be nonnegative")
  wt <- data[[weight]]
  ratio <- wt / reference_weight
  if (any(wt <= 0 | !is.finite(ratio) | ratio <= 0)) {
    stop("Weights and weight/reference ratios must be positive and finite")
  }
  if (any(vapply(split(wt, subject), function(x) any(x != x[1L]), logical(1)))) {
    stop("Weight must be constant within each subject, including dosing records")
  }
  if (any(!data$EVID %in% c(0, 1, 101))) stop("`EVID` must contain only 0, 1, or 101")
  dose <- data$EVID != 0
  if (any(data$AMT[dose] <= 0) || any(data$AMT[!dose] != 0)) {
    stop("Doses require positive AMT; observations require zero AMT")
  }
  groups <- split(dose, subject)
  if (any(vapply(groups, function(x) !any(x) || sum(!x) < 2L, logical(1)))) {
    stop("Each subject needs at least one dose and two observations")
  }
  dv <- data[[response]]
  if (!is_numeric_vector(dv) || any(!is.finite(dv[!dose])) || any(is.infinite(dv[dose]))) {
    stop("Responses must be real numeric and finite on observations; dosing responses may be missing")
  }
  cmt <- ifelse(dose, 1L, 2L)
  if ("CMT" %in% names(data) && (!is_numeric_vector(data$CMT) ||
    anyNA(data$CMT) || any(data$CMT != cmt))) {
    stop("`CMT` must be 1 for oral doses and 2 for observations")
  }
  dv[dose] <- 0
  data.frame(
    ID = subject, TIME = data[[time]], DV = dv, WT = wt,
    EVID = as.integer(dose), AMT = data$AMT, CMT = cmt,
    row.names = rownames(data)
  )
}

allometric_initial_values <- function(initial = list()) {
  values <- c(ka = 1, cl = 1, v = exp(1), eta_ka_var = 1, eta_cl_var = 1, residual_sd = 1)
  if (!is.list(initial) || is.object(initial) || !is.null(dim(initial)) ||
    (length(initial) > 0L && (is.null(names(initial)) || anyNA(names(initial)) ||
      any(!nzchar(names(initial))) || anyDuplicated(names(initial))))) {
    stop("`initial` must be a list of uniquely named starting values")
  }
  unknown <- setdiff(names(initial), names(values))
  if (length(unknown)) {
    stop(
      "Unknown initial values: ", paste(unknown, collapse = ", "),
      ". Allowed names: ", paste(names(values), collapse = ", ")
    )
  }
  for (name in names(initial)) {
    value <- initial[[name]]
    if (!is_numeric_vector(value) || is.object(value) || length(value) != 1L ||
      !is.finite(value) || value <= 0) {
      stop("`initial$", name, "` must be one positive finite numeric value")
    }
    values[name] <- unname(value)
  }
  values
}

allometric_nlmixr_model <- function(reference_weight, initial = allometric_initial_values()) {
  # Substitute a validated numeric literal, never user-provided R code. The
  # stored backend model remains self-contained after serialization.
  model <- function() NULL
  body(model) <- substitute(
    {
      ini({
        tka <- LOG_KA
        tcl <- LOG_CL
        tv <- LOG_V
        eta.ka ~ VAR_KA
        eta.cl ~ VAR_CL
        add.sd <- SD_ERROR
      })
      model({
        ka <- exp(tka + eta.ka)
        cl <- exp(tcl + eta.cl) * (WT / REF)^0.75
        v <- exp(tv) * (WT / REF)
        linCmt() ~ add(add.sd)
      })
    },
    list(
      REF = unname(reference_weight),
      LOG_KA = log(initial[["ka"]]), LOG_CL = log(initial[["cl"]]), LOG_V = log(initial[["v"]]),
      VAR_KA = initial[["eta_ka_var"]], VAR_CL = initial[["eta_cl_var"]],
      SD_ERROR = initial[["residual_sd"]]
    )
  )
  model
}
