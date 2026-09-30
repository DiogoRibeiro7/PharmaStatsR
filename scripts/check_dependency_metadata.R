#!/usr/bin/env Rscript

# Check namespace-qualified calls in package R code against DESCRIPTION.
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

files <- list.files(source_dir, pattern = "\\.R$", full.names = TRUE)
used <- unlist(lapply(files, function(file) {
  tokens <- utils::getParseData(parse(file = file, keep.source = TRUE))
  tokens$text[tokens$token == "SYMBOL_PACKAGE"]
}), use.names = FALSE)
if (length(used) == 0L) {
  stop("No namespace calls found in R source files.", call. = FALSE)
}

undeclared <- setdiff(sort(unique(used)), c(declared, "base"))
if (length(undeclared) > 0L) {
  stop("Namespace calls missing from DESCRIPTION: ",
       paste(undeclared, collapse = ", "), call. = FALSE)
}
message("Namespace calls are declared in DESCRIPTION.")
