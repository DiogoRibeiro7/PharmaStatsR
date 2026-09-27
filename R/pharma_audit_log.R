#' Append a step to a local HMAC audit log
#'
#' Stores each message and UTC timestamp in a CSV file with an HMAC-SHA256
#' of that row and the preceding row's hash. Existing logs are verified
#' with the supplied key before an entry is appended.
#'
#' @param message One nonempty, nonmissing character string describing the step.
#' @param file One nonempty path to the CSV log. A missing file is initialized
#'   with a genesis row before the first entry.
#' @param key One nonempty, nonmissing character string used as the HMAC key.
#'   Keep it separate from the log and protect both.
#'
#' @return The path to the log file, invisibly.
#' @details
#' This local CSV helper does not prevent deletion of final rows or provide
#' concurrency control, access control, or secure storage for the key.
#' Verification is possible only for the records still present in the file.
#' @export
#'
#' @examples
#' if (requireNamespace("openssl", quietly = TRUE)) {
#'   tmp <- tempfile()
#'   pharma_audit_log("Load data", tmp, key = "example-key")
#'   pharma_audit_log("Fit model", tmp, key = "example-key")
#'   pharma_audit_verify(tmp, key = "example-key")
#' }
pharma_audit_log <- function(message, file = "audit.log", key) {
  valid_text <- function(x) {
    is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
  }
  if (!valid_text(message)) {
    stop("message must be one nonempty character string", call. = FALSE)
  }
  if (!valid_text(file)) {
    stop("file must be one nonempty path", call. = FALSE)
  }
  if (missing(key) || !valid_text(key)) {
    stop("key must be one nonempty character string", call. = FALSE)
  }
  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop("Package 'openssl' is required for pharma_audit_log()",
         call. = FALSE)
  }

  if (file.exists(file)) {
    # Never append after a failed key or chain check.
    if (!pharma_audit_verify(file, key = key)) {
      stop("Existing audit log failed verification; no entry appended",
           call. = FALSE)
    }
    previous_hash <- utils::tail(
      utils::read.csv(file, colClasses = "character", na.strings = character())$hash,
      1L
    )
  } else {
    genesis_timestamp <- format(Sys.time(), tz = "UTC", usetz = TRUE)
    previous_hash <- as.character(openssl::sha256(
      paste("genesis", genesis_timestamp, NA_character_), key = key
    ))
    genesis <- data.frame(
      step = "genesis",
      timestamp = genesis_timestamp,
      previous_hash = NA_character_,
      hash = previous_hash,
      stringsAsFactors = FALSE
    )
    utils::write.csv(genesis, file, row.names = FALSE)
  }

  timestamp <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  entry_hash <- as.character(openssl::sha256(
    paste(message, timestamp, previous_hash), key = key
  ))
  entry <- data.frame(
    step = message,
    timestamp = timestamp,
    previous_hash = previous_hash,
    hash = entry_hash,
    stringsAsFactors = FALSE
  )
  utils::write.table(
    entry, file, sep = ",", row.names = FALSE,
    col.names = FALSE, append = TRUE, qmethod = "double"
  )
  invisible(file)
}
