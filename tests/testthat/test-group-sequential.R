test_that("group-sequential boundaries match established three-look designs", {
  expect_equal(pharma_group_seq(k = 1), stats::qnorm(0.975))

  of <- pharma_group_seq(k = 3, alpha = 0.05)
  pocock <- pharma_group_seq(k = 3, alpha = 0.05, method = "pocock")

  # Published gsDesign three-look examples round to these critical z-values.
  expect_equal(of, c(3.471, 2.454, 2.004), tolerance = 0.01)
  expect_equal(pocock, rep(2.289, 3), tolerance = 0.01)
  expect_gt(of[1], of[2])
  expect_gt(of[2], of[3])
  expect_lt(of[3], pocock[3])
})

test_that("information fractions affect calibrated boundaries", {
  regular <- pharma_group_seq(k = 3)
  uneven <- pharma_group_seq(k = 3, timing = c(0.25, 0.6, 1))

  expect_length(uneven, 3)
  expect_true(all(is.finite(uneven)))
  expect_false(isTRUE(all.equal(uneven, regular)))
})

test_that("group-sequential inputs reject invalid plans", {
  expect_error(pharma_group_seq(k = 0), "positive whole number")
  expect_error(pharma_group_seq(k = 2.5), "positive whole number")
  expect_error(pharma_group_seq(k = NA_real_), "positive whole number")
  expect_error(pharma_group_seq(alpha = 0), "alpha")
  expect_error(pharma_group_seq(alpha = 0.5), "alpha")
  expect_error(pharma_group_seq(alpha = NA_real_), "alpha")
  expect_error(pharma_group_seq(k = 3, timing = c(0.5, 1)), "timing")
  expect_error(pharma_group_seq(k = 3, timing = c(0.5, 0.4, 1)), "timing")
  expect_error(pharma_group_seq(k = 3, timing = c(0.2, 0.6, 0.9)), "timing")
  expect_error(pharma_group_seq(method = "bonferroni"), "arg")
})
