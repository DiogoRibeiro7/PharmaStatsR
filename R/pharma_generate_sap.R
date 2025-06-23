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
#' @param objectives Text describing study objectives.
#' @param endpoints Text describing the study endpoints.
#' @param populations Text describing analysis populations.
#' @param methods Text describing planned analyses.
#' @param criteria Text describing inclusion/exclusion criteria.
#' @param software Text describing the software to be used.
#' @param extra_sections Named list of additional sections and their contents.
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
#'
#' pharma_generate_sap(
#'   objectives = "Assess efficacy and safety",
#'   endpoints = "Overall survival",
#'   extra_sections = list(Timeline = "Study visit schedule")
#' )
pharma_generate_sap <- function(path = NULL,
                                title = "Untitled Study",
                                author = "Diogo Ribeiro",
                                objectives = "Describe the primary and secondary objectives of the study.",
                                endpoints = "List the primary and secondary endpoints.",
                                populations = "Define analysis populations such as ITT and safety sets.",
                                methods = "Outline the statistical methods that will be used, including any adjustments for multiplicity or interim analyses.",
                                criteria = "Specify key inclusion and exclusion criteria.",
                                software = "Specify the software packages and versions that will be used.",
                                extra_sections = NULL) {
  # base sections for the SAP template
  sap_text <- c(
    paste0("# Statistical Analysis Plan - ", title),
    "",
    paste0("Author: ", author),
    "",
    "## Objectives",
    objectives,
    "",
    "## Endpoints",
    endpoints,
    "",
    "## Analysis Populations",
    populations,
    "",
    "## Inclusion/Exclusion Criteria",
    criteria,
    "",
    "## Planned Analyses",
    methods,
    "",
    "## Software",
    software
  )

  # append any user-defined sections
  if (!is.null(extra_sections) && length(extra_sections) > 0) {
    for (nm in names(extra_sections)) {
      sap_text <- c(sap_text, "", paste0("## ", nm), extra_sections[[nm]])
    }
  }

  # optionally write the template to disk
  if (!is.null(path)) {
    writeLines(sap_text, path)
    return(invisible(sap_text))
  }

  # return the assembled template
  sap_text
}
