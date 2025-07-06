#' Initialize or reset audit blockchain
#'
#' Creates an empty blockchain ledger for storing analysis audit information.
#'
#' @return Invisible `NULL`.
#' @export
pharma_audit_init <- function() {
  genesis <- list(
    index = 1,
    timestamp = Sys.time(),
    name = "genesis",
    result_hash = NA_character_,
    prev_hash = "0"
  )
  genesis$hash <- digest::digest(genesis, algo = "sha256")
  assign(".pharma_audit_chain", list(genesis), envir = .GlobalEnv)
  invisible(NULL)
}

#' Log an analysis result to the audit blockchain
#'
#' Adds a block containing a hash of the result and metadata to the
#' blockchain-based audit trail.
#'
#' @param name Character string describing the analysis.
#' @param result Object containing the analysis result to hash.
#'
#' @return Invisible `NULL`.
#' @examples
#' pharma_audit_init()
#' pharma_audit_log("t_test", t.test(1:10, 11:20))
#' pharma_audit_get()
#' @export
pharma_audit_log <- function(name, result) {
  if (!exists(".pharma_audit_chain", envir = .GlobalEnv)) {
    stop("Audit chain not initialized. Run pharma_audit_init().")
  }
  chain <- get(".pharma_audit_chain", envir = .GlobalEnv)
  prev_hash <- chain[[length(chain)]]$hash
  block <- list(
    index = length(chain) + 1,
    timestamp = Sys.time(),
    name = name,
    result_hash = digest::digest(result, algo = "sha256"),
    prev_hash = prev_hash
  )
  block$hash <- digest::digest(block, algo = "sha256")
  assign(".pharma_audit_chain", c(chain, list(block)), envir = .GlobalEnv)
  invisible(NULL)
}

#' Retrieve the audit blockchain
#'
#' Returns a data frame representing the current audit chain.
#'
#' @return A `data.frame` of blockchain entries.
#' @export
pharma_audit_get <- function() {
  if (!exists(".pharma_audit_chain", envir = .GlobalEnv)) {
    stop("Audit chain not initialized. Run pharma_audit_init().")
  }
  chain <- get(".pharma_audit_chain", envir = .GlobalEnv)
  do.call(rbind, lapply(chain, as.data.frame))
}
