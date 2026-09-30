#' Conduct a meta-analysis
#'
#' Delegate a specified fixed- or random-effects model to `metafor::rma`.
#' Requires the 'metafor' package to be installed. An estimation failure is
#' returned as an error; it never changes the chosen model to fixed effects.
#'
#' @param yi Numeric vector of effect size estimates.
#' @param vi Numeric vector of effect size variances.
#' @param method Estimation method passed to `metafor::rma`. Use "FE" for a
#'   fixed-effects model or "REML" (default) for random effects.
#' @param ... Additional arguments passed to [metafor::rma].
#'
#' @return An `rma` object fitted with the requested `method`. Errors from
#'   `metafor::rma` are propagated without substituting another model.
#' @export
#'
#' @examples
#' if (requireNamespace("metafor", quietly = TRUE)) {
#' pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
#' }

pharma_meta_analysis <- function(yi, vi, method = "REML", ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop(
      "Package 'metafor' is required for pharma_meta_analysis().\n",
      "Please install it with install.packages('metafor')",
      call. = FALSE
    )
  }
  check_numeric_vector(yi, "yi")
  check_numeric_vector(vi, "vi")
  if (length(yi) != length(vi)) {
    stop("`yi` and `vi` must be the same length; got ", length(yi), " and ", length(vi))
  }
  if (!is.character(method) || length(method) != 1L || is.na(method) ||
      !nzchar(method)) {
    stop("`method` must be a nonempty character scalar", call. = FALSE)
  }
  if (length(yi) < 3) {
    warning("Meta-analysis with fewer than 3 studies may be unreliable")
  }
  .pharma_meta_rma(yi = yi, vi = vi, method = method, ...)
}

# Keep the backend call separate so tests can exercise estimation failures
# without depending on a particular optimizer's error text or version.
.pharma_meta_rma <- function(...) {
  metafor::rma(...)
}

#' Forest plot for a meta-analysis
#'
#' Create a forest plot from an `rma` object.
#' Requires the 'metafor' package.
#'
#' @param model An object from [metafor::rma].
#' @param ... Additional arguments passed to [metafor::forest].
#'
#' @return A plot.
#' @export
#'
#' @examples
#' if (requireNamespace("metafor", quietly = TRUE)) {
#' res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
#' pharma_forest_plot(res)
#' }

pharma_forest_plot <- function(model, ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop(
      "Package 'metafor' is required for pharma_forest_plot().\n",
      "Please install it with install.packages('metafor')",
      call. = FALSE
    )
  }
  if (!inherits(model, "rma")) {
    stop("`model` must be a 'rma' object from metafor")
  }
  metafor::forest(model, ...)
}

#' Funnel plot for a meta-analysis
#'
#' Create a funnel plot from an `rma` object.
#' Requires the 'metafor' package.
#'
#' @param model An object from [metafor::rma].
#' @param ... Additional arguments passed to [metafor::funnel].
#'
#' @return A plot.
#' @export
#'
#' @examples
#' if (requireNamespace("metafor", quietly = TRUE)) {
#' res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
#' pharma_funnel_plot(res)
#' }

pharma_funnel_plot <- function(model, ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop(
      "Package 'metafor' is required for pharma_funnel_plot().\n",
      "Please install it with install.packages('metafor')",
      call. = FALSE
    )
  }
  if (!inherits(model, "rma")) {
    stop("`model` must be a 'rma' object from metafor")
  }
  metafor::funnel(model, ...)
}

#' Meta-regression
#'
#' Wrapper around `metafor::rma` to fit a meta-regression with moderators.
#' Requires the 'metafor' package.
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
#' if (requireNamespace("metafor", quietly = TRUE)) {
#' mods <- cbind(size = c(100, 120, 80))
#' pharma_meta_regression(
#'   yi = c(0.2, 0.1, -0.1),
#'   vi = c(0.05, 0.04, 0.06),
#'   mods = mods
#' )
#' }

pharma_meta_regression <- function(yi, vi, mods, method = "REML", ...) {
  if (!requireNamespace("metafor", quietly = TRUE)) {
    stop(
      "Package 'metafor' is required for pharma_meta_regression().\n",
      "Please install it with install.packages('metafor')",
      call. = FALSE
    )
  }
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
#' Requires the 'netmeta' package.
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
#' @param ... Additional arguments passed to [netmeta::netmeta]. Pass
#'   `studlab` here to identify comparisons from the same study, especially
#'   multi-arm studies. Without it, `netmeta` treats comparisons as independent
#'   studies.
#'
#' @return A `netmeta` object.
#' @export
#'
#' @examples
#' if (requireNamespace("netmeta", quietly = TRUE)) {
#' df <- data.frame(
#'   treat1 = c("A", "A", "B"),
#'   treat2 = c("B", "C", "C"),
#'   TE = c(0.2, 0.5, -0.1),
#'   seTE = c(0.1, 0.2, 0.1),
#'   study = c("s1", "s2", "s3")
#' )
#' pharma_network_meta_analysis(TE, seTE, treat1, treat2,
#'   data = df, studlab = df$study, random = FALSE)
#' }

pharma_network_meta_analysis <- function(TE, seTE, treat1, treat2, data = NULL,
                                         sm = "MD", random = TRUE, ...) {
  if (!.pharma_netmeta_available()) {
    stop(
      "Package 'netmeta' is required for pharma_network_meta_analysis().\n",
      "Please install it with install.packages('netmeta')",
      call. = FALSE
    )
  }
  if (!is.null(data)) {
    required <- c(
      deparse(substitute(TE)),
      deparse(substitute(seTE)),
      deparse(substitute(treat1)),
      deparse(substitute(treat2))
    )
    validate_inputs(data, required_cols = required)
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

.pharma_netmeta_available <- function() {
  requireNamespace("netmeta", quietly = TRUE)
}
