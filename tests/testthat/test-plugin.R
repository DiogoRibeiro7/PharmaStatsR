test_that("plugin registration and execution works", {
  pharma_register_plugin("test_mean", mean)
  expect_true("test_mean" %in% pharma_list_plugins())
  res <- pharma_run_plugin("test_mean", 1:4)
  expect_equal(res, 2.5)
  pharma_unregister_plugin("test_mean")
  expect_false("test_mean" %in% pharma_list_plugins())
})

test_that("stat method registration and execution works", {
  pharma_register_stat("mean_method", mean)
  expect_true("mean_method" %in% pharma_list_stats())
  expect_equal(pharma_run_stat("mean_method", 1:4), 2.5)
  pharma_unregister_stat("mean_method")
  expect_false("mean_method" %in% pharma_list_stats())
})
