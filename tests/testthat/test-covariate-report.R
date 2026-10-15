local_edition(3)

library(testthat)

skip_if_not(requireNamespace("rmarkdown", quietly = TRUE))

make_report_data <- function() {
  set.seed(123)
  data.frame(
    SubjectID = rep(1:5, each = 2),
    Time = rep(0:1, times = 5),
    DV = rnorm(10)
  )
}

with_report_directory <- function(code) {
  directory <- tempfile("report-test-")
  dir.create(directory)
  directory <- normalizePath(directory, winslash = "/", mustWork = TRUE)
  previous <- getwd()
  on.exit(
    {
      setwd(previous)
      unlink(directory, recursive = TRUE)
    },
    add = TRUE
  )
  setwd(directory)
  force(code)
}

test_that("relative and absolute HTML destinations contain complete reports", {
  skip_if_not(rmarkdown::pandoc_available())
  d <- make_report_data()
  model <- fit_covariate_model(d, "DV", "SubjectID", "Time")
  template <- system.file("templates", "covariate-report.Rmd", package = "PharmaStatsR")
  template_text <- readLines(template)
  template_files <- list.files(dirname(template),
    recursive = TRUE,
    all.files = TRUE
  )
  workspaces <- Sys.glob(file.path(tempdir(), "pharmocovr-report-*"))
  with_report_directory({
    original_wd <- getwd()
    paths <- c(
      "analysis.html", file.path("nested reports", "analysis"),
      file.path(getwd(), "absolute reports", "analysis.html")
    )
    for (path in paths) {
      out <- generate_report(model, d, output_file = path)
      expected <- if (endsWith(path, ".html")) path else paste0(path, ".html")
      expect_identical(out, normalizePath(expected, winslash = "/"))
      expect_true(file.exists(out))
      html <- paste(readLines(out, warn = FALSE), collapse = "\n")
      expect_match(html, "Pharmacometrics Report", fixed = TRUE)
      expect_match(html, "Summary", fixed = TRUE)
      expect_match(html, "(Intercept)", fixed = TRUE)
      expect_match(html, "Diagnostics", fixed = TRUE)
      expect_match(html, "data:image/png;base64,", fixed = TRUE)
      expect_identical(getwd(), original_wd)
    }
    expect_setequal(
      list.files(recursive = TRUE),
      c(
        "analysis.html", "nested reports/analysis.html",
        "absolute reports/analysis.html"
      )
    )
  })
  expect_identical(readLines(template), template_text)
  expect_identical(
    list.files(dirname(template), recursive = TRUE, all.files = TRUE),
    template_files
  )
  expect_setequal(
    Sys.glob(file.path(tempdir(), "pharmocovr-report-*")), workspaces
  )
})

test_that("default destinations return an existing temporary report", {
  skip_if_not(rmarkdown::pandoc_available())
  d <- make_report_data()
  model <- fit_covariate_model(d, "DV", "SubjectID", "Time")
  out <- generate_report(model, d)
  on.exit(unlink(out), add = TRUE)
  expect_true(file.exists(out))
  expect_identical(dirname(out), normalizePath(tempdir(), winslash = "/"))
  expect_true(endsWith(out, ".html"))
})

test_that("PDF output is rendered to the requested relative destination", {
  skip_if_not(rmarkdown::pandoc_available())
  skip_if(Sys.which("pdflatex") == "", "LaTeX is not installed")
  d <- make_report_data()
  model <- fit_covariate_model(d, "DV", "SubjectID", "Time")
  with_report_directory({
    out <- generate_report(
      model, d,
      output_format = "pdf_document",
      output_file = file.path("pdf reports", "analysis")
    )
    expect_identical(
      out, normalizePath("pdf reports/analysis.pdf", winslash = "/")
    )
    expect_identical(readChar(out, 4L, useBytes = TRUE), "%PDF")
    expect_gt(file.info(out)$size, 1000)
    expect_identical(list.files(recursive = TRUE), "pdf reports/analysis.pdf")
  })
})

test_that("invalid report paths fail before rendering", {
  for (path in list(
    character(), NA_character_, "", "  ", 1, c("a", "b"),
    matrix("report.html")
  )) {
    expect_error(
      generate_report(NULL, data.frame(), output_file = path), "single nonempty"
    )
  }
  with_report_directory({
    for (path in c(".", "..", getwd(), "new-directory/", "new-directory\\")) {
      expect_error(
        generate_report(NULL, data.frame(), output_file = path),
        "not a directory"
      )
    }
    writeLines("existing file", "parent")
    expect_error(
      generate_report(NULL, data.frame(), output_file = "parent/report.html"),
      "Cannot create the report output directory"
    )
    expect_identical(readLines("parent"), "existing file")
  })
})

test_that("render failures clean up without changing the caller directory", {
  captured <- new.env(parent = emptyenv())
  local_mocked_bindings(
    render = function(input, ...) {
      captured$workspace <- dirname(input)
      expect_true(file.exists(input))
      stop("simulated render failure")
    },
    .package = "rmarkdown"
  )
  with_report_directory({
    original_wd <- getwd()
    expect_error(
      generate_report(NULL, data.frame(), output_file = "analysis.html"),
      "simulated render failure"
    )
    expect_false(dir.exists(captured$workspace))
    expect_identical(getwd(), original_wd)
    expect_false(file.exists("analysis.html"))
  })
})
