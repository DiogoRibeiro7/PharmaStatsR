#' Verify a blockchain-like audit trail
#'
#' Checks that each entry in an audit log created with
#' `pharma_audit_log()` correctly links to the previous entry via its
#' HMAC-SHA256 hash. The hash is recomputed from the stored message,
#' timestamp and previous hash so any tampering with the log is
#' detected. Returns `TRUE` if the chain is valid.
#'
#' @param file Path to the CSV log file. Defaults to "audit.log".
#' @param key Character string with the secret key used when logging.
#'   The verification recalculates HMAC signatures with this key and
#'   ensures each entry links to the previous one.
#'
#' @return Logical `TRUE` if the log is intact, otherwise `FALSE`.
#' @export
#'
#' @examples
#' f <- tempfile()
#' pharma_audit_log("start", f, key = "secret")
#' pharma_audit_log("next", f, key = "secret")
#' pharma_audit_verify(f, key = "secret")
pharma_audit_verify <- function(file = "audit.log", key) {
  if (!file.exists(file)) {
    stop("Log file does not exist")
  }
  if (missing(key) || !is.character(key) || length(key) != 1) {
    stop("key must be a single character string")
  }
  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop("Package 'openssl' is required for pharma_audit_verify()")
  }
  log <- utils::read.csv(file, stringsAsFactors = FALSE)
  if (nrow(log) == 0) {
    return(FALSE)
  }
  for (i in seq_len(nrow(log))) {
    if (i == 1) {
      if (log$step[i] != "genesis") {
        return(FALSE)
      }
      expected <- openssl::sha256(
        paste("genesis", log$timestamp[i], NA_character_),
        key = key
      )
      if (!identical(log$hash[i], expected)) {
        return(FALSE)
      }
    } else {
      prev <- log$hash[i - 1]
      if (log$previous_hash[i] != prev) {
        return(FALSE)
      }
      expected <- openssl::sha256(
        paste(log$step[i], log$timestamp[i], prev),
        key = key
      )
      if (!identical(log$hash[i], expected)) {
        return(FALSE)
      }
    }
  }
  TRUE
}
