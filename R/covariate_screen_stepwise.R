#' Select covariates via stepwise AIC
#'
#' Performs forward and backward stepwise selection based on AIC using ordinary
#' linear regression. All models use the same rows, complete for the response
#' and every candidate. Subject-level correlation is not modeled at this stage.
#' The response must be a real numeric vector; candidates may be real numeric,
#' logical, character, or factor vectors. At least three complete-case rows are
#' required. Infinite numeric values and constant variables on retained rows
#' are rejected. Unused factor levels are dropped before fitting.
#'
#' Column names are interpreted literally, including spaces or formula
#' operators. Duplicate column names, duplicate candidates, and using the
#' response as a candidate are rejected. An empty candidate selection returns
#' `character(0)` without fitting.
#'
#' @param data A `data.frame` containing the response and covariates.
#' @param response Name of the response variable as a string.
#' @param id Name of the subject identifier column. Its presence is checked but
#'   its values are not used in fitting or complete-case filtering.
#' @param covariates Character vector of unique covariate column names.
#'
#' @return Character vector of selected covariate names.
#' @examples
#' set.seed(123)
#' df <- data.frame(
#'   SubjectID = 1:100,
#'   DV = rnorm(100),
#'   x1 = rnorm(100),
#'   x2 = rnorm(100)
#' )
#' screen_covariates_stepwise(df, "DV", "SubjectID", c("x1", "x2"))
#' @export
screen_covariates_stepwise <- function(data, response, id, covariates) {
  validate_data_frame_names(data)
  if (!is.character(id) || length(id) != 1L || !is.null(dim(id)) ||
    is.na(id) || !id %in% names(data)) {
    stop("`id` column not found")
  }
  data <- prepare_screening_data(data, response, covariates)
  if (is.null(data)) {
    return(character(0))
  }

  base_formula <- stats::as.formula(".screen_response ~ 1")
  candidate_names <- names(data)[-1L]
  full_formula <- stats::reformulate(
    candidate_names,
    response = ".screen_response"
  )

  # Fit stepwise model ----------------------------------------------------
  base_model <- stats::lm(base_formula, data = data)
  step_model <- stats::step(
    base_model,
    scope = list(lower = base_formula, upper = full_formula),
    direction = "both", trace = 0
  )

  # Extract selected terms ------------------------------------------------
  terms <- attr(stats::terms(step_model), "term.labels")
  unname(covariates[match(terms, candidate_names)])
}
