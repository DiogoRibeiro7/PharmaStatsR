#' Verify a blockchain-like audit trail
#'
#' Checks that each entry in an audit log created with
#' `pharma_audit_log()` correctly links to the previous entry via its
#' SHA256 hash. The hash is recomputed from the stored message,
#' timestamp and previous hash so any tampering with the log is
#' detected. Returns `TRUE` if the chain is valid.
#'
#' @param file Path to the CSV log file. Defaults to "audit.log".
#' @param key Deprecated and ignored. It is kept for backward compatibility
#'   but not used.
#'
#' @return Logical `TRUE` if the log is intact, otherwise `FALSE`.
#' @export
#'
#' @examples
#' f <- tempfile()
#' pharma_audit_log("start", f)
#' pharma_audit_log("next", f)
#' pharma_audit_verify(f)
pharma_audit_verify <- function(file = "audit.log", key = NULL) {
  if (!file.exists(file)) {
    stop("Log file does not exist")
  }
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop("Package 'digest' is required for pharma_audit_verify()")
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
      expected <- digest::digest(
        paste("genesis", log$timestamp[i], NA_character_),
        algo = "sha256"
      )
      if (log$hash[i] != expected) {
        return(FALSE)
      }
    } else {
      prev <- log$hash[i - 1]
      if (log$previous_hash[i] != prev) {
        return(FALSE)
      }
      expected <- digest::digest(
        paste(log$step[i], log$timestamp[i], prev),
        algo = "sha256"
      )
      if (log$hash[i] != expected) {
        return(FALSE)
      }
    }
  }
  TRUE
}
