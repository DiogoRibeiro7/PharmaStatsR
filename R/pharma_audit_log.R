#' Record an analysis step in a blockchain-like audit trail
#'
#' Appends a hashed entry to a CSV log file. Each entry stores the
#' SHA256 hash of the message, timestamp and previous hash so that
#' tampering with any record invalidates the subsequent chain. This
#' provides a lightweight append-only log using the `digest` package.
#'
#' @param message Character string describing the analysis step.
#' @param file Path to the CSV log file. If the file does not exist, a
#'   new log is created with a genesis block.
#' @param key Character string used as the secret key for the HMAC
#'   signature. Each entry is signed with this key so any
#'   modification can be detected during verification.
#'
#' @return Invisibly returns the path to the log file.
#' @export
#'
#' @examples
#' tmp <- tempfile()
#' pharma_audit_log("Load data", tmp)
#' pharma_audit_log("Fit model", tmp)
#' read.csv(tmp)
pharma_audit_log <- function(message,
                             file = "audit.log",
                             key) {
  if (!is.character(message) || length(message) != 1) {
    stop("message must be a single character string")
  }
  if (missing(key) || !is.character(key) || length(key) != 1) {
    stop("key must be a single character string")
  }

  if (!requireNamespace("digest", quietly = TRUE)) {
    stop("Package 'digest' is required for pharma_audit_log()")
  }

  if (!file.exists(file)) {
    genesis_timestamp <- format(Sys.time(), tz = "UTC", usetz = TRUE)
    genesis_hash <- digest::hmac(
      key,
      paste("genesis", genesis_timestamp, NA_character_),
      algo = "sha256"
    )
    log <- data.frame(
      step = "genesis",
      timestamp = genesis_timestamp,
      previous_hash = NA_character_,
      hash = genesis_hash,
      stringsAsFactors = FALSE
    )
    utils::write.csv(log, file, row.names = FALSE)
  } else {
    log <- utils::read.csv(file, stringsAsFactors = FALSE)
  }

  timestamp <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  prev_hash <- tail(log$hash, 1)
  entry_hash <- digest::hmac(key, paste(message, timestamp, prev_hash), algo = "sha256")
  entry <- data.frame(
    step = message,
    timestamp = timestamp,
    previous_hash = prev_hash,
    hash = entry_hash,
    stringsAsFactors = FALSE
  )
  utils::write.table(entry, file,
    sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE
  )
  invisible(file)
}
