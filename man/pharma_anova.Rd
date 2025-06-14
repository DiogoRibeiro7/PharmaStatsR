\name{pharma_anova}
\alias{pharma_anova}
\title{Conduct a one-way ANOVA}
\usage{pharma_anova(formula, data, ...)}
\arguments{
  \item{formula}{Model formula specifying outcome and group.}
  \item{data}{Data frame containing variables used in the model.}
  \item{...}{Additional arguments passed to \code{aov}.}
}
\value{An object of class \code{aov}.}
\description{Wrapper around \code{stats::aov} for comparing means across groups.}
\examples{pharma_anova(response ~ treatment, data = pharma_sample)}
