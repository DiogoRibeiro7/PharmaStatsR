#' Reshape time-varying covariates
#'
#' Converts between long and wide representations of time-varying covariates.
#' If `data` contains the covariate columns along with the column specified
#' by `time_var`, it is assumed to be in long format and will be pivoted to wide
#' format. Otherwise the function looks for wide-format columns of the form
#' `covariate_time` and pivots them to long format.
#' Names are interpreted literally. Underscores in covariate names and time
#' labels are preserved. A wide column must match exactly one selected
#' covariate prefix; ambiguous names and empty time suffixes raise errors.
#'
#' All other columns, including `id`, jointly identify wide rows. They must
#' be unique in wide input; in long input, their combination with time must
#' be unique. Duplicate keys raise an error even when covariate values agree;
#' rows are never silently aggregated or discarded. Differing retained metadata
#' define separate keys, including for the same subject. Missing key values are
#' allowed and count as equal when detecting duplicates.
#' Missing combinations are filled with missing values by the pivot. Time
#' values must be nonmissing, nonempty atomic values. On conversion to long
#' format, labels become numeric only if distinct labels remain distinct;
#' otherwise they remain character. Original time classes are not recorded.
#' Long-format input needs at least one time value. Empty wide tables can be
#' reshaped when their column names supply the covariate/time mapping.
#' Retained columns other than the identifier must not start with a selected
#' covariate prefix followed by an underscore, which would be ambiguous on a
#' subsequent conversion to long format.
#'
#' Wide rows follow the first appearance of each retained key; columns follow
#' selected covariate order, with times in first-appearance order within each
#' covariate. Long output keeps each wide row's times together, following their
#' first appearance in the wide column names. Value columns follow their first
#' appearance in those names, not necessarily the selection vector. Missing
#' measurement rows are retained. Round trips may add structurally missing cells
#' and do not restore original interleaved row order, row names, or time classes.
#'
#' @param data A data.frame containing the variables to reshape.
#' @param covariates Nonempty character vector of unique covariate base names.
#'   Every selected covariate must be present in the detected format.
#' @param id Single name of the subject identifier column. It is always
#'   retained, even if its name starts with a selected covariate prefix.
#' @param time_var Single name of the time variable. Defaults to "Time".
#'   Must differ from the identifier and selected covariate names.
#'
#' @return A data.frame in the opposite orientation of the input.
#' @examples
#' df <- data.frame(
#'   SubjectID = c(1, 1, 2, 2),
#'   Time = c(0, 1, 0, 1),
#'   WT = c(70, 72, 65, 66)
#' )
#' wide <- reshape_timevarying(df, "WT", id = "SubjectID", time_var = "Time")
#' long <- reshape_timevarying(wide, "WT", id = "SubjectID", time_var = "Time")
#' @export
reshape_timevarying <- function(
  data,
  covariates,
  id = "SubjectID",
  time_var = "Time"
) {
  validate_data_frame_names(data)
  if (!is.character(covariates) || !is.null(dim(covariates)) ||
    length(covariates) == 0L || anyNA(covariates) ||
    any(covariates == "") || anyDuplicated(covariates)) {
    stop(
      "`covariates` must be a character vector of unique, nonempty names"
    )
  }
  roles <- list(id = id, time_var = time_var)
  for (argument in names(roles)) {
    value <- roles[[argument]]
    if (!is.character(value) || !is.null(dim(value)) || length(value) != 1L ||
      is.na(value) || value == "") {
      stop(sprintf("`%s` must be a single nonempty column name", argument))
    }
  }
  if (id == time_var || any(c(id, time_var) %in% covariates)) {
    stop("Identifier, time, and covariate names must be distinct")
  }
  if (!id %in% names(data)) {
    stop(sprintf("ID column '%s' not found", id))
  }

  # A private time name avoids collisions with tidyr's specification columns.
  time_key <- utils::tail(make.unique(c(
    names(data), covariates, time_var, ".pharmocovr_time"
  )), 1L)
  has_long_cols <- all(c(time_var, covariates) %in% names(data))
  if (has_long_cols) {
    return(timevarying_to_wide(data, covariates, id, time_var, time_key))
  }
  if (time_var %in% names(data)) {
    stop("Time column is present but some selected covariates are missing")
  }

  spec <- parse_timevarying_names(setdiff(names(data), id), covariates)
  names(spec)[3L] <- time_key
  retained <- setdiff(names(data), spec$.name)
  if (any(covariates %in% retained)) {
    stop("Covariate output names conflict with retained columns")
  }
  if (anyDuplicated(data[retained])) {
    stop("Duplicate wide row keys cannot be reshaped uniquely; check retained columns")
  }
  long_data <- tidyr::pivot_longer_spec(data, spec)
  labels <- long_data[[time_key]]
  unique_labels <- unique(labels)
  converted <- utils::type.convert(
    unique_labels,
    as.is = TRUE, na.strings = character(), tryLogical = FALSE
  )
  if (is_numeric_vector(converted) && !anyNA(converted) &&
    !anyDuplicated(converted)) {
    labels <- converted[match(labels, unique_labels)]
  }
  long_data[[time_key]] <- labels
  names(long_data)[names(long_data) == time_key] <- time_var
  as.data.frame(long_data)
}

