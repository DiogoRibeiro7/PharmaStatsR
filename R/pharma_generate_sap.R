#' Generate a statistical analysis plan (SAP) template
#'
#' Creates a basic Markdown template for a statistical analysis plan. The
#' template includes placeholders for study objectives, endpoints, and
#' planned analyses. The resulting text can be returned as a character
#' vector or written directly to a file. It does not supply, review, or
#' approve a study-specific analysis plan; the caller must complete and
#' review every relevant section before use. Section text may be an empty
#' string when it will be completed later.
#'
#' @param path Character string. Optional output file path to save the
#'   generated Markdown. If `NULL`, the function returns the text instead
#'   of writing to disk.
#' @param title Single, non-missing character string with the study title.
#'   Defaults to "Untitled Study".
#' @param author Single, non-missing character string with the author name.
#'   Defaults to "Diogo Ribeiro".
#' @param objectives Single, non-missing character string describing objectives.
#' @param endpoints Single, non-missing character string describing endpoints.
#' @param populations Single, non-missing character string describing populations.
#' @param methods Single, non-missing character string describing analyses.
#' @param criteria Single, non-missing character string describing criteria.
#' @param software Single, non-missing character string describing software.
#' @param extra_sections Named list of additional sections, each containing a
#'   single, non-missing character string. Names must be nonblank, unique, and
#'   distinct from the default section names. `NULL` or `list()` adds none.
#' @param include_sections Character vector giving the order of default sections
#'   to include: "Objectives", "Endpoints", "Analysis Populations",
#'   "Inclusion/Exclusion Criteria", "Planned Analyses", and "Software".
#'   Names must be nonblank, unique, and supported. Set to `NULL` to omit
#'   all defaults; an empty character vector is invalid.
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
#' pharma_generate_sap(tempfile(fileext = ".md"),
#'   title = "Clinical Trial",
#'   author = "Diogo Ribeiro"
#' )
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
                                methods = "Describe the methods, including multiplicity and interim analyses.",
                                criteria = "Specify key inclusion and exclusion criteria.",
                                software = "Specify the software packages and versions that will be used.",
                                extra_sections = NULL,
                                include_sections = c(
                                  "Objectives", "Endpoints", "Analysis Populations",
                                  "Inclusion/Exclusion Criteria", "Planned Analyses", "Software"
                                )) {
  defaults <- list(
    "Objectives" = objectives,
    "Endpoints" = endpoints,
    "Analysis Populations" = populations,
    "Inclusion/Exclusion Criteria" = criteria,
    "Planned Analyses" = methods,
    "Software" = software
  )

  check_text <- function(value, argument) {
    if (!is.character(value) || length(value) != 1L || is.na(value)) {
      stop(argument, " must be a single, non-missing character string.", call. = FALSE)
    }
  }

  check_text(title, "title")
  check_text(author, "author")
  section_arguments <- c(
    "objectives", "endpoints", "populations", "criteria", "methods", "software"
  )
  for (i in seq_along(defaults)) {
    check_text(defaults[[i]], section_arguments[[i]])
  }

  if (!is.null(include_sections)) {
    if (!is.character(include_sections) || length(include_sections) == 0L) {
      stop("include_sections must be a nonempty character vector or NULL.", call. = FALSE)
    }
    if (anyNA(include_sections) || any(!nzchar(trimws(include_sections)))) {
      stop("include_sections must not contain missing or blank names.", call. = FALSE)
    }
    if (anyDuplicated(include_sections)) {
      stop("include_sections must not contain duplicate names.", call. = FALSE)
    }
    unknown <- setdiff(include_sections, names(defaults))
    if (length(unknown) > 0L) {
      stop(
        "Unknown include_sections: ", paste(sQuote(unknown), collapse = ", "),
        ". Supported sections: ", paste(names(defaults), collapse = ", "), ".",
        call. = FALSE
      )
    }
  }

  if (!is.null(extra_sections)) {
    if (!is.list(extra_sections)) {
      stop("extra_sections must be a named list or NULL.", call. = FALSE)
    }
    if (length(extra_sections) > 0L) {
      section_names <- names(extra_sections)
      if (is.null(section_names) || anyNA(section_names) ||
          any(!nzchar(trimws(section_names)))) {
        stop("extra_sections must have nonblank names for every section.", call. = FALSE)
      }
      if (anyDuplicated(section_names) || any(section_names %in% names(defaults))) {
        stop("extra_sections names must be unique and distinct from default sections.", call. = FALSE)
      }
      for (i in seq_along(extra_sections)) {
        argument <- paste0("extra_sections[[", sQuote(section_names[[i]]), "]]")
        check_text(extra_sections[[i]], argument)
      }
    }
  }

  sap_text <- c(
    paste0("# Statistical Analysis Plan - ", title),
    "",
    paste0("Author: ", author)
  )

  # Respect the requested order, then append custom sections.
  if (!is.null(include_sections)) {
    for (sec in include_sections) {
      sap_text <- c(sap_text, "", paste0("## ", sec), defaults[[sec]])
    }
  }
  if (!is.null(extra_sections)) {
    for (nm in names(extra_sections)) {
      sap_text <- c(sap_text, "", paste0("## ", nm), extra_sections[[nm]])
    }
  }

  # Optionally write the template to disk if a path is provided.
  if (!is.null(path)) {
    writeLines(sap_text, path)
    return(invisible(sap_text))
  }

  sap_text
}
