test_that("plugin registration and execution works", {
  pharma_register_plugin("test_mean", mean)
  expect_true("test_mean" %in% pharma_list_plugins())
  res <- pharma_run_plugin("test_mean", 1:4)
  expect_equal(res, 2.5)
  pharma_unregister_plugin("test_mean")
  expect_false("test_mean" %in% pharma_list_plugins())
})
