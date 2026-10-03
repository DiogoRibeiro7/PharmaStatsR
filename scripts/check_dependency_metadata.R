#!/usr/bin/env Rscript

# Check qualified calls and literal optional-package guards against DESCRIPTION.
# The base namespace is supplied by R and does not need a dependency entry.
root <- getwd()
description <- file.path(root, "DESCRIPTION")
source_dir <- file.path(root, "R")
if (!file.exists(description) || !dir.exists(source_dir)) {
  stop("Run this script from the package root.", call. = FALSE)
}

metadata <- read.dcf(description)
fields <- intersect(c("Depends", "Imports", "Suggests", "Enhances"),
                    colnames(metadata))
entries <- unlist(lapply(fields, function(field) {
  strsplit(metadata[1L, field], ",", fixed = TRUE)[[1L]]
}), use.names = FALSE)
declared <- trimws(sub("\\s*\\(.*$", "", entries))

# The shared guard receives a literal package name at its public entry points.
# Other guards with variable package names (dashboards and exporters) are
# reviewed in docs/dependency-audit.md.
literal_guards <- function(expr) {
  if (is.call(expr)) {
    fun <- expr[[1L]]
    args <- as.list(expr)[-1L]
    package <- character()
    if (is.symbol(fun) && as.character(fun) %in%
        c("requireNamespace", ".pharma_require_optional") &&
        length(args) > 0L && is.character(args[[1L]]) &&
        length(args[[1L]]) == 1L) {
      package <- args[[1L]]
    }
    return(c(package, unlist(lapply(args, literal_guards), use.names = FALSE)))
  }
  if (is.expression(expr) || is.pairlist(expr) || is.list(expr)) {
    return(unlist(lapply(as.list(expr), literal_guards), use.names = FALSE))
  }
  character()
}

files <- list.files(source_dir, pattern = "\\.R$", full.names = TRUE)
used <- unlist(lapply(files, function(file) {
  source <- parse(file = file, keep.source = TRUE)
  tokens <- utils::getParseData(source)
  c(tokens$text[tokens$token == "SYMBOL_PACKAGE"], literal_guards(source))
}), use.names = FALSE)
if (length(used) == 0L) {
  stop("No package references found in R source files.", call. = FALSE)
}

undeclared <- setdiff(sort(unique(used)), c(declared, "base"))
if (length(undeclared) > 0L) {
  stop("Package references missing from DESCRIPTION: ",
       paste(undeclared, collapse = ", "), call. = FALSE)
}
message("Qualified calls and literal package guards are declared in DESCRIPTION.")
