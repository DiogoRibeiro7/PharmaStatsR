#' Conduct a meta-analysis
#'
#' Wrapper around `metafor::rma` to fit fixed- or random-effects models.
#'
#' @param yi Numeric vector of effect size estimates.
#' @param vi Numeric vector of effect size variances.
#' @param method Estimation method. Use "FE" for fixed effects or
#'   e.g. "REML" for random effects (default).
#' @param ... Additional arguments passed to [metafor::rma].
#'
#' @return A `rma` object.
#' @export
#'
#' @examples
#' pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
pharma_meta_analysis <- function(yi, vi, method = "REML", ...) {
  check_numeric_vector(yi, "yi")
  check_numeric_vector(vi, "vi")
  if (length(yi) != length(vi)) {
    stop("`yi` and `vi` must be the same length; got ", length(yi), " and ", length(vi))
  }
  if (!is.character(method) || length(method) != 1) {
    stop("`method` must be a single character string")
  }
  if (length(yi) < 3) {
    warning("Meta-analysis with fewer than 3 studies may be unreliable")
  }
  tryCatch(
    metafor::rma(yi = yi, vi = vi, method = method, ...),
    error = function(e) {
      if (grepl("singular", e$message)) {
        message("Attempting fallback with FE model due to estimation issues")
        metafor::rma(yi = yi, vi = vi, method = "FE", ...)
      } else {
        stop("Meta-analysis failed: ", e$message)
      }
    }
  )
}

#' Forest plot for a meta-analysis
#'
#' Create a forest plot from an `rma` object.
#'
#' @param model An object from [metafor::rma].
#' @param ... Additional arguments passed to [metafor::forest].
#'
#' @return A plot.
#' @export
#'
#' @examples
#' res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
#' pharma_forest_plot(res)
pharma_forest_plot <- function(model, ...) {
  if (!inherits(model, "rma")) {
    stop("`model` must be a 'rma' object from metafor")
  }
  metafor::forest(model, ...)
}

#' Funnel plot for a meta-analysis
#'
#' Create a funnel plot from an `rma` object.
#'
#' @param model An object from [metafor::rma].
#' @param ... Additional arguments passed to [metafor::funnel].
#'
#' @return A plot.
#' @export
#'
#' @examples
#' res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
#' pharma_funnel_plot(res)
pharma_funnel_plot <- function(model, ...) {
  if (!inherits(model, "rma")) {
    stop("`model` must be a 'rma' object from metafor")
  }
  metafor::funnel(model, ...)
}

#' Meta-regression
#'
#' Wrapper around `metafor::rma` to fit a meta-regression with moderators.
#'
#' @param yi Effect size estimates.
#' @param vi Effect size variances.
#' @param mods Moderator matrix or formula.
#' @param method Estimation method for random effects (default "REML").
#' @param ... Additional arguments passed to [metafor::rma].
#'
#' @return A `rma` object.
#' @export
#'
#' @examples
#' mods <- cbind(size = c(100, 120, 80))
#' pharma_meta_regression(
#'   yi = c(0.2, 0.1, -0.1),
#'   vi = c(0.05, 0.04, 0.06),
#'   mods = mods
#' )
pharma_meta_regression <- function(yi, vi, mods, method = "REML", ...) {
  check_numeric_vector(yi, "yi")
  check_numeric_vector(vi, "vi")
  if (length(yi) != length(vi)) {
    stop("`yi` and `vi` must be the same length; got ", length(yi), " and ", length(vi))
  }
  if (!(is.matrix(mods) || inherits(mods, "formula"))) {
    stop("`mods` must be a matrix or formula")
  }
  if (!is.character(method) || length(method) != 1) {
    stop("`method` must be a single character string")
  }
  metafor::rma(yi = yi, vi = vi, mods = mods, method = method, ...)
}

#' Network meta-analysis
#'
#' Fit a network meta-analysis using [netmeta::netmeta] to compare multiple
#' treatments across studies.
#'
#' @param TE Numeric vector of treatment effect estimates.
#' @param seTE Numeric vector of standard errors for the effect estimates.
#' @param treat1 Character vector specifying the first treatment in each
#'   comparison.
#' @param treat2 Character vector specifying the second treatment in each
#'   comparison.
#' @param data Optional data frame containing the variables.
#' @param sm Summary measure passed to [netmeta::netmeta].
#' @param random Logical indicating whether to fit a random-effects model
#'   (default `TRUE`).
#' @param ... Additional arguments passed to [netmeta::netmeta].
#'
#' @return A `netmeta` object.
#' @export
#'
#' @examples
#' df <- data.frame(
#'   treat1 = c("A", "A", "B"),
#'   treat2 = c("B", "C", "C"),
#'   TE = c(0.2, 0.5, -0.1),
#'   seTE = c(0.1, 0.2, 0.1)
#' )
#' pharma_network_meta_analysis(TE, seTE, treat1, treat2, data = df)
pharma_network_meta_analysis <- function(TE, seTE, treat1, treat2, data = NULL,
                                         sm = "MD", random = TRUE, ...) {
  if (!is.null(data)) {
    required <- c(
      deparse(substitute(TE)),
      deparse(substitute(seTE)),
      deparse(substitute(treat1)),
      deparse(substitute(treat2))
    )
    check_dataset(data, required)
    TE <- data[[required[1]]]
    seTE <- data[[required[2]]]
    treat1 <- data[[required[3]]]
    treat2 <- data[[required[4]]]
  }
  check_numeric_vector(TE, "TE")
  check_numeric_vector(seTE, "seTE")
  if (!is.character(treat1) || !is.character(treat2)) {
    stop("`treat1` and `treat2` must be character vectors")
  }
  if (length(TE) != length(seTE) || length(TE) != length(treat1) ||
    length(TE) != length(treat2)) {
    stop("`TE`, `seTE`, `treat1`, and `treat2` must have the same length")
  }
  if (anyNA(TE) || anyNA(seTE) || anyNA(treat1) || anyNA(treat2)) {
    stop("`TE`, `seTE`, `treat1`, and `treat2` cannot contain NA values")
  }
  if (!is.logical(random) || length(random) != 1 || is.na(random)) {
    stop("`random` must be a single logical value")
  }
  netmeta::netmeta(
    TE = TE,
    seTE = seTE,
    treat1 = treat1,
    treat2 = treat2,
    sm = sm,
    random = random,
    ...
  )
}
