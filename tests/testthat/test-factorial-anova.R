# Two factors crossed with two independent observations per cell.
factorial_example <- function() {
  data.frame(
    treatment = factor(rep(c("A", "B"), each = 4L)),
    dose = factor(rep(c("Low", "High"), each = 2L, times = 2L),
                  levels = c("Low", "High")),
    response = c(9, 11, 11, 13, 10, 12, 16, 18)
  )
}

test_that("balanced two-factor ANOVA has independently known effects", {
  data <- factorial_example()
  fit <- pharma_factorial_anova(response ~ treatment * dose, data)
  tab <- summary(fit)[[1L]]

  # Cell means: 10, 12, 11, 17. Grand mean 12.5. Sequential sums of
  # squares are 18 for treatment, 32 for dose, 8 for interaction, and 8
  # for residual error. The residual df is 4, so MSE = 2.
  expect_s3_class(fit, "aov")
  expect_equal(unname(stats::coef(fit)), c(10, 1, 2, 4),
               tolerance = 1e-12)
  expect_equal(as.numeric(tab[["Df"]]), c(1, 1, 1, 4))
  expect_equal(as.numeric(tab[["Sum Sq"]]), c(18, 32, 8, 8),
               tolerance = 1e-12)
  expect_equal(as.numeric(tab[["F value"]][1:3]), c(9, 16, 4),
               tolerance = 1e-12)
  # Independent upper-tail F(1, 4) values from SciPy 1.17.0.
  expect_equal(as.numeric(tab[["Pr(>F)"]][1:3]),
               c(0.03994196807171883, 0.016130089900092546,
                 0.11611652351681556), tolerance = 1e-12)

  # The fitted coefficients and residual error also agree with a direct lm.
  reference <- stats::lm(response ~ treatment * dose, data = data)
  expect_equal(stats::coef(fit), stats::coef(reference))
  expect_equal(sum(stats::residuals(fit)^2),
               sum(stats::residuals(reference)^2))
})

test_that("factorial ANOVA rejects confounded, incomplete, and unbalanced cells", {
  data <- factorial_example()
  expect_error(
    pharma_factorial_anova(response ~ treatment * factor(dose),
                            data = pharma_sample),
    "factor combination"
  )
  expect_error(pharma_factorial_anova(response ~ treatment * dose,
                                     data = data[-c(1L, 2L), ]),
               "factor combination")
  expect_error(pharma_factorial_anova(response ~ treatment * dose,
                                     data = data[c(1L, 3L, 5L, 7L), ]),
               "at least two per cell")
  expect_error(pharma_factorial_anova(response ~ treatment * dose,
                                     data = rbind(data, data[1L, ])),
               "same number")
})

test_that("factorial ANOVA checks coding, formula, and analysis population", {
  data <- factorial_example()
  data$dose <- as.numeric(data$dose)
  expect_error(pharma_factorial_anova(response ~ treatment * dose, data),
               "categorical")
  expect_s3_class(pharma_factorial_anova(
    response ~ treatment * factor(dose), data
  ), "aov")

  data <- factorial_example()
  expect_error(pharma_factorial_anova(response ~ treatment + dose, data),
               "factor1 \\* factor2")
  expect_error(pharma_factorial_anova(response ~ treatment * dose - 1, data),
               "intercept")
  data$response[1L] <- NA_real_
  expect_error(pharma_factorial_anova(response ~ treatment * dose, data),
               "NA values")
  data$response[1L] <- Inf
  expect_error(pharma_factorial_anova(response ~ treatment * dose, data),
               "finite numeric")

  data <- factorial_example()
  expect_error(pharma_factorial_anova(
    response ~ treatment * dose, data, subset = treatment == "A"
  ), "not supported")
  expect_error(pharma_factorial_anova(
    response ~ treatment * dose, data, weights = rep(1, nrow(data))
  ), "not supported")
})
