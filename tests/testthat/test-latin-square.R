test_that("Latin square fits a complete categorical design", {
  dat <- pharma_latin_square
  expect_true(all(vapply(dat[c("treatment", "row", "column")],
                         is.factor, logical(1))))

  fit <- pharma_latin_square_anova(
    response ~ treatment + row + column, data = dat
  )
  reference <- stats::aov(response ~ treatment + row + column, data = dat)
  expect_s3_class(fit, "aov")
  expect_equal(stats::coef(fit), stats::coef(reference))
  expect_equal(as.numeric(summary(fit)[[1L]][["Df"]]), c(3, 3, 3, 6))
})

test_that("Latin square accepts explicit factor conversion of numeric codes", {
  dat <- pharma_latin_square
  dat$row <- as.integer(dat$row)
  dat$column <- as.integer(dat$column)

  expect_error(
    pharma_latin_square_anova(response ~ treatment + row + column, dat),
    "factor"
  )
  fit <- pharma_latin_square_anova(
    response ~ treatment + factor(row) + factor(column), dat
  )
  reference <- stats::aov(
    response ~ treatment + factor(row) + factor(column), data = dat
  )
  expect_equal(stats::coef(fit), stats::coef(reference))
})

test_that("Latin square rejects incomplete or repeated allocations", {
  dat <- pharma_latin_square
  missing_cell <- dat[-1L, ]
  expect_error(
    pharma_latin_square_anova(
      response ~ treatment + row + column, missing_cell
    ),
    "one observation per row-column cell"
  )

  repeated_cell <- dat
  repeated_cell$column[1L] <- repeated_cell$column[2L]
  expect_error(
    pharma_latin_square_anova(
      response ~ treatment + row + column, repeated_cell
    ),
    "one observation per row-column cell"
  )

  repeated_treatment <- dat
  repeated_treatment$treatment[1L] <- repeated_treatment$treatment[2L]
  expect_error(
    pharma_latin_square_anova(
      response ~ treatment + row + column, repeated_treatment
    ),
    "each treatment once per row and column"
  )
})

test_that("Latin square rejects undefined or inappropriate models", {
  dat <- pharma_latin_square
  expect_error(
    pharma_latin_square_anova(response ~ treatment + row, dat),
    "three main effects"
  )
  expect_error(
    pharma_latin_square_anova(
      response ~ treatment * row + column, dat
    ),
    "three main effects"
  )
  expect_error(
    pharma_latin_square_anova(
      response ~ treatment + row + column - 1, dat
    ),
    "intercept"
  )

  dat$response[1L] <- NA_real_
  expect_error(
    pharma_latin_square_anova(response ~ treatment + row + column, dat),
    "NA values"
  )
  dat$response[1L] <- Inf
  expect_error(
    pharma_latin_square_anova(response ~ treatment + row + column, dat),
    "finite numeric"
  )

  expect_error(
    pharma_latin_square_anova(
      response ~ treatment + row + column, pharma_latin_square,
      subset = row != "1"
    ),
    "not supported"
  )
})

test_that("a two-by-two square has no residual degrees of freedom", {
  dat <- data.frame(
    response = c(1, 3, 2, 4),
    treatment = factor(c("A", "B", "B", "A")),
    row = factor(c(1, 1, 2, 2)),
    column = factor(c(1, 2, 1, 2))
  )
  expect_error(
    pharma_latin_square_anova(response ~ treatment + row + column, dat),
    "at least three"
  )
})
