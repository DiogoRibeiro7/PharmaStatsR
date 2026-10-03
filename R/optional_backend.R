# Check a Suggested backend at the point of use. A separate availability
# function lets tests exercise missing-package behavior on CI machines that
# have the package installed.
.pharma_optional_available <- function(package) {
  requireNamespace(package, quietly = TRUE)
}

.pharma_require_optional <- function(package, caller) {
  if (!.pharma_optional_available(package)) {
    stop("Package '", package, "' is required for ", caller, "(). ",
         "Install it with install.packages('", package, "').",
         call. = FALSE)
  }
  invisible(TRUE)
}
