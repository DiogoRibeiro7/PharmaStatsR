#' Simulated repeated measures dataset
#'
#' Example data for a simple two-condition repeated measures design.
#'
#' @format A data frame with 20 rows and 3 variables:
#' \describe{
#'   \item{subject}{Subject identifier}
#'   \item{condition}{Condition ("A" or "B")}
#'   \item{response}{Numeric response}
#' }
#' @source Simulated data.
"pharma_repeated" <- data.frame(
  subject = rep(1:10, each = 2),
  condition = rep(c("A","B"), times = 10),
  response = c(5.1,5.5,5.0,5.4,4.9,5.3,5.2,5.6,5.1,5.5,
               6.0,6.2,5.9,6.1,6.0,6.4,6.2,6.5,6.1,6.3)
)
