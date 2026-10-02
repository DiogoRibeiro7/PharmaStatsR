test_that("stored response values match the seeded reference", {
  expect_equal(round(pharma_latin_square$response[1:3], 6),
               c(4.831857, 4.930947, 5.467612))
  expect_equal(round(pharma_dose_response$response[1], 6), 0.962020)
  expect_equal(round(tail(pharma_latin_square$response, 1), 6), 5.536074)
  expect_equal(round(tail(pharma_dose_response$response, 1), 6), 4.659457)
})

test_that("hand-entered fixtures preserve their published designs", {
  expect_named(pharma_sample,
               c("subject", "treatment", "dose", "response", "outcome"))
  expect_identical(dim(pharma_sample), c(20L, 5L))
  expect_identical(pharma_sample$subject, 1:20)
  expect_identical(as.integer(table(pharma_sample$treatment,
                                    pharma_sample$dose)),
                   c(10L, 0L, 0L, 10L))
  expect_true(all(pharma_sample$outcome %in% 0:1))

  expect_named(pharma_repeated, c("subject", "condition", "response"))
  expect_identical(dim(pharma_repeated), c(20L, 3L))
  expect_identical(sort(unique(pharma_repeated$subject)), 1:10)
  expect_true(all(table(pharma_repeated$subject,
                        pharma_repeated$condition) == 1L))
  expect_type(pharma_repeated$subject, "integer")
  expect_type(pharma_repeated$condition, "character")

  expect_named(pharma_crossover,
               c("subject", "period", "treatment", "response", "outcome"))
  expect_identical(dim(pharma_crossover), c(20L, 5L))
  expect_true(all(vapply(pharma_crossover[c("subject", "period", "treatment")],
                         is.factor, logical(1))))
  expect_true(all(table(pharma_crossover$subject,
                        pharma_crossover$period) == 1L))
  expect_true(all(table(pharma_crossover$subject,
                        pharma_crossover$treatment) == 1L))
  expect_true(all(table(pharma_crossover$period,
                        pharma_crossover$treatment) == 5L))
  expect_true(all(pharma_crossover$outcome %in% 0:1))

  expect_named(pharma_survival, c("subject", "time", "status", "treatment"))
  expect_identical(dim(pharma_survival), c(30L, 4L))
  expect_identical(pharma_survival$subject, 1:30)
  expect_true(all(pharma_survival$time > 0))
  expect_true(all(pharma_survival$status %in% 0:1))
  expect_identical(as.integer(table(pharma_survival$treatment)), c(15L, 15L))
})

test_that("generated fixtures preserve crossed designs and finite responses", {
  expect_named(pharma_latin_square,
               c("row", "column", "treatment", "response"))
  expect_identical(dim(pharma_latin_square), c(16L, 4L))
  expect_true(all(vapply(pharma_latin_square[1:3], is.factor, logical(1))))
  expect_true(all(table(pharma_latin_square$row,
                        pharma_latin_square$column) == 1L))
  expect_true(all(table(pharma_latin_square$row,
                        pharma_latin_square$treatment) == 1L))
  expect_true(all(table(pharma_latin_square$column,
                        pharma_latin_square$treatment) == 1L))

  expect_named(pharma_dose_response, c("subject", "dose", "response"))
  expect_identical(dim(pharma_dose_response), c(30L, 3L))
  expect_identical(sort(unique(pharma_dose_response$dose)),
                   c(0, 10, 20, 50, 100))
  expect_true(all(table(pharma_dose_response$subject,
                        pharma_dose_response$dose) == 1L))

  for (dat in list(pharma_sample, pharma_repeated, pharma_crossover,
                   pharma_survival, pharma_latin_square,
                   pharma_dose_response)) {
    expect_false(anyNA(dat))
    for (col in dat[vapply(dat, is.numeric, logical(1))]) {
      expect_true(all(is.finite(col)))
    }
  }
})