parse_timevarying_names <- function(column_names, covariates) {
  prefixes <- paste0(covariates, "_")
  matches <- lapply(column_names, function(name) {
    which(startsWith(name, prefixes))
  })
  if (any(lengths(matches) > 1L)) {
    stop("Ambiguous wide column names match multiple covariate prefixes")
  }
  selected <- which(lengths(matches) == 1L)
  if (length(selected) == 0L) {
    stop("No time-varying covariate columns found")
  }
  variables <- covariates[unlist(matches[selected], use.names = FALSE)]
  labels <- substring(column_names[selected], nchar(variables) + 2L)
  if (any(labels == "")) {
    stop("Wide covariate columns must have nonempty time suffixes")
  }
  if (!all(covariates %in% variables)) {
    stop("Some selected covariates have no wide-format columns")
  }
  data.frame(
    .name = column_names[selected], .value = variables, .time = labels,
    stringsAsFactors = FALSE
  )
}

timevarying_to_wide <- function(data, covariates, id, time_var, time_key) {
  times <- data[[time_var]]
  if (!is.atomic(times) || !is.null(dim(times)) || anyNA(times) ||
    any(as.character(times) == "")) {
    stop("Time values must be nonmissing, nonempty atomic values")
  }
  if (length(times) == 0L) {
    stop("Long-format data must contain at least one time value")
  }
  if (anyDuplicated(as.character(unique(times)))) {
    stop("Distinct time values produce duplicate wide column labels")
  }
  keys <- setdiff(names(data), covariates)
  if (anyDuplicated(data[keys])) {
    stop("Duplicate identifier/time combinations cannot be reshaped uniquely")
  }
  id_cols <- setdiff(keys, time_var)
  for (variable in covariates) {
    if (any(startsWith(setdiff(id_cols, id), paste0(variable, "_")))) {
      stop("Retained column names conflict with covariate prefixes")
    }
  }
  names(data)[names(data) == time_var] <- time_key
  spec <- tidyr::build_wider_spec(
    data,
    names_from = tidyselect::all_of(time_key),
    values_from = tidyselect::all_of(covariates)
  )
  spec$.name <- paste(spec$.value, as.character(spec[[time_key]]), sep = "_")
  parse_timevarying_names(spec$.name, covariates)
  if (anyDuplicated(spec$.name) || any(spec$.name %in% id_cols)) {
    stop("Wide output column names are not unique")
  }
  tidyr::pivot_wider_spec(data, spec, id_cols = tidyselect::all_of(id_cols))
}
