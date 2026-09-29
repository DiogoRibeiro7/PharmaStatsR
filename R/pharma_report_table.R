#' Extract selected model estimates into a table
#'
#' Select term, estimate, confidence interval, and p-value columns from
#' `broom::tidy()`. Results can optionally be written to Word (`.docx`)
#' or Excel (`.xlsx`) if the corresponding packages are available. The
#' helper does not apply an APA or ICH reporting standard, verify model
#' assumptions, or provide a study-specific interpretation.
#'
#' @param model A fitted model object whose `broom::tidy()` output includes
#'   `term`, `estimate`, `conf.low`, `conf.high`, and `p.value`.
#' @param file Optional path to save the table. Should end with \code{.docx} or
#'   \code{.xlsx}. If \code{NULL}, the table is returned as a data frame.
#' @param conf.level Confidence level for intervals. Default is 0.95.
#'
#' @return A data frame with the five selected columns. If `file` is provided,
#'   the same table is invisibly returned after being written to disk.
#' @export
#'
#' @examples
#' fit <- lm(response ~ treatment, data = pharma_sample)
#' pharma_report_table(fit)
#'
pharma_report_table <- function(model, file = NULL, conf.level = 0.95) {
  # Generate a tidy summary of the model with confidence intervals
  res <- broom::tidy(model, conf.int = TRUE, conf.level = conf.level)
  res <- res[, c("term", "estimate", "conf.low", "conf.high", "p.value")]

  if (!is.null(file)) {
    if (grepl("\\.xlsx$", file, ignore.case = TRUE)) {
      if (!requireNamespace("openxlsx", quietly = TRUE)) {
        stop("Package 'openxlsx' is required to write .xlsx files")
      }
      # write results to an Excel workbook
      openxlsx::write.xlsx(res, file)
    } else if (grepl("\\.docx$", file, ignore.case = TRUE)) {
      if (!requireNamespace("flextable", quietly = TRUE) ||
        !requireNamespace("officer", quietly = TRUE)) {
        stop("Packages 'flextable' and 'officer' are required to write .docx files")
      }
      # build Word document containing the table
      ft <- flextable::flextable(res)
      doc <- officer::read_docx()
      doc <- flextable::body_add_flextable(doc, ft)
      print(doc, target = file)
    } else {
      stop("file must end with .xlsx or .docx")
    }
    # Return invisibly if writing to disk so the function can be used
    # in pipelines without printing the table to the console.
    return(invisible(res))
  }

  # Return the tidy results as a data frame when no output file is requested
  res
}
