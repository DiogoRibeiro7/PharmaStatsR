\name{pharma_crossover}
\docType{data}
\alias{pharma_crossover}
\title{Simulated crossover trial dataset}
\format{A data frame with 20 rows and 5 variables:
\describe{
  \item{subject}{Subject factor, levels 1 to 10}
  \item{period}{Period factor, levels 1 and 2}
  \item{treatment}{Treatment factor, levels A and B}
  \item{response}{Numeric illustrative response (unitless)}
  \item{outcome}{Arbitrary binary example label, 0 or 1; not a defined clinical event}
}}
\source{Hand-entered illustrative values in the package source.}
\description{A hand-entered, balanced two-period AB/BA illustration with ten
subjects: five receive A then B and five B then A. These are not clinical records.}
\details{One observation per subject and period. Use for a complete AB/BA
additive crossover ANOVA; these data do not establish bioequivalence or
identify carryover effects.}
\examples{head(pharma_crossover)}
