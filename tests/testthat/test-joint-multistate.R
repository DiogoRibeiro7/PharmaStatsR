test_that("pharma_joint_model guards against missing JM package", {
  expect_error(pharma_joint_model(NULL, NULL, "time"), "Package 'JM' is required")
})

test_that("pharma_multistate_model validates inputs and package availability", {
  expect_error(pharma_multistate_model(list(), matrix(1)), "coxFit must be a 'coxph' object")
  dummy_cox <- structure(list(), class = "coxph")
  trans <- matrix(0, 2, 2)
  expect_error(pharma_multistate_model(dummy_cox, trans), "Package 'mstate' is required")
})
