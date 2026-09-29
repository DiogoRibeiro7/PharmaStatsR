#' Fit a generalized estimating equations (GEE) model
#'
#' Convenience wrapper around `geepack::geeglm` for correlated response data.
#' The function resolves cluster IDs against `data`, validates complete model
#' values and contiguous cluster rows, and then delegates fitting to `geepack`.
#'
#' @param formula A model formula.
#' @param id A bare column name in `data` or an observation-aligned vector
#'   identifying independent clusters. Each cluster must occupy consecutive rows.
#' @param data Data frame containing the variables in the model.
#' @param family Error distribution and link function to be used in the model.
#' @param corstr Working correlation structure. See `geepack::geeglm`.
#' @param ... Additional arguments passed to `geepack::geeglm`.
#'
#' @details
#' `geepack::geeglm()` requires complete data and contiguous rows for each
#' cluster. Sort by the cluster identifier (and by visit order for an ordered
#' working correlation) before fitting. The model estimates a marginal mean
#' relationship; its interpretation depends on the chosen working correlation
#' and the independence of clusters.
#'
#' @return A `geeglm` object.
#' @export
#'
#' @examples
#' if (requireNamespace("geepack", quietly = TRUE)) {
#' pharma_gee(response ~ condition, id = subject, data = pharma_repeated)
#' }

pharma_gee <- function(formula, id, data, family = stats::gaussian,
                       corstr = "independence", ...) {
  validate_inputs(data, formula)
  if (!requireNamespace("geepack", quietly = TRUE)) {
    stop(
      "Package 'geepack' is required for `pharma_gee()`.\n",
      "Please install it with: install.packages('geepack')"
    )
  }
  if (missing(id)) {
    stop("id is required to identify clusters", call. = FALSE)
  }

  # Capture the caller's expression before the wrapper loses its data context.
  id_expr <- substitute(id)
  cluster_id <- eval(id_expr, envir = data, enclos = parent.frame())
  if (!(is.numeric(cluster_id) || is.character(cluster_id) ||
        is.factor(cluster_id) || is.logical(cluster_id)) ||
      !is.null(dim(cluster_id)) || length(cluster_id) != nrow(data) ||
      anyNA(cluster_id)) {
    stop("id must be a complete vector with one value per data row",
         call. = FALSE)
  }
  if (anyDuplicated(rle(cluster_id)$values)) {
    stop("all observations for each id must be in contiguous rows",
         call. = FALSE)
  }

  model_data <- stats::model.frame(
    formula, data = data, na.action = stats::na.pass
  )
  if (anyNA(model_data)) {
    stop("model variables must be complete for geepack::geeglm()",
         call. = FALSE)
  }

  # Keep the original id expression in geeglm's call. Its model.frame() then
  # evaluates a bare column name against data, just as a direct call does.
  fit_call <- substitute(
    geepack::geeglm(
      formula = formula, id = .ID, data = data,
      family = family, corstr = corstr, ...
    ),
    list(.ID = id_expr)
  )
  eval(fit_call)
}
