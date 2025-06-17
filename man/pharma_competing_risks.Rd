\name{pharma_competing_risks}
\alias{pharma_competing_risks}
\title{Competing-risks regression}
\usage{pharma_competing_risks(formula, data, failcode = 1, cencode = 0, ...)}
\arguments{
  \item{formula}{\code{Surv(time, status) ~ predictors}.}
  \item{data}{Data frame with model variables.}
  \item{failcode}{Event code of interest.}
  \item{cencode}{Code for censoring.}
  \item{...}{Additional arguments passed to \code{crr}.}
}
\value{A \code{crr} object.}
\description{Wrapper around \code{cmprsk::crr} for Fine-Gray models.}
\examples{
# pharma_competing_risks(Surv(time, status) ~ treatment, df)
}
