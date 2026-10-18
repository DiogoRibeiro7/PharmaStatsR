#' Select covariates via LASSO regression
#'
#' Performs covariate selection using the LASSO penalty with cross-validation.
#' Candidate columns must be numeric, with at least two columns for `glmnet`.
#' Rows with missing response or candidate values are removed before fitting.
#' By default, folds are assigned at the row level. Supply `id` to keep all
#' retained observations from each subject in the same fold. Random assignment
#' balances the number of subjects (or rows), not the number of observations
#' per subject. Use `set.seed()` before calling to reproduce random folds, or
#' supply `foldid` to reuse a fixed split.
#'
#' The regression is Gaussian and does not model within-subject correlation.
#' Grouping controls the split only: preprocessing performed before this call
#' is not refitted within each training fold. Categorical encoding is not
#' supported. Selection uses the nonzero coefficients at `lambda.min`.
#' This is the penalty with minimum cross-validated mean squared error on
#' the backend's generated path, not the one-standard-error choice. The
#' backend fits an intercept and standardizes predictors by default. The
#' exact nonzero comparison does not apply a separate coefficient tolerance;
#' with `alpha = 0`, ridge coefficients generally do not give sparse selection.
#'
#' Candidate names are interpreted literally, including spaces, formula
#' operators and `"(Intercept)"`. A candidate with that name remains distinct
#' from the fitted intercept. The result contains original candidate names in
#' their supplied order, without names attached to the character vector.
#'
#' @param data A `data.frame` containing the response and covariates.
#' @param response Name of the response variable as a string.
#' @param covariates Character vector of covariate column names.
#' @param alpha Finite number in `[0, 1]`; `1` corresponds to LASSO.
#' @param id Optional subject identifier column name. Identifiers must be
#'   nonmissing on retained rows. If `foldid` is also supplied, it must assign
#'   each retained subject to exactly one fold.
#' @param nfolds Number of random folds, an integer of at least three and no
#'   greater than the number of retained subjects (or rows without `id`).
#'   Defaults to ten. Ignored when `foldid` is supplied.
#' @param foldid Optional vector of positive integer fold labels, one per row
#'   of the original `data`. It is subset alongside complete-case rows and
#'   surviving labels are renumbered internally. At least three folds must
#'   remain. Supplying this vector avoids random fold generation.
#'
#' @return Unnamed character vector of original selected covariate names in
#'   candidate order. The fitted intercept is excluded; a candidate literally
#'   named `"(Intercept)"` is eligible for selection.
#' @seealso [screen_covariates_lasso_imputed()] for training-fold numeric
#'   imputation with a prespecified penalty grid and held-out predictions.
#' @examples
#' set.seed(123)
#' df <- data.frame(
#'   DV = rnorm(100),
#'   x1 = rnorm(100),
#'   x2 = rnorm(100)
#' )
#' screen_covariates_lasso(df, "DV", c("x1", "x2"))
#'
#' # Repeated measurements: hold out entire subjects.
#' df$SubjectID <- rep(seq_len(20), each = 5)
#' screen_covariates_lasso(
#'   df, "DV", c("x1", "x2"),
#'   id = "SubjectID", nfolds = 5
#' )
#'
#' # Reuse the same subject-level split when comparing alpha values.
#' folds <- rep(rep(seq_len(5), length.out = 20), each = 5)
#' screen_covariates_lasso(
#'   df, "DV", c("x1", "x2"),
#'   alpha = 0.5,
#'   id = "SubjectID", foldid = folds
#' )
#' @export
screen_covariates_lasso <- function(data, response, covariates, alpha = 1,
                                    id = NULL, nfolds = 10L, foldid = NULL) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame")
  }
  if (anyDuplicated(names(data))) {
    stop("`data` must have unique column names")
  }
  if (!is.character(response) || length(response) != 1L ||
    is.na(response) || !response %in% names(data)) {
    stop("`response` column not found")
  }
  if (!is.character(covariates) || anyNA(covariates) ||
    anyDuplicated(covariates)) {
    stop("`covariates` must be a character vector of unique column names")
  }
  if (length(covariates) == 0) {
    return(character(0))
  }
  if (!all(covariates %in% names(data))) {
    missing <- setdiff(covariates, names(data))
    stop(sprintf("Covariates not found: %s", paste(missing, collapse = ", ")))
  }
  if (response %in% covariates) {
    stop("`response` cannot also be a candidate covariate")
  }
  if (length(covariates) < 2L) {
    stop("LASSO screening requires at least two numeric covariate columns")
  }
  if (!is.null(id)) {
    if (!is.character(id) || length(id) != 1L ||
      is.na(id) || !id %in% names(data)) {
      stop("`id` must name a subject identifier column in `data`")
    }
  }
  if (!is_numeric_vector(alpha) || length(alpha) != 1L ||
    !is.finite(alpha) || alpha < 0 || alpha > 1) {
    stop("`alpha` must be a finite number between 0 and 1")
  }

  vars <- c(response, covariates)
  if (!all(vapply(data[vars], is_numeric_vector, logical(1)))) {
    stop("Response and covariate columns must be numeric vectors")
  }
  keep <- stats::complete.cases(data[vars])
  x <- as.matrix(data[keep, covariates, drop = FALSE])
  y <- data[[response]][keep]
  if (length(y) < 3L) {
    stop("At least three complete-case rows are required")
  }
  if (any(!is.finite(x)) || any(!is.finite(y))) {
    stop("Response and covariates must be finite on complete-case rows")
  }

  subjects <- if (is.null(id)) NULL else data[[id]]
  folds <- make_lasso_folds(keep, subjects, nfolds, foldid)
  validate_lasso_training(x, y, folds)

  cv <- glmnet::cv.glmnet(x, y, alpha = alpha, foldid = folds)
  coefs <- stats::coef(cv, s = "lambda.min")

  # The first row is the fitted intercept. Remaining rows follow x columns;
  # matching by text would also discard a candidate named "(Intercept)".
  unname(covariates[coefs[-1L, 1] != 0])
}

