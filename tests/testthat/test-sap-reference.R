# Deterministic artifact contract for pharma_generate_sap().
# Expected Markdown is written explicitly rather than assembled by the helper.

sap_reference_expected <- function() {
  c(
    "# Statistical Analysis Plan - Estudo Δ – Fase III",
    "",
    "Author: Investigador #1",
    "",
    "## Software",
    "R >= 4.4; pacote `survival`.",
    "",
    "## Endpoints",
    "Primário: OS | Secundário: PFS.",
    "",
    "## Objectives",
    "",
    "",
    "## Decision Rules",
    "Use **two-sided** α = 0.05; do not infer approval.",
    "",
    "## Notas UTF-8",
    "Eficácia, segurança, razão β/α; café."
  )
}

sap_reference_call <- function(path = NULL) {
  pharma_generate_sap(
    path = path,
    title = "Estudo Δ – Fase III",
    author = "Investigador #1",
    objectives = "",
    endpoints = "Primário: OS | Secundário: PFS.",
    software = "R >= 4.4; pacote `survival`.",
    include_sections = c("Software", "Endpoints", "Objectives"),
    extra_sections = list(
      "Decision Rules" = "Use **two-sided** α = 0.05; do not infer approval.",
      "Notas UTF-8" = "Eficácia, segurança, razão β/α; café."
    )
  )
}

test_that("SAP reference matches the complete explicit Markdown vector", {
  actual <- sap_reference_call()
  expected <- sap_reference_expected()

  expect_identical(actual, expected)
  expect_identical(actual[actual == ""], rep("", 6L))
  expect_identical(
    grep("^## ", actual, value = TRUE),
    c(
      "## Software", "## Endpoints", "## Objectives",
      "## Decision Rules", "## Notas UTF-8"
    )
  )
  expect_identical(actual[12L], "")
  expect_identical(actual[13L], "")
})

test_that("written SAP lines and UTF-8 text equal the returned artifact", {
  path <- tempfile(fileext = ".md")
  on.exit(unlink(path), add = TRUE)

  returned <- sap_reference_call(path)
  expected <- sap_reference_expected()
  saved <- readLines(path, encoding = "UTF-8", warn = FALSE)

  expect_identical(returned, expected)
  expect_identical(enc2utf8(saved), enc2utf8(expected))

  raw_text <- readChar(path, nchars = file.info(path)$size, useBytes = TRUE)
  normalized <- gsub("\\r\\n", "\n", raw_text, fixed = FALSE)
  expect_identical(
    enc2utf8(normalized),
    enc2utf8(paste0(paste(expected, collapse = "\n"), "\n"))
  )
})

test_that("valid SAP generation overwrites only with the complete artifact", {
  path <- tempfile(fileext = ".md")
  on.exit(unlink(path), add = TRUE)
  writeLines(c("OLD", "CONTENT"), path)

  returned <- sap_reference_call(path)
  saved <- readLines(path, encoding = "UTF-8", warn = FALSE)

  expect_identical(returned, sap_reference_expected())
  expect_identical(enc2utf8(saved), enc2utf8(sap_reference_expected()))
  expect_false(any(saved %in% c("OLD", "CONTENT")))
})

test_that("custom-only SAP keeps exact ordering and empty bodies", {
  actual <- pharma_generate_sap(
    title = "Custom only",
    author = "",
    include_sections = NULL,
    extra_sections = list(
      "First" = "",
      "Second [literal]" = "Text with #, |, `code`, **bold**, and α."
    )
  )

  expect_identical(actual, c(
    "# Statistical Analysis Plan - Custom only",
    "",
    "Author: ",
    "",
    "## First",
    "",
    "",
    "## Second [literal]",
    "Text with #, |, `code`, **bold**, and α."
  ))
})

test_that("invalid SAP requests leave an existing artifact byte-for-byte intact", {
  path <- tempfile(fileext = ".md")
  on.exit(unlink(path), add = TRUE)

  original <- charToRaw("ORIGINAL\nBYTES\n")
  con <- file(path, open = "wb")
  writeBin(original, con)
  close(con)

  invalid <- list(
    list(include_sections = c("Objectives", "Unknown")),
    list(include_sections = c("Objectives", "Objectives")),
    list(extra_sections = list(Objectives = "duplicate")),
    list(extra_sections = setNames(list("text"), " ")),
    list(title = NA_character_),
    list(methods = c("one", "two"))
  )

  for (args in invalid) {
    expect_error(do.call(pharma_generate_sap, c(list(path = path), args)))
    con <- file(path, open = "rb")
    current <- readBin(con, what = "raw", n = file.info(path)$size)
    close(con)
    expect_identical(current, original)
  }
})
