test_that("pharma_generate_sap returns text", {
  sap <- pharma_generate_sap()
  expect_true(is.character(sap))
  expect_true(length(sap) > 1)
  sap2 <- pharma_generate_sap(objectives = "Assess efficacy")
  expect_true(grepl("Assess efficacy", sap2[which(grepl("Objectives", sap2)) + 1]))
})
