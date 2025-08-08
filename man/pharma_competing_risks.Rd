\name{pharma_competing_risks}
\alias{pharma_competing_risks}
\title{Competing-risks regression}
\usage{pharma_competing_risks(formula, data, failcode = 1, cencode = 0, ...)}
\arguments{
  \item{formula}{A formula of the form \code{Surv(time, status) ~ predictors} where \code{status} codes the event type.}
  \item{data}{A data frame containing model variables.}
  \item{failcode}{Integer code for the event of interest. Defaults to 1.}
  \item{cencode}{Integer code for censoring. Defaults to 0.}
  \item{...}{Additional arguments passed to \code{cmprsk::crr}.}
}
\value{A \code{crr} object.}
\description{Convenience wrapper around \code{cmprsk::crr} for Fine-Gray competing-risks models.}
\examples{
if (requireNamespace("cmprsk", quietly = TRUE)) {
  df <- data.frame(
    time = c(5, 6, 7),
    status = c(1, 2, 0),
    treatment = c(0, 1, 1)
  )
  pharma_competing_risks(survival::Surv(time, status) ~ treatment, df)
}
}
