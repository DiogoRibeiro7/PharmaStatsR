#' Simulated Latin square dataset
#'
#' Example data for a 4x4 Latin square design used in design of experiments examples.
#'
#' @format A data frame with 16 rows and 4 variables:
#' \describe{
#'   \item{row}{Row factor}
#'   \item{column}{Column factor}
#'   \item{treatment}{Treatment factor (A-D)}
#'   \item{response}{Numeric response}
#' }
#' @source Simulated data.
#' @examples
#' data(pharma_latin_square)
#' summary(pharma_latin_square)
pharma_latin_square <- local({
  set.seed(123)
  design <- data.frame(
    row = factor(rep(1:4, each = 4)),
    column = factor(rep(1:4, times = 4)),
    treatment = factor(c(
      "A", "B", "C", "D",
      "B", "C", "D", "A",
      "C", "D", "A", "B",
      "D", "A", "B", "C"
    ))
  )
  design$response <- rnorm(16, mean = 5, sd = 0.3)
  design
})
