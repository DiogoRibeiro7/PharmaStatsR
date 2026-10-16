#' Predict from a covariate mixed model using original column names
#'
#' Predicts from [fit_covariate_model()] using raw new rows. A saved `column_map`
#' from `repair_names = TRUE` is applied without learning or fitting anything.
#' Default and older unmapped fits are also supported. The declared `nlme`
#' dependency is loaded for method registration after an RDS round trip.
#'
#' `level = 0` gives population predictions from fixed effects only; no subject
#' identifier is needed. `level = 1` adds the fitted random intercept for a
#' known subject and requires the identifier column. Unknown subjects return
#' `NA` at level 1, as in [nlme::predict.lme()]; there is no fallback to population
#' prediction. Missing predictor values and missing required identifiers raise
#' errors rather than dropping rows. No response column is required.
#'
#' Numeric covariates must stay real numeric and finite, logical covariates must
#' stay logical, and categorical covariates may be factors or characters.
#' Categorical levels and contrasts follow the saved model; unknown levels fail.
#' All raw candidate covariates are required. Extra columns are ignored and
#' input order may differ. Empty data return a named zero-length numeric vector.
#' These are point predictions, without intervals or a population-level
#' uncertainty assessment for an unknown subject. This is an experimental API.
#'
#' @param object A native `lme` result from [fit_covariate_model()], including
#'   a saved/restored result. Its stored training data, model structure, and
#'   name mapping (when present) must remain available and consistent.
#' @param newdata Data frame containing original covariate names and, for
#'   `level = 1`, the original subject identifier. Names must be unique,
#'   nonmissing, and nonempty.
#' @param level Scalar `0` (default) for population predictions or `1` for
#'   predictions conditional on the fitted subject random intercept.
#' @return A numeric vector with one entry per input row, named with the input
#'   row names. Data and fitted objects are not modified. This helper does not
#'   change the native model class or rename its coefficient labels.
#' @examples
#' subject <- rep(1:4, each = 3)
#' time <- rep(c(-1, 0, 1), 4)
#' training <- data.frame(subject, time,
#'   y = 2 + 1.5 * time + rep(c(-3, -1, 1, 3), each = 3) +
#'     rep(c(1, -2, 1), 4)
#' )
#' names(training) <- c("subject id", "visit time", "response value")
#' model <- fit_covariate_model(training, "response value", "subject id", "visit time",
#'   repair_names = TRUE
#' )
#' predict_covariate_model(model, training, level = 0)
#' predict_covariate_model(model, training, level = 1)
#' @seealso [fit_covariate_model()], [nlme::predict.lme()]
#' @export
predict_covariate_model <- function(object, newdata, level = 0L) {
  loadNamespace("nlme")
  if (!is_numeric_vector(level) || length(level) != 1L ||
    !is.finite(level) || !level %in% c(0, 1)) {
    stop("`level` must be 0 (population) or 1 (subject-specific)")
  }
  mapping <- covariate_lme_mapping(object)
  required <- mapping$role == "covariate" | (level == 1 & mapping$role == "id")
  columns <- mapping[required, , drop = FALSE]
  validate_model_covariates(newdata, columns$original)
  validate_model_vectors(newdata, columns$original)
  for (i in seq_len(nrow(columns))) {
    name <- columns$original[i]
    value <- newdata[[name]]
    if (anyNA(value) || (is_numeric_vector(value) && any(!is.finite(value)))) {
      stop(sprintf("Prediction column '%s' must be observed and finite", name))
    }
    if (columns$role[i] == "covariate") {
      trained <- object$data[[columns$model[i]]]
      compatible <- if (is_numeric_vector(trained)) {
        is_numeric_vector(value)
      } else if (is.logical(trained)) {
        is.logical(value)
      } else {
        is.factor(value) || is.character(value)
      }
      if (!compatible) stop(sprintf("Prediction column '%s' has an incompatible type", name))
    }
  }
  if (nrow(newdata) == 0L) {
    return(stats::setNames(numeric(0), rownames(newdata)))
  }
  # Select first, then rename together: raw names can collide with aliases.
  prepared <- newdata[columns$original]
  names(prepared) <- columns$model
  values <- stats::predict(object, newdata = prepared, level = level, na.action = stats::na.fail)
  if (length(values) != nrow(newdata) || any(is.infinite(values)) ||
    any(is.nan(values)) || (level == 0 && anyNA(values))) {
    stop("Mixed-model predictions must be finite, except for unknown subjects at level 1")
  }
  stats::setNames(as.numeric(values), rownames(newdata))
}

covariate_lme_mapping <- function(object) {
  invalid <- function() stop("Invalid covariate model; use an intact result from fit_covariate_model()")
  if (!inherits(object, "lme") || !is.list(object) || !is.data.frame(object$data)) invalid()
  variables <- all.vars(stats::formula(object))
  id <- names(object$groups)
  if (!length(variables) || length(id) != 1L) invalid()
  backend <- c(variables[1L], id, variables[-1L])
  if (!valid_encoding_names(backend) || !all(backend %in% names(object$data))) invalid()
  roles <- c("response", "id", rep("covariate", length(variables) - 1L))
  mapping <- object[["column_map", exact = TRUE]]
  if (is.null(mapping)) {
    mapping <- data.frame(role = roles, original = backend, model = backend, stringsAsFactors = FALSE)
  }
  if (!is.data.frame(mapping) || !valid_encoding_names(names(mapping)) ||
    !all(c("role", "original", "model") %in% names(mapping)) ||
    !identical(mapping$role, roles) || !valid_encoding_names(mapping$original) ||
    !identical(mapping$model, backend)) {
    invalid()
  }
  mapping
}
