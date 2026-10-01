#' Simulated Latin square dataset
#'
#' A complete 4 by 4 Latin square: each treatment occurs once in every row
#' and column. Responses are independent normal draws with mean 5 and SD 0.3,
#' using seed 123. No treatment effect is built into these responses.
#'
#' @format A data frame with 16 rows and 4 variables:
#' \describe{
#'   \item{row}{Row factor, levels 1 to 4}
#'   \item{column}{Column factor, levels 1 to 4}
#'   \item{treatment}{Treatment factor, levels A to D}
#'   \item{response}{Numeric simulated response (unitless)}
#' }
#' @source Fixed design and seeded normal draws in the package source; no
#'   patient or experimental observations.
#' @details Use to demonstrate the additive Latin square ANOVA. One response
#'   per row-column cell does not allow separate estimation of interactions.
#' @examples
#' data(pharma_latin_square)
#' summary(pharma_latin_square)
pharma_latin_square <- .pharma_fixture_seed(123, function() {
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
