test_that("network meta-analysis reports the missing optional backend", {
  testthat::local_mocked_bindings(.pharma_netmeta_available = function() FALSE)

  expect_error(
    pharma_network_meta_analysis(
      TE = c(0.2, 0.5, -0.1), seTE = c(0.1, 0.2, 0.1),
      treat1 = c("A", "A", "B"), treat2 = c("B", "C", "C")
    ),
    "install.packages\\('netmeta'\\)"
  )
})

test_that("network meta-analysis matches the installed backend", {
  skip_if_not_installed("netmeta")

  effects <- c(0.2, 0.25, 0.5, 0.45, -0.1)
  errors <- c(0.1, 0.11, 0.2, 0.18, 0.12)
  first <- c("A", "A", "A", "A", "B")
  second <- c("B", "B", "C", "C", "C")
  studies <- paste0("s", seq_along(effects))

  actual <- pharma_network_meta_analysis(
    effects, errors, first, second,
    studlab = studies, sm = "MD", random = FALSE
  )
  reference <- netmeta::netmeta(
    TE = effects, seTE = errors, treat1 = first, treat2 = second,
    studlab = studies, sm = "MD", random = FALSE
  )

  expect_s3_class(actual, "netmeta")
  expect_identical(actual$studlab, reference$studlab)
  expect_equal(actual$TE.common, reference$TE.common, tolerance = 1e-12)
  expect_equal(actual$seTE.common, reference$seTE.common, tolerance = 1e-12)

  random_fit <- pharma_network_meta_analysis(
    effects, errors, first, second, studlab = studies
  )
  random_reference <- netmeta::netmeta(
    TE = effects, seTE = errors, treat1 = first, treat2 = second,
    studlab = studies, sm = "MD", random = TRUE
  )
  expect_equal(random_fit$TE.random, random_reference$TE.random,
               tolerance = 1e-12)
  expect_equal(random_fit$seTE.random, random_reference$seTE.random,
               tolerance = 1e-12)
})
