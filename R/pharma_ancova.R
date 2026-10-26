#' Fit a one-covariate ANCOVA model
#'
#' Fit an additive linear model with one categorical treatment and one numeric
#' covariate, compare it with the corresponding treatment-by-covariate
#' interaction model, and report treatment adjusted means at the unweighted
#' arithmetic covariate mean of the selected observations.
#'
#' @param formula A two-sided additive formula of the form
#'   `response ~ treatment + covariate` with an intercept. The treatment must
#'   be categorical and the covariate numeric. Terms must be direct column names.
#' @param data A data frame containing the variables in `formula`.
#' @param conf.level Confidence level for adjusted-mean intervals.
#' @param ... Named options: `weights` and `subset` use the native
#'   [stats::model.frame()] lookup rules (data first, then the formula's
#'   environment) and are evaluated once for both models. Weights must be
#'   finite, strictly positive numeric values on selected rows; `NULL` uses
#'   ordinary least squares. Use `subset` to exclude zero-weight observations
#'   explicitly. `contrasts`, `tol`, `singular.ok`, `x` and `y` are passed
#'   to both fits. `model` and `qr` must be `TRUE`, `method` must be
#'   `"qr"`, and `tol` must be strictly between zero and one. Standard
#'   `na.action` choices are accepted but selected missing values are always
#'   rejected; custom callbacks and other options, including offsets, are
#'   unsupported.
#'
#' @return An object of class `pharma_ancova` (also a list) with the additive
#'   `model`, the `interaction_model`,
#'   `slope_homogeneity` comparison, treatment `adjusted_means`,
#'   `covariate_mean`, and the detected treatment/covariate names.
#' @details
#' The interaction comparison is a model diagnostic for the common-slope
#' assumption; a large p-value does not prove equal slopes. Adjusted means are
#' predictions from the additive model at the unweighted covariate mean of
#' the selected rows. Positive weights specify relative precision in weighted
#' least squares, with variance proportional to `1 / weights`; they are not
#' treated as replication counts or survey-design weights. Model-based standard
#' errors, individual confidence intervals and the nested-model F test use
#' that assumption. Multiplying all weights by one positive constant preserves
#' coefficients, coefficient standard errors, adjusted-mean intervals and
#' the interaction test, up to numerical tolerance.
#'
#' Selection occurs before checking model values, weights and treatment levels.
#' Missing or nonfinite selected model values are rejected regardless of
#' `na.action`; incomplete rows outside the subset do not affect the analysis.
#' Both additive and interaction designs must have full column rank and positive
#' residual degrees of freedom. Offsets require an explicit choice for adjusted
#' predictions and are rejected; use `stats::lm()` directly for that workflow.
#' Use `summary(result)` for the additive model's familiar `lm` output plus
#' the slope comparison and adjusted means; `coef(summary(result))` extracts
#' its coefficient table. See [summary.pharma_ancova()].
#' @export
#'
#' @examples
#' dat <- data.frame(
#'   response = c(11, 11, 13, 17, 14, 16, 20, 26),
#'   treatment = factor(rep(c("A", "B"), each = 4)),
#'   baseline = rep(0:3, 2)
#' )
#' fit <- pharma_ancova(response ~ treatment + baseline, dat)
#' summary(fit)
#' coef(summary(fit))
#' dat$precision <- seq_len(nrow(dat))
#' weighted <- pharma_ancova(response ~ treatment + baseline, dat,
#'   weights = precision, subset = baseline > 0
#' )
#' summary(weighted)
pharma_ancova <- function(formula, data, conf.level = 0.95, ...) {
  pharma_log("INFO", "Running pharma_ancova")
  validate_inputs(data, formula)
  if (anyDuplicated(names(data))) {
    stop("data must have unique column names", call. = FALSE)
  }
  original_call <- match.call()
  arguments <- as.list(match.call(expand.dots = FALSE)$...)
  allowed <- c(
    "weights", "subset", "contrasts", "tol", "singular.ok",
    "model", "x", "y", "qr", "method", "na.action"
  )
  if (length(arguments) && (is.null(names(arguments)) ||
    anyNA(names(arguments)) || any(names(arguments) == "") ||
    anyDuplicated(names(arguments)))) {
    stop("Additional ANCOVA arguments must have unique, complete names", call. = FALSE)
  }
  if ("offset" %in% names(arguments) || length(attr(stats::terms(formula), "offset"))) {
    stop("Offsets are unsupported for ANCOVA adjusted means; use lm() with explicit prediction offsets", call. = FALSE)
  }
  unknown <- setdiff(names(arguments), allowed)
  if (length(unknown)) {
    stop("Unsupported ANCOVA argument(s): ", paste(unknown, collapse = ", "), call. = FALSE)
  }

  if (!is.numeric(conf.level) || length(conf.level) != 1L ||
    is.na(conf.level) || !is.finite(conf.level) ||
    conf.level <= 0 || conf.level >= 1) {
    stop("conf.level must be one finite number strictly between 0 and 1",
      call. = FALSE
    )
  }

  # Resolve data-dependent expressions once, using model.frame's data/formula
  # lookup rules. Both fits then receive the same selected values.
  frame_arguments <- arguments[intersect(c("weights", "subset"), names(arguments))]
  mf <- do.call(stats::model.frame, c(
    list(
      formula = formula, data = data, na.action = stats::na.pass,
      drop.unused.levels = TRUE
    ),
    frame_arguments
  ), envir = parent.frame())
  weights <- stats::model.weights(mf)
  if (!is.null(weights) && (!is.numeric(weights) || is.complex(weights) ||
    !is.null(dim(weights)) || length(weights) != nrow(mf) ||
    any(!is.finite(weights)) || any(weights <= 0))) {
    stop("weights must be finite, strictly positive numeric values on every selected row", call. = FALSE)
  }
  trm <- stats::terms(mf)
  mf <- mf[, names(mf) != "(weights)", drop = FALSE]
  if (anyNA(mf)) {
    stop("Variables used by formula contain NA values; remove or impute them before calling pharma_ancova",
      call. = FALSE
    )
  }

  labels <- attr(trm, "term.labels")
  if (attr(trm, "intercept") != 1L || length(labels) != 2L ||
    any(attr(trm, "order") != 1L) || ncol(mf) != 3L) {
    stop("pharma_ancova requires response ~ treatment + covariate with an intercept and no interaction",
      call. = FALSE
    )
  }
  if (!all(labels %in% names(data))) {
    stop("treatment and covariate terms must be direct column names in data",
      call. = FALSE
    )
  }

  response <- mf[[1L]]
  if (!is.numeric(response) || !is.null(dim(response)) ||
    !all(is.finite(response))) {
    stop("Response must be one finite numeric vector", call. = FALSE)
  }

  predictors <- mf[-1L]
  is_cat <- vapply(
    predictors,
    function(x) is.factor(x) || is.character(x) || is.logical(x),
    logical(1)
  )
  is_num <- vapply(
    predictors,
    function(x) is.numeric(x) && is.null(dim(x)),
    logical(1)
  )
  if (sum(is_cat) != 1L || sum(is_num) != 1L) {
    stop("ANCOVA requires exactly one categorical treatment and one numeric covariate",
      call. = FALSE
    )
  }

  treatment_name <- names(predictors)[which(is_cat)]
  covariate_name <- names(predictors)[which(is_num)]
  treatment <- droplevels(as.factor(predictors[[treatment_name]]))
  covariate <- predictors[[covariate_name]]

  if (nlevels(treatment) < 2L) {
    stop("Treatment must have at least two observed levels", call. = FALSE)
  }
  if (!all(is.finite(covariate)) || length(unique(covariate)) < 2L) {
    stop("Covariate must contain at least two distinct finite values",
      call. = FALSE
    )
  }

  controls <- lapply(arguments[setdiff(names(arguments), c("weights", "subset"))],
    eval,
    envir = parent.frame()
  )
  # Complete selected rows are required independently of the global option.
  # Standard na.action choices are accepted, but custom row-changing callbacks
  # would break the common analysis population.
  if ("na.action" %in% names(controls)) {
    action <- controls[["na.action"]]
    standard <- list(NULL, stats::na.fail, stats::na.omit, stats::na.exclude, stats::na.pass)
    valid <- any(vapply(standard, identical, logical(1), y = action)) ||
      (is.character(action) && length(action) == 1L && !is.na(action) &&
        action %in% c("na.fail", "na.omit", "na.exclude", "na.pass"))
    if (!valid) stop("Custom na.action functions are unsupported; select complete rows with subset", call. = FALSE)
    controls["na.action"] <- NULL
  }
  for (name in intersect(c("model", "qr"), names(controls))) {
    if (!identical(controls[[name]], TRUE)) {
      stop(name, " must be TRUE for ANCOVA diagnostics and summaries", call. = FALSE)
    }
  }
  if ("method" %in% names(controls) && !identical(controls$method, "qr")) {
    stop("method must be 'qr' for ANCOVA fits", call. = FALSE)
  }
  if ("tol" %in% names(controls) &&
    (!is.numeric(controls$tol) || is.complex(controls$tol) ||
      length(controls$tol) != 1L || !is.finite(controls$tol) ||
      controls$tol <= 0 || controls$tol >= 1)) {
    stop("tol must be one finite number strictly between 0 and 1", call. = FALSE)
  }
  fit_model <- function(model_formula, label) {
    fit <- do.call(stats::lm, c(
      list(
        formula = model_formula, data = mf, weights = weights,
        na.action = stats::na.fail
      ), controls
    ))
    if (fit$rank < length(stats::coef(fit)) || stats::df.residual(fit) <= 0L) {
      stop(label, " model must have full column rank and positive residual degrees of freedom", call. = FALSE)
    }
    if (any(!is.finite(stats::coef(fit))) || !is.finite(stats::deviance(fit))) {
      stop(label, " model has non-finite fitted coefficients or residual sum of squares", call. = FALSE)
    }
    # Keep a readable native-model call instead of embedding the full frame
    # generated by do.call. The stored model frame remains the fit's data.
    fit$call <- original_call
    fit$call[[1L]] <- quote(stats::lm)
    fit$call$conf.level <- NULL
    fit$call$formula <- as.call(as.list(model_formula))
    fit
  }
  model <- fit_model(formula, "Additive")
  interaction_formula <- stats::as.formula(
    paste(
      deparse(formula[[2L]]),
      "~",
      paste(labels, collapse = " + "),
      "+",
      paste(labels, collapse = ":")
    ),
    env = environment(formula)
  )
  interaction_model <- fit_model(interaction_formula, "Interaction")
  comparison <- stats::anova(model, interaction_model)

  covariate_mean <- mean(covariate)
  levels_treatment <- levels(treatment)
  newdata <- data.frame(
    factor(levels_treatment, levels = levels_treatment),
    rep(covariate_mean, length(levels_treatment))
  )
  names(newdata) <- c(treatment_name, covariate_name)
  if (is.logical(predictors[[treatment_name]])) {
    newdata[[treatment_name]] <- levels_treatment == "TRUE"
  }
  prediction <- stats::predict(
    model,
    newdata = newdata,
    interval = "confidence",
    level = conf.level
  )

  adjusted_means <- data.frame(
    treatment = levels_treatment,
    covariate = rep(covariate_mean, length(levels_treatment)),
    adjusted_mean = unname(prediction[, "fit"]),
    conf.low = unname(prediction[, "lwr"]),
    conf.high = unname(prediction[, "upr"]),
    stringsAsFactors = FALSE
  )

  slope_homogeneity <- list(
    df1 = unname(comparison$Df[[2L]]),
    df2 = unname(stats::df.residual(interaction_model)),
    F = unname(comparison$F[[2L]]),
    p.value = unname(comparison[["Pr(>F)"]][[2L]])
  )

  structure(
    list(
      model = model,
      interaction_model = interaction_model,
      slope_homogeneity = slope_homogeneity,
      adjusted_means = adjusted_means,
      covariate_mean = covariate_mean,
      treatment = treatment_name,
      covariate = covariate_name
    ),
    class = c("pharma_ancova", "list")
  )
}
