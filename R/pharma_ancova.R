#' Fit a one-covariate ANCOVA model
#'
#' Fit an additive linear model with one categorical treatment and one numeric
#' covariate, compare it with the corresponding treatment-by-covariate
#' interaction model, and report treatment adjusted means at the observed
#' covariate mean.
#'
#' @param formula A two-sided additive formula of the form
#'   `response ~ treatment + covariate` with an intercept. The treatment must
#'   be categorical and the covariate numeric. Terms must be direct column names.
#' @param data A data frame containing the variables in `formula`.
#' @param conf.level Confidence level for adjusted-mean intervals.
#' @param ... Additional arguments passed to both `stats::lm()` fits.
#'
#' @return A list with the additive `model`, the `interaction_model`,
#'   `slope_homogeneity` comparison, treatment `adjusted_means`,
#'   `covariate_mean`, and the detected treatment/covariate names.
#' @details
#' The interaction comparison is a model diagnostic for the common-slope
#' assumption; a large p-value does not prove equal slopes. Adjusted means are
#' predictions from the additive model at the overall observed covariate mean.
#' Missing or nonfinite model values are rejected before fitting.
#' @export
#'
#' @examples
#' dat <- data.frame(
#'   response = c(1, 3, 5, 7, 4, 6, 8, 10),
#'   treatment = factor(rep(c("A", "B"), each = 4)),
#'   baseline = rep(0:3, 2)
#' )
#' pharma_ancova(response ~ treatment + baseline, dat)
pharma_ancova <- function(formula, data, conf.level = 0.95, ...) {
  pharma_log("INFO", "Running pharma_ancova")
  validate_inputs(data, formula)

  if (!is.numeric(conf.level) || length(conf.level) != 1L ||
      is.na(conf.level) || !is.finite(conf.level) ||
      conf.level <= 0 || conf.level >= 1) {
    stop("conf.level must be one finite number strictly between 0 and 1",
         call. = FALSE)
  }

  mf <- stats::model.frame(formula, data = data, na.action = stats::na.pass)
  if (anyNA(mf)) {
    stop("Variables used by formula contain NA values; remove or impute them before calling pharma_ancova",
         call. = FALSE)
  }

  trm <- stats::terms(mf)
  labels <- attr(trm, "term.labels")
  if (attr(trm, "intercept") != 1L || length(labels) != 2L ||
      any(attr(trm, "order") != 1L) || ncol(mf) != 3L) {
    stop("pharma_ancova requires response ~ treatment + covariate with an intercept and no interaction",
         call. = FALSE)
  }
  if (!all(labels %in% names(data))) {
    stop("treatment and covariate terms must be direct column names in data",
         call. = FALSE)
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
         call. = FALSE)
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
         call. = FALSE)
  }

  model <- stats::lm(formula = formula, data = data, ...)
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
  interaction_model <- stats::lm(
    formula = interaction_formula,
    data = data,
    ...
  )
  comparison <- stats::anova(model, interaction_model)

  covariate_mean <- mean(covariate)
  levels_treatment <- levels(treatment)
  newdata <- data.frame(
    factor(levels_treatment, levels = levels_treatment),
    rep(covariate_mean, length(levels_treatment))
  )
  names(newdata) <- c(treatment_name, covariate_name)
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