make_lasso_folds <- function(keep, subjects, nfolds, foldid) {
  if (!is.null(subjects)) {
    if (!is.atomic(subjects) || !is.null(dim(subjects))) {
      stop("Subject identifiers must be a nonmissing vector on retained rows")
    }
    subjects <- subjects[keep]
    if (anyNA(subjects)) {
      stop("Subject identifiers must be a nonmissing vector on retained rows")
    }
    units <- match(subjects, unique(subjects))
  } else {
    units <- seq_len(sum(keep))
  }

  if (is.null(foldid)) {
    if (!is_numeric_vector(nfolds) || length(nfolds) != 1L ||
      !is.finite(nfolds) || nfolds < 3 || nfolds != floor(nfolds)) {
      stop("`nfolds` must be an integer of at least three")
    }
    n_units <- length(unique(units))
    if (nfolds > n_units) {
      stop("`nfolds` exceeds the number of retained subjects or rows")
    }
    unit_folds <- sample(rep(seq_len(nfolds), length.out = n_units))
    return(unit_folds[units])
  }

  if (!is_numeric_vector(foldid) || length(foldid) != length(keep) ||
    any(!is.finite(foldid)) || any(foldid < 1) ||
    any(foldid != floor(foldid))) {
    stop("`foldid` must contain one positive integer per original data row")
  }
  retained <- foldid[keep]
  folds <- match(retained, sort(unique(retained)))
  if (length(unique(folds)) < 3L) {
    stop("`foldid` must retain at least three nonempty folds")
  }
  if (!is.null(subjects)) {
    per_subject <- vapply(
      split(folds, units), function(x) length(unique(x)), integer(1)
    )
    if (any(per_subject > 1L)) {
      stop("`foldid` must keep each retained subject in a single fold")
    }
  }
  folds
}

validate_lasso_training <- function(x, y, folds) {
  for (fold in sort(unique(folds))) {
    train <- folds != fold
    if (length(unique(y[train])) < 2L) {
      stop(sprintf(
        "Training data excluding fold %s has constant response", fold
      ))
    }
    varying <- vapply(
      seq_len(ncol(x)),
      function(j) length(unique(x[train, j])) > 1L,
      logical(1)
    )
    if (!any(varying)) {
      stop(sprintf(
        "Training data excluding fold %s has no varying covariates", fold
      ))
    }
  }
}
