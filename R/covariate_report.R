#' Generate analysis report
#'
#' Renders an analysis report summarizing model parameters and diagnostic plots.
#' Relative output paths are resolved from the caller's working directory.
#' Missing parent directories are created. The installed template is copied
#' to a temporary workspace, which is removed after rendering, including on
#' failure. Rendering requires Pandoc; PDF output also requires LaTeX.
#'
#' @param model A fitted mixed-effects model object.
#' @param data A data.frame used for diagnostics and tables.
#' @param output_format Output document format. Either 'html_document' or
#'   'pdf_document'.
#' @param output_file Optional path to the resulting file. Defaults to a
#'   temporary file. If the filename has no extension, the renderer appends
#'   one for the selected format. Existing output files may be overwritten.
#'
#' @return The absolute path to the file produced by the renderer.
#' @examples
#' \dontrun{
#' model <- nlme::lme(DV ~ Time, random = ~ 1 | SubjectID, data = example_data)
#' generate_report(model, example_data)
#' }
#' @export
generate_report <- function(model, data,
                            output_format = c("html_document", "pdf_document"),
                            output_file = NULL) {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("Package 'rmarkdown' is required for report generation.")
  }

  output_format <- match.arg(output_format)
  template <- system.file("templates", "covariate-report.Rmd", package = "PharmaStatsR")
  if (template == "") {
    stop("Report template not found.")
  }
  if (is.null(output_file)) {
    ext <- if (output_format == "html_document") ".html" else ".pdf"
    output_file <- tempfile(fileext = ext)
  }
  if (!is.character(output_file) || !is.null(dim(output_file)) ||
    length(output_file) != 1L || is.na(output_file) ||
    !nzchar(trimws(output_file))) {
    stop("`output_file` must be a single nonempty file path")
  }
  output_file <- path.expand(output_file)
  if (dir.exists(output_file) || basename(output_file) %in% c(".", "..") ||
    grepl("[/\\\\]$", output_file)) {
    stop("`output_file` must name a file, not a directory")
  }
  output_dir <- dirname(output_file)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(output_dir)) {
    stop("Cannot create the report output directory")
  }
  output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)

  render_dir <- tempfile("pharmocovr-report-")
  if (!dir.create(render_dir)) {
    stop("Cannot create the temporary report workspace")
  }
  render_dir <- normalizePath(render_dir, winslash = "/", mustWork = TRUE)
  on.exit(unlink(render_dir, recursive = TRUE), add = TRUE)
  local_template <- file.path(render_dir, "report.Rmd")
  if (!file.copy(template, local_template)) {
    stop("Cannot copy the report template to the temporary workspace")
  }

  rendered <- rmarkdown::render(
    input = local_template,
    output_format = output_format,
    output_file = basename(output_file),
    output_dir = output_dir,
    intermediates_dir = render_dir,
    knit_root_dir = render_dir,
    quiet = TRUE,
    params = list(model = model, data = data),
    envir = new.env(parent = baseenv())
  )

  normalizePath(rendered, winslash = "/", mustWork = TRUE)
}
