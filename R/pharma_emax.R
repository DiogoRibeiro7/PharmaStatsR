#' Fit an Emax dose-response model
#'
#' Convenience wrapper around \code{nls} for fitting a standard Emax model.
#'
#' @param dose Numeric vector of doses.
#' @param response Numeric vector of responses.
#' @param start Named list of starting values for \code{e0}, \code{emax}, and \code{ed50}.
#'   Defaults to basic guesses.
#' @param ... Additional arguments passed to \code{nls}.
#'
#' @return An \code{nls} object.
#' @export
#'
#' @examples
#' pharma_emax(
#'   pharma_dose_response$dose,
#'   pharma_dose_response$response
#' )
pharma_emax <- function(dose, response,
                        start = list(
                          e0 = min(response),
                          emax = max(response) - min(response),
                          ed50 = stats::median(dose)
                        ),
                        ...) {
  stats::nls(response ~ e0 + (emax * dose) / (ed50 + dose),
    start = start, ...
  )
}

#' Fit a sigmoid Emax model
#'
#' Wrapper around \code{nls} for a four-parameter sigmoid Emax (Hill) model.
#'
#' @param dose Numeric vector of doses.
#' @param response Numeric vector of responses.
#' @param start Named list of starting values for \code{e0}, \code{emax},\code{ed50}, and \code{h}.
#' @param ... Additional arguments passed to \code{nls}.
#'
#' @return An \code{nls} object.
#' @export
#'
#' @examples
#' pharma_sigmoid_emax(
#'   pharma_dose_response$dose,
#'   pharma_dose_response$response
#' )
pharma_sigmoid_emax <- function(dose, response,
                                start = list(
                                  e0 = min(response),
                                  emax = max(response) - min(response),
                                  ed50 = stats::median(dose),
                                  h = 1
                                ),
                                ...) {
  stats::nls(response ~ e0 + (emax * dose^h) / (ed50^h + dose^h),
    start = start, ...
  )
}

#' Fit a mixed-effects Emax model using nlme
#'
#' Convenience wrapper around \code{nlme::nlme} for repeated measures of Emax
#' curves. The wrapper sets `nlmeControl(returnObject = TRUE)`, so reaching
#' the iteration limit may return an object with a nonconvergence warning.
#'
#' @param dose Numeric vector of doses.
#' @param response Numeric vector of responses.
#' @param subject Subject identifier for random effects.
#' @param start Named vector of starting values for \code{e0}, \code{emax}, and
#'   \code{ed50}. If `NULL`, coefficients from a pooled `nls` fit are used.
#' @param random Random-effects formula. Defaults to a subject-specific baseline.
#' @param ... Additional arguments passed to \code{nlme::nlme}.
#'
#' @return An \code{nlme} object inheriting from \code{lme}.
#' @export
#'
#' @examples
#' pharma_emax_nlme(pharma_dose_response$dose,
#'   pharma_dose_response$response,
#'   subject = pharma_dose_response$subject
#' )
pharma_emax_nlme <- function(dose, response, subject,
                             start = NULL,
                             random = e0 ~ 1 | subject, ...) {
  if (!requireNamespace("nlme", quietly = TRUE)) {
    stop("Package 'nlme' is required for pharma_emax_nlme()")
  }
  data <- data.frame(subject = subject, dose = dose, response = response)
  if (is.null(start)) {
    nls_fit <- stats::nls(response ~ e0 + (emax * dose) / (ed50 + dose),
      data = data,
      start = list(
        e0 = min(response),
        emax = max(response) - min(response),
        ed50 = stats::median(dose)
      )
    )
    start <- stats::coef(nls_fit)
  }
  nlme::nlme(response ~ e0 + (emax * dose) / (ed50 + dose),
    data = data,
    fixed = e0 + emax + ed50 ~ 1,
    random = random,
    start = start,
    control = nlme::nlmeControl(returnObject = TRUE),
    ...
  )
}
