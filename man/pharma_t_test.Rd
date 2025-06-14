\name{pharma_t_test}
\alias{pharma_t_test}
\title{Conduct a two-sample t-test}
\usage{pharma_t_test(x, y, ...)}
\arguments{
  \item{x}{Numeric vector for group 1.}
  \item{y}{Numeric vector for group 2.}
  \item{...}{Additional arguments passed to \code{t.test}.}
}
\value{An object of class \code{htest}.}
\description{Wraps \code{stats::t.test} to compare two numeric samples.}
\examples{
pharma_t_test(rnorm(10), rnorm(10))
}
