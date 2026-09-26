#' Group-sequential boundaries
#'
#' Calculate simple O'Brien-Fleming or Pocock boundaries for interim analyses.
#'
#' @param k Number of looks/interim analyses.
#' @param alpha Overall type I error rate.
#' @param method Boundary method ("obrien-fleming" or "pocock").
#'
#' @return A numeric vector of critical z-values for each look.
#' @export
#' @examples
#' pharma_group_seq(k = 3)
pharma_group_seq <- function(k = 4, alpha = 0.05,
                             method = c("obrien-fleming", "pocock")) {
  method <- match.arg(method)
  if (k < 1) stop("k must be >= 1")
  if (method == "obrien-fleming") {
    probs <- (1:k) / k
    z <- stats::qnorm(1 - alpha / 2 / sqrt(probs))
  } else {
    z <- rep(stats::qnorm(1 - alpha / 2 / k), k)
  }
  z
}
