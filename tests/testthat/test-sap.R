test_that("pharma_generate_sap returns text", {
  sap <- pharma_generate_sap()
  expect_true(is.character(sap))
  expect_true(length(sap) > 1)
})
