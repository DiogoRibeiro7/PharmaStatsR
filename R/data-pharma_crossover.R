#' Simulated crossover trial dataset
#'
#' A hand-entered, balanced two-period AB/BA illustration with ten subjects:
#' five receive A then B and five B then A. These are not clinical records.
#'
#' @format A data frame with 20 rows and 5 variables:
#' \describe{
#'   \item{subject}{Subject factor, levels 1 to 10}
#'   \item{period}{Period factor, levels 1 and 2}
#'   \item{treatment}{Treatment factor, levels A and B}
#'   \item{response}{Numeric illustrative response (unitless)}
#'   \item{outcome}{Arbitrary binary example label, 0 or 1; not a defined clinical event}
#' }
#' @source Hand-entered illustrative values in the package source.
#' @details One observation per subject and period. Use for a complete AB/BA
#'   additive crossover ANOVA; these data do not establish bioequivalence or
#'   identify carryover effects.
#' @docType data
#' @keywords datasets
#' @export
#' @examples
#' data(pharma_crossover)
#' head(pharma_crossover)
pharma_crossover <- data.frame(
  subject = factor(rep(1:10, each = 2)),
  period = factor(rep(1:2, times = 10)),
  treatment = factor(rep(c("A", "B", "B", "A"), times = 5)),
  response = c(5.2,5.0,5.3,5.1,4.9,5.4,5.0,4.8,5.5,5.2,
               5.4,5.6,5.7,5.5,5.8,5.6,5.9,5.7,6.0,5.8),
  outcome = c(1,0,1,0,0,1,0,0,1,0,
             1,0,1,0,1,0,1,0,1,0)
)
