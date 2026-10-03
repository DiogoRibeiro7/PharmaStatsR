test_that("pharma_generate_sap returns text", {
  sap <- pharma_generate_sap()
  expect_true(is.character(sap))
  expect_true(length(sap) > 1)
  sap2 <- pharma_generate_sap(objectives = "Assess efficacy")
  expect_true(grepl("Assess efficacy", sap2[which(grepl("Objectives", sap2)) + 1]))
})

test_that("SAP sections retain the requested order and exact text", {
  sap <- pharma_generate_sap(
    include_sections = c("Software", "Objectives"),
    objectives = "Assess efficacy", software = "R 4.x",
    extra_sections = list(Timeline = "Visit schedule")
  )
  expect_identical(sap, c(
    "# Statistical Analysis Plan - Untitled Study", "", "Author: Diogo Ribeiro",
    "", "## Software", "R 4.x", "", "## Objectives", "Assess efficacy",
    "", "## Timeline", "Visit schedule"
  ))
  expect_identical(
    pharma_generate_sap(include_sections = NULL, extra_sections = list()),
    c("# Statistical Analysis Plan - Untitled Study", "", "Author: Diogo Ribeiro")
  )
})

test_that("invalid SAP requests fail before touching the output path", {
  path <- tempfile(fileext = ".md")
  writeLines("Existing plan", path)
  on.exit(unlink(path))

  invalid <- list(
    list(include_sections = c("Objectives", "Planned Analysis")),
    list(include_sections = character()),
    list(include_sections = c("Objectives", "Objectives")),
    list(include_sections = c("Objectives", "")),
    list(include_sections = NA_character_),
    list(include_sections = 1),
    list(objectives = c("first", "second")),
    list(endpoints = 1),
    list(methods = NA_character_),
    list(title = NULL),
    list(extra_sections = list("Unnamed")),
    list(extra_sections = list(Timeline = "ok", "Missing name")),
    list(extra_sections = setNames(list("text"), " ")),
    list(extra_sections = setNames(list("one", "two"), c("Timeline", "Timeline"))),
    list(extra_sections = list(Objectives = "duplicate default")),
    list(extra_sections = list(Timeline = 3)),
    list(extra_sections = list(Timeline = c("one", "two"))),
    list(extra_sections = list(Timeline = NA_character_)),
    list(extra_sections = c(Timeline = "text"))
  )
  for (args in invalid) {
    expect_error(do.call(pharma_generate_sap, c(list(path = path), args)))
    expect_identical(readLines(path), "Existing plan")
  }

  unlink(path)
  expect_error(
    pharma_generate_sap(path, include_sections = c("Objectives", "Planned Analysis")),
    "Planned Analysis.*Supported sections"
  )
  expect_false(file.exists(path))
})
