#!/usr/bin/env Rscript

# Confirm that the all-Suggests check can load each declared R package.
description <- "DESCRIPTION"
if (!file.exists(description)) {
  stop("Run this script from the package root.", call. = FALSE)
}

metadata <- read.dcf(description, fields = "Suggests")
if (!is.matrix(metadata) || nrow(metadata) != 1L ||
    !("Suggests" %in% colnames(metadata)) ||
    is.na(metadata[1L, "Suggests"]) ||
    !nzchar(trimws(metadata[1L, "Suggests"]))) {
  stop("DESCRIPTION must have a nonempty Suggests field.", call. = FALSE)
}

entries <- trimws(strsplit(metadata[1L, "Suggests"], ",", fixed = TRUE)[[1L]])
packages <- trimws(sub("\\s*\\(.*$", "", entries))
if (anyNA(packages) || any(!nzchar(packages)) ||
    anyDuplicated(packages) > 0L) {
  stop("DESCRIPTION has an invalid or duplicate Suggested package.", call. = FALSE)
}

available <- vapply(packages, requireNamespace, logical(1L), quietly = TRUE)
if (!all(available)) {
  stop("Missing Suggested packages: ",
       paste(packages[!available], collapse = ", "), call. = FALSE)
}

versions <- vapply(packages, function(package) {
  as.character(utils::packageVersion(package))
}, character(1L))
message("Verified all ", length(packages), " Suggested R packages: ",
        paste(paste(packages, versions, sep = "="), collapse = ", "))
