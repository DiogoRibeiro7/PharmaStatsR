test_that("pharma_gee resolves a column ID like geeglm", {
  skip_if_not_installed("geepack")
  dat <- data.frame(
    subject = rep(seq_len(6), each = 3L),
    condition = rep(c(0, 1, 0), 6L),
    response = c(1.2, 2.4, 1.0, 2.2, 3.0, 2.4, 3.5, 4.8, 3.9,
                 1.7, 2.4, 1.5, 2.8, 3.2, 2.6, 3.1, 4.1, 3.2)
  )
  reference <- geepack::geeglm(
    response ~ condition, id = subject, data = dat, corstr = "exchangeable"
  )
  actual <- pharma_gee(
    response ~ condition, id = subject, data = dat, corstr = "exchangeable"
  )
  vector_id <- pharma_gee(
    response ~ condition, id = dat$subject, data = dat, corstr = "exchangeable"
  )
  expect_equal(stats::coef(actual), stats::coef(reference))
  expect_equal(stats::vcov(actual), stats::vcov(reference))
  expect_equal(actual$id, dat$subject)
  expect_equal(stats::coef(vector_id), stats::coef(reference))
})

test_that("pharma_gee rejects invalid cluster and model rows", {
  skip_if_not_installed("geepack")
  dat <- data.frame(
    subject = rep(1:4, each = 2),
    response = c(1.1, 2.2, 1.9, 3.1, 2.8, 4.1, 3.3, 4.8),
    condition = rep(c(0, 1), 4)
  )
  interleaved <- dat[c(1, 3, 2, 4, 5:8), ]
  expect_error(
    pharma_gee(response ~ condition, id = subject, data = interleaved),
    "contiguous"
  )
  expect_error(
    pharma_gee(response ~ condition, id = 1:3, data = dat),
    "one value per data row"
  )
  missing_id <- dat
  missing_id$subject[1] <- NA
  expect_error(
    pharma_gee(response ~ condition, id = subject, data = missing_id),
    "complete vector"
  )
  missing_response <- dat
  missing_response$response[1] <- NA
  expect_error(
    pharma_gee(response ~ condition, id = subject, data = missing_response),
    "model variables must be complete"
  )
})

test_that("pharma_gee validates data argument", {
  skip_if_not_installed("geepack")
  expect_error(
    pharma_gee(response ~ condition, id = pharma_repeated$subject, data = 1),
    "'data' must be a data frame"
  )
})

test_that("pharma_gee requires geepack", {
  skip_if(requireNamespace("geepack", quietly = TRUE), "geepack installed")
  expect_error(
    pharma_gee(response ~ condition, id = pharma_repeated$subject, data = pharma_repeated),
    "Package 'geepack' is required"
  )
})
