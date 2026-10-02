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
#' @source Responses generated with seed 123 by
#'   \code{data-raw/generate-fixture-responses.R} and stored as fixed values in
#'   the package source; no patient or experimental observations.
#' @details Use to demonstrate the additive Latin square ANOVA. One response
#'   per row-column cell does not allow separate estimation of interactions.
#' @docType data
#' @keywords datasets
#' @export
#' @examples
#' summary(pharma_latin_square)
pharma_latin_square <- data.frame(
  row = factor(rep(1:4, each = 4)),
  column = factor(rep(1:4, times = 4)),
  treatment = factor(c(
    "A", "B", "C", "D",
    "B", "C", "D", "A",
    "C", "D", "A", "B",
    "D", "A", "B", "C"
  )),
  response = c(
    4.83185730603434, 4.93094675315502, 5.46761249424474,
    5.02115251742737, 5.03878632054828, 5.51451949606498,
    5.13827486179676, 4.62048162961804, 4.79394414443194,
    4.86630140897001, 5.36722453923184, 5.10794414811721,
    5.12023143517822, 5.03320481478354, 4.83324765957378,
    5.53607394104092
  )
)
