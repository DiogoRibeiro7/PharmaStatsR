#' Generate a statistical analysis plan (SAP) template
#'
#' Creates a basic Markdown template for a statistical analysis plan. The
#' template includes placeholders for study objectives, endpoints, and
#' planned analyses. The resulting text can be returned as a character
#' vector or written directly to a file.
#'
#' @param path Character string. Optional output file path to save the
#'   generated Markdown. If `NULL`, the function returns the text instead
#'   of writing to disk.
#' @param title Character string with the study title. Defaults to
#'   "Untitled Study".
#' @param author Character string with the author name. Defaults to
#'   "Diogo Ribeiro".
#'
#' @return A character vector containing the SAP in Markdown format. If
#'   `path` is provided, the text is invisibly returned after being written
#'   to that location.
#' @export
#'
#' @examples
#' sap <- pharma_generate_sap()
#' cat(sap, sep = "\n")
#' 
#' pharma_generate_sap("analysis_plan.md",
#'                     title = "Clinical Trial",
#'                     author = "Diogo Ribeiro")
pharma_generate_sap <- function(path = NULL,
                                title = "Untitled Study",
                                author = "Diogo Ribeiro") {
  sap_text <- c(
    paste0("# Statistical Analysis Plan - ", title),
    "",
    paste0("Author: ", author),
    "",
    "## Objectives",
    "Describe the primary and secondary objectives of the study.",
    "",
    "## Endpoints",
    "List the primary and secondary endpoints.",
    "",
    "## Analysis Populations",
    "Define analysis populations such as ITT and safety sets.",
    "",
    "## Planned Analyses",
    "Outline the statistical methods that will be used, including",
    "any adjustments for multiplicity or interim analyses.",
    "",
    "## Software",
    "Specify the software packages and versions that will be used."
  )

  if (!is.null(path)) {
    writeLines(sap_text, path)
    return(invisible(sap_text))
  }

  sap_text
}
