\name{pharma_landmark_analysis}
\alias{pharma_landmark_analysis}
\title{Landmark analysis}
\usage{pharma_landmark_analysis(formula, data, landmark, ...)}
\arguments{
  \item{formula}{\code{Surv(time, status) ~ predictors}.}
  \item{data}{Data frame with model variables.}
  \item{landmark}{Landmark time.}
  \item{...}{Additional arguments passed to \code{coxph}.}
}
\value{A \code{coxph} object fitted on landmarked data.}
\description{Fits a Cox model on subjects who survive past the landmark time.}
\examples{
# pharma_landmark_analysis(Surv(time, status) ~ trt, df, landmark = 12)
}
