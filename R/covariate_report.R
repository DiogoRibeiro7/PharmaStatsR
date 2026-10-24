#' Generate analysis report
#'
#' Renders a fixed-effects table and diagnostic plots for a native `nlme::lme`
#' model. The table always uses `summary(model)$tTable`, independently of
#' `broom.mixed` availability. It includes estimates, standard errors,
#' denominator degrees of freedom, t statistics and two-sided p-values, retaining
#' native summary defaults (including the default sigma adjustment for ML fits).
#' Numeric values display six significant digits; p-values below `1e-6` display
#' as `<1e-6`. Coefficient labels are escaped for HTML/PDF output. Obtain full
#' precision from the fitted model; the report does not return a numeric table.
#' Random-effect and residual variance rows are not included.
#'
#' Diagnostics retain native model defaults, including fitted subject effects.
#' See [plot_obs_vs_pred()] and [plot_residuals()] for data and row-alignment
#' requirements. This report does not validate a model or add simultaneous
#' inference, post-selection adjustments, or predictive uncertainty.
#'
#' Relative output paths are resolved from the caller's working directory.
#' Missing parent directories are created. The installed template is copied
#' to a temporary workspace, which is removed after rendering, including on
#' failure. Rendering requires Pandoc; PDF output also requires LaTeX.
#'
#' @param model A native `nlme::lme` fitted model with stored data containing
#'   numeric `Time`. Residuals must align with those stored rows; use
#'   `na.exclude` when fitting with omitted rows.
#' @param data A uniquely named `data.frame` for observed/predicted diagnostics,
#'   containing numeric `DV` and the native model's required prediction columns.
#'   The fixed-effects table and residual plot use the fitted model, not this
#'   table. Renamed/repaired models require their native predictor names and
#'   the diagnostic `DV`/`Time` columns; no automatic name mapping is performed.
#' @param output_format Output document format. Either 'html_document' or
#'   'pdf_document'.
#' @param output_file Optional path to the resulting file. Defaults to a
#'   temporary file. If the filename has no extension, the renderer appends
#'   one for the selected format. Existing output files may be overwritten.
#'
#' @return The absolute path to the file produced by the renderer.
#' @examples
#' \dontrun{
#' df <- data.frame(SubjectID = rep(1:4, each = 3), Time = rep(c(-1, 0, 1), 4))
#' df$DV <- 2 + 1.5 * df$Time + rep(c(-3, -1, 1, 3), each = 3) +
#'   rep(c(1, -2, 1), 4)
#' model <- fit_covariate_model(df, "DV", "SubjectID", "Time")
#' generate_report(model, df)
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
