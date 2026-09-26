\name{pharma_register_stat}
\alias{pharma_register_stat}
\alias{pharma_unregister_stat}
\alias{pharma_list_stats}
\alias{pharma_run_stat}
\title{Register and manage custom statistical methods}
\description{Utilities to register, list, run, and unregister custom statistical methods for PharmaStatsR.}
\usage{
pharma_register_stat(name, fun)
pharma_unregister_stat(name)
pharma_list_stats()
pharma_run_stat(name, ...)
}
\arguments{
\item{name}{Name of the method.}
\item{fun}{Function implementing the method.}
\item{...}{Arguments passed to the method.}
}
\value{\code{pharma_register_stat} and \code{pharma_unregister_stat} return invisible \code{TRUE} on success. \code{pharma_list_stats} returns a character vector of method names. \code{pharma_run_stat} returns the result of the specified method.}
\examples{
pharma_register_stat("mean_method", mean)
pharma_run_stat("mean_method", 1:3)
pharma_unregister_stat("mean_method")
}
