local_edition(3)

report_reference_data <- function() {
  d <- data.frame(SubjectID = rep(1:4, each = 3), Time = rep(c(-1, 0, 1), 4))
  d$DV <- 2 + 1.5 * d$Time + rep(c(-3, -1, 1, 3), each = 3) + rep(c(1, -2, 1), 4)
  d
}

read_fixed_report_table <- function(path) {
  html <- paste(readLines(path, warn = FALSE), collapse = "")
  tables <- regmatches(html, gregexpr("<table[^>]*>.*?</table>", html, perl = TRUE))[[1]]
  table <- tables[grepl("<caption>Fixed effects</caption>", tables, fixed = TRUE)]
  expect_length(table, 1L)
  cells <- regmatches(table, gregexpr("<td[^>]*>.*?</td>", table, perl = TRUE))[[1]]
  cells <- trimws(gsub("<[^>]*>", "", cells))
  cells <- matrix(cells, ncol = 6L, byrow = TRUE)
  list(html = table, cells = cells)
}

test_that("rendered fixed effects match independent balanced REML references", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())
  d <- report_reference_data()
  # Within-subject SS=24 with 7 residual df; between-subject MS=20.
  # sigma^2=24/7, tau^2=116/21. Thus Var(beta0)=5/3, Var(beta1)=3/7.
  # nlme assigns denominator df=7 to both terms for this within-subject design.
  beta <- c(2, 1.5)
  se <- sqrt(c(5 / 3, 3 / 7))
  directory <- tempfile("report-reference-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE))
  for (case in c("ordinary", "permuted_saved", "affine")) {
    input <- d
    expected_beta <- beta
    expected_se <- se
    if (case == "permuted_saved") input <- d[c(12, 1, 8, 3, 5, 10, 2, 9, 4, 7, 11, 6), ]
    if (case == "affine") {
      input$DV <- 7 - 2 * input$DV
      expected_beta <- c(3, -3)
      expected_se <- 2 * se
    }
    model <- fit_covariate_model(input, "DV", "SubjectID", "Time")
    if (case == "permuted_saved") {
      saveRDS(model, file.path(directory, "model.rds"))
      model <- readRDS(file.path(directory, "model.rds"))
    }
    original_model <- model
    original_data <- input
    out <- generate_report(model, input, output_file = file.path(directory, paste0(case, ".html")))
    parsed <- read_fixed_report_table(out)
    expect_identical(parsed$cells[, 1], c("(Intercept)", "Time"))
    expected_t <- expected_beta / expected_se
    expected <- cbind(expected_beta, expected_se, c(7, 7), expected_t, 2 * stats::pt(-abs(expected_t), df = 7))
    actual <- matrix(as.numeric(parsed$cells[, -1]), nrow = 2)
    # Six significant display digits plus a small variance-optimizer tolerance.
    expect_equal(as.vector(actual), as.vector(expected), tolerance = 1e-5)
    for (header in c("Term", "Estimate", "Std. Error", "DF", "t statistic", "p value")) {
      expect_match(parsed$html, paste0(">", header, "</th>"), fixed = TRUE)
    }
    expect_identical(model, original_model)
    expect_identical(input, original_data)
  }
})

test_that("small report p-values have an explicit bound instead of rounded zero", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())
  d <- report_reference_data()
  d$DV <- d$DV + 100 + 50 * d$Time
  model <- fit_covariate_model(d, "DV", "SubjectID", "Time")
  out <- tempfile(fileext = ".html")
  on.exit(unlink(out))
  generate_report(model, d, output_file = out)
  parsed <- read_fixed_report_table(out)
  expect_identical(parsed$cells[, 6], rep("&lt;1e-6", 2))
  expect_equal(as.numeric(parsed$cells[, 2]), c(102, 51.5))
  expect_match(parsed$html, "&lt;1e-6", fixed = TRUE)
})

test_that("report coefficient labels are escaped in HTML and PDF", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available())
  d <- report_reference_data()
  d$group <- factor(rep(c("base", "<b>&H</b>", "base", "<b>&H</b>"), each = 3), levels = c("base", "<b>&H</b>"))
  model <- fit_covariate_model(d, "DV", "SubjectID", c("Time", "group"))
  directory <- tempfile("report-labels-")
  dir.create(directory)
  on.exit(unlink(directory, recursive = TRUE))
  out <- generate_report(model, d, output_file = file.path(directory, "labels.html"))
  parsed <- read_fixed_report_table(out)
  expect_identical(parsed$cells[, 1], c("(Intercept)", "Time", "group&lt;b&gt;&amp;H&lt;/b&gt;"))
  expect_false(grepl("<b>&H</b>", parsed$html, fixed = TRUE))
  if (Sys.which("pdflatex") != "") {
    pdf <- generate_report(model, d, output_format = "pdf_document", output_file = file.path(directory, "labels.pdf"))
    expect_identical(readChar(pdf, 4L, useBytes = TRUE), "%PDF")
    expect_gt(file.info(pdf)$size, 1000)
  }
})
