#' Simulated two-group example dataset
#'
#' Hand-entered illustrative values for two groups of ten subjects each.
#' Treatment A always has dose 1 and B always has dose 2, so treatment and dose
#' are perfectly confounded. These are not clinical records.
#'
#' @format A data frame with 20 rows and 5 variables:
#' \describe{
#'   \item{subject}{Integer subject identifier, 1 to 20}
#'   \item{treatment}{Character group label, A or B}
#'   \item{dose}{Numeric illustrative level, 1 or 2 (unitless)}
#'   \item{response}{Numeric illustrative response (unitless)}
#'   \item{outcome}{Arbitrary binary example label, 0 or 1; not a defined clinical event}
#' }
#' @source Hand-entered illustrative values in the package source.
#' @details Use for simple group comparisons or row-level examples. The
#'   treatment and dose effects cannot be estimated separately. The binary
#'   outcome is an example label, without clinical event semantics.
#' @docType data
#' @keywords datasets
#' @export
#' @examples
#' data(pharma_sample)
#' head(pharma_sample)
pharma_sample <- data.frame(
  subject = 1:20,
  treatment = rep(c("A", "B"), each = 10),
  dose = rep(c(1, 2), each = 10),
  response = c(5.1, 4.9, 5.5, 4.8, 5.3, 5.1, 5.7, 4.6, 5.2, 5.0,
               5.9, 6.1, 6.0, 5.8, 6.2, 5.7, 5.9, 6.3, 6.1, 6.2),
  outcome = c(0,1,1,0,1,0,1,0,1,0,
              1,0,0,1,0,1,0,1,0,1)
)
