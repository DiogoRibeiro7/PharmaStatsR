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
  .pharma_require_optional("metafor", "pharma_meta_analysis")
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
#' @return Draws a forest plot on the active graphics device and invisibly
#'   returns the backend's layout list (including `xlim`, `alim`, `at`, `ylim`,
#'   and `rows`). Study point coordinates and labels are not returned.
#' @export
#'
#' @examples
#' if (requireNamespace("metafor", quietly = TRUE)) {
#' res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
#' pharma_forest_plot(res)
#' }

pharma_forest_plot <- function(model, ...) {
  .pharma_require_optional("metafor", "pharma_forest_plot")
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
#' @return Draws a funnel plot on the active graphics device and invisibly
#'   returns the backend's data frame: `x` holds plotted effects, `y` holds
#'   the selected y-axis values (standard errors by default), and `slab`
#'   holds study labels.
#' @details For labels, use an `rma` object fitted directly with
#'   [metafor::rma] and stored study labels. Plot-time `slab` overrides
#'   passed through this wrapper currently fail backend evaluation.
#' @export
#'
#' @examples
#' if (requireNamespace("metafor", quietly = TRUE)) {
#' res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
#' pharma_funnel_plot(res)
#' }

pharma_funnel_plot <- function(model, ...) {
  .pharma_require_optional("metafor", "pharma_funnel_plot")
  if (!inherits(model, "rma")) {
    stop("`model` must be a 'rma' object from metafor")
  }
  metafor::funnel(model, ...)
}

#' Meta-regression
#'
#' Fit a fixed- or mixed-effects meta-regression using `metafor::rma()`.
#' Requires the optional 'metafor' package. Estimation errors are propagated.
#'
#' @param yi Finite numeric vector of effect size estimates, one per study.
#' @param vi Finite numeric vector of corresponding sampling variances, not
#'   standard errors.
#' @param mods Numeric moderator matrix with one row per study and at least
#'   one column, or a one-sided moderator formula such as `~ dose`. Formula
#'   variables may be supplied with `data` through `...`.
#' @param method Estimation method passed to `metafor::rma()`. The default
#'   "REML" fits a mixed-effects model; use "FE" explicitly for fixed effects.
#' @param ... Additional arguments passed to [metafor::rma].
#'
#' @return An `rma` object for the requested model.
#' @export
#'
#' @examples
#' if (requireNamespace("metafor", quietly = TRUE)) {
#' mods <- cbind(dose = 1:6)
#' pharma_meta_regression(
#'   yi = c(-0.3, 0.2, 0.4, 0.1, 0.7, 0.9),
#'   vi = c(0.06, 0.04, 0.05, 0.03, 0.08, 0.04),
#'   mods = mods, method = "FE"
#' )
#' }

pharma_meta_regression <- function(yi, vi, mods, method = "REML", ...) {
  if (!.pharma_metafor_available()) {
    stop(
      "Package 'metafor' is required for pharma_meta_regression().\n",
      "Please install it with install.packages('metafor')",
      call. = FALSE
    )
  }
  check_numeric_vector(yi, "yi")
  check_numeric_vector(vi, "vi")
  if (length(yi) != length(vi)) {
    stop(
      "`yi` and `vi` must be the same length; got ", length(yi),
      " and ", length(vi), call. = FALSE
    )
  }
  if (is.matrix(mods)) {
    # Matrix rows must align with the original effect-size vectors.
    if (!is.numeric(mods) || nrow(mods) != length(yi) ||
        ncol(mods) < 1L || anyNA(mods) || !all(is.finite(mods))) {
      stop(
        "`mods` must be a finite numeric matrix with one row per effect size and at least one column",
        call. = FALSE
      )
    }
  } else if (!inherits(mods, "formula") || length(mods) != 2L) {
    stop("`mods` must be a numeric matrix or a one-sided formula", call. = FALSE)
  }
  if (!is.character(method) || length(method) != 1L || is.na(method) ||
      !nzchar(method)) {
    stop("`method` must be a nonempty character scalar", call. = FALSE)
  }
  metafor::rma(yi = yi, vi = vi, mods = mods, method = method, ...)
}

.pharma_metafor_available <- function() {
  requireNamespace("metafor", quietly = TRUE)
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
