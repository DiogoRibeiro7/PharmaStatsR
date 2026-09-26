\name{pharma_network_meta_analysis}
\alias{pharma_network_meta_analysis}
\title{Network meta-analysis}
\usage{
pharma_network_meta_analysis(TE, seTE, treat1, treat2, data = NULL, sm = "MD", random = TRUE, ...)
}
\arguments{
  \item{TE}{Numeric vector of treatment effect estimates.}
  \item{seTE}{Numeric vector of standard errors for the effect estimates.}
  \item{treat1}{Character vector specifying the first treatment in each comparison.}
  \item{treat2}{Character vector specifying the second treatment in each comparison.}
  \item{data}{Optional data frame containing the variables.}
  \item{sm}{Summary measure passed to \code{netmeta::netmeta}.}
  \item{random}{Logical indicating if a random-effects model is fitted.}
  \item{...}{Additional arguments passed to \code{netmeta::netmeta}.}
}
\value{
A \code{netmeta} object.
}
\description{
Fit a network meta-analysis using \code{netmeta::netmeta} to compare multiple treatments across studies.
Requires the 'netmeta' package to be installed.
}
\examples{
if (requireNamespace("netmeta", quietly = TRUE)) {
df <- data.frame(
  treat1 = c("A", "A", "B"),
  treat2 = c("B", "C", "C"),
  TE = c(0.2, 0.5, -0.1),
  seTE = c(0.1, 0.2, 0.1)
)
pharma_network_meta_analysis(TE, seTE, treat1, treat2, data = df)
}
}
