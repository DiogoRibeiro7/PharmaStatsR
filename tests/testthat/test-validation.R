test_that("validation report indicates compliance", {
  rep <- pharma_validation_report(pharma_sample, "Treatment")
  expect_true(rep$compliant)
  expect_equal(rep$estimand, "Treatment")
})
