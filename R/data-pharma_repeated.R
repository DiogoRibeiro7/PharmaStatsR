#' Simulated repeated measures dataset
#'
#' Ten subjects with one hand-entered response for each of conditions A and B.
#' Rows are ordered as a pair of conditions within each subject. These are not
#' clinical records.
#'
#' @description Simulated repeated measures dataset
#'
#' @format A data frame with 20 rows and 3 variables:
#' \describe{
#'   \item{subject}{Integer subject identifier, 1 to 10}
#'   \item{condition}{Character condition label, A or B}
#'   \item{response}{Numeric illustrative response (unitless)}
#' }
#' @source Hand-entered illustrative values in the package source.
#' @details Use for paired or repeated-condition examples. Convert both
#'   subject and condition to factors for \code{pharma_repeated_anova()}.
#' @docType data
#' @keywords datasets
#' @export
#' @examples
#' data(pharma_repeated)
#' head(pharma_repeated)
pharma_repeated <- data.frame(
  subject = rep(1:10, each = 2),
  condition = rep(c("A","B"), times = 10),
  response = c(5.1,5.5,5.0,5.4,4.9,5.3,5.2,5.6,5.1,5.5,
               6.0,6.2,5.9,6.1,6.0,6.4,6.2,6.5,6.1,6.3)
)
