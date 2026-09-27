#' Verify a local HMAC audit log
#'
#' Recomputes the HMAC-SHA256 for every record and checks the link to the
#' preceding record. Malformed CSV files and mismatched hashes return
#' `FALSE`; a missing file or invalid argument raises an error.
#'
#' @param file One nonempty path to an existing CSV audit log.
#' @param key One nonempty, nonmissing character string used to write the log.
#'
#' @return One logical value: `TRUE` if every stored row verifies, otherwise
#'   `FALSE`.
#' @details
#' This checks only the rows present in the file. Deleting the final row or
#' rows leaves a valid prefix, which cannot be detected without an external
#' record of the expected final hash or length.
#' @export
#'
#' @examples
#' if (requireNamespace("openssl", quietly = TRUE)) {
#'   f <- tempfile()
#'   pharma_audit_log("start", f, key = "example-key")
#'   pharma_audit_log("next", f, key = "example-key")
#'   pharma_audit_verify(f, key = "example-key")
#' }
pharma_audit_verify <- function(file = "audit.log", key) {
  valid_text <- function(x) {
    is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
  }
  if (!valid_text(file)) {
    stop("file must be one nonempty path", call. = FALSE)
  }
  if (!file.exists(file)) {
    stop("Log file does not exist", call. = FALSE)
  }
  if (missing(key) || !valid_text(key)) {
    stop("key must be one nonempty character string", call. = FALSE)
  }
  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop("Package 'openssl' is required for pharma_audit_verify()",
         call. = FALSE)
  }

  # Read all fields as literal strings so a message equal to "NA" is retained.
  log <- tryCatch(
    utils::read.csv(
      file, colClasses = "character", na.strings = character(),
      stringsAsFactors = FALSE
    ),
    error = function(e) NULL,
    warning = function(w) NULL
  )
  fields <- c("step", "timestamp", "previous_hash", "hash")
  if (is.null(log) || !identical(names(log), fields) ||
      nrow(log) == 0L ||
      anyNA(log[c("step", "timestamp", "hash")]) ||
      any(!nzchar(log$timestamp)) || any(!nzchar(log$hash))) {
    return(FALSE)
  }
  if (log$step[[1L]] != "genesis" ||
      (!is.na(log$previous_hash[[1L]]) &&
       !(log$previous_hash[[1L]] %in% c("", "NA")))) {
    return(FALSE)
  }
  if (nrow(log) > 1L &&
      (anyNA(log$previous_hash[-1L]) ||
       any(!nzchar(log$previous_hash[-1L])))) {
    return(FALSE)
  }

  for (i in seq_len(nrow(log))) {
    previous_hash <- if (i == 1L) NA_character_ else log$hash[[i - 1L]]
    if (i > 1L && !identical(log$previous_hash[[i]], previous_hash)) {
      return(FALSE)
    }
    expected <- as.character(openssl::sha256(
      paste(log$step[[i]], log$timestamp[[i]], previous_hash), key = key
    ))
    if (!identical(log$hash[[i]], expected)) {
      return(FALSE)
    }
  }
  TRUE
}
