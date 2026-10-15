#' Validate input data schema
#'
#' Ensures the input data contains required columns with expected types
#' and at least one additional covariate column. All column names must be
#' unique, nonmissing, and nonempty. This structural check permits missing
#' values; preprocessing and model functions validate their selected variables.
#'
#' @param data A `data.frame` with columns `SubjectID`, `Time`, `DV` and
#'   additional covariates.
#'
#' @return `TRUE` invisibly when validation passes. An error is thrown on
#'   failure.
#' @examples
#' df <- data.frame(SubjectID = 1L, Time = 0, DV = 1.1, WT = 70)
#' validate_data_schema(df)
#' @export
validate_data_schema <- function(data) {
  validate_data_frame_names(data)

  required_cols <- c("SubjectID", "Time", "DV")
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop(
      sprintf(
        "Missing required columns: %s", paste(missing_cols, collapse = ", ")
      )
    )
  }

  # Type checks for required columns
  if (!is.integer(data$SubjectID) || !is.null(dim(data$SubjectID))) {
    stop("`SubjectID` must be integer")
  }
  if (!is_numeric_vector(data$Time)) {
    stop("`Time` must be numeric")
  }
  if (!is_numeric_vector(data$DV)) {
    stop("`DV` must be numeric")
  }

  covariate_cols <- setdiff(names(data), required_cols)
  if (length(covariate_cols) == 0) {
    stop("No covariate columns found")
  }

  invisible(TRUE)
}
