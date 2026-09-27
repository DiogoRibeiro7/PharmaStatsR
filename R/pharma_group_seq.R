#' Two-sided group-sequential efficacy boundaries
#'
#' Calculate calibrated O'Brien-Fleming or Pocock critical z-values for
#' planned analyses using `gsDesign`. These are symmetric two-sided
#' efficacy boundaries under its canonical joint normal model.
#'
#' @param k A positive whole number of analyses, including the final analysis.
#' @param alpha Overall two-sided type I error rate, strictly between 0 and 0.5.
#' @param method Boundary family, `"obrien-fleming"` or `"pocock"`.
#' @param timing Optional increasing information fractions, one per analysis.
#'   The last must equal 1. Defaults to equally spaced information fractions.
#'
#' @return A numeric vector of positive critical z-values. At each analysis
#'   the upper boundary is the returned value and the lower boundary is its
#'   negative. No futility or sample-size calculation is returned.
#' @references
#' `gsDesign` design derivation:
#' \url{https://keaven.github.io/gsDesign/reference/gsDesign.html}
#' @export
#'
#' @examples
#' pharma_group_seq(k = 3)
#' pharma_group_seq(k = 3, method = "pocock", timing = c(0.25, 0.6, 1))
pharma_group_seq <- function(k = 4, alpha = 0.05,
                             method = c("obrien-fleming", "pocock"),
                             timing = NULL) {
  method <- match.arg(method)
  if (!is.numeric(k) || length(k) != 1L || !is.finite(k) ||
      k < 1 || k %% 1 != 0) {
    stop("`k` must be a positive whole number", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) ||
      alpha <= 0 || alpha >= 0.5) {
    stop("`alpha` must be strictly between 0 and 0.5", call. = FALSE)
  }

  if (is.null(timing)) {
    timing <- seq_len(k) / k
  }
  if (!is.numeric(timing) || length(timing) != k ||
      any(!is.finite(timing)) || any(timing <= 0) ||
      any(diff(timing) <= 0) ||
      abs(timing[k] - 1) > sqrt(.Machine$double.eps)) {
    stop(
      "`timing` must contain increasing information fractions ending at 1",
      call. = FALSE
    )
  }

  if (k == 1) {
    return(stats::qnorm(1 - alpha / 2))
  }

  boundary <- if (method == "obrien-fleming") "OF" else "Pocock"
  design <- gsDesign::gsDesign(
    k = k, test.type = 2, alpha = alpha / 2,
    timing = timing, sfu = boundary
  )
  as.numeric(design$upper$bound)
}
