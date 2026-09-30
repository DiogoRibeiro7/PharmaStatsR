repeated_example <- function() {
  data.frame(
    subject = factor(rep(1:4, each = 2L)),
    condition = factor(rep(c("A", "B"), times = 4L)),
    response = c(2, 3, 4, 6, 5, 6, 7, 10)
  )
}

test_that("paired two-condition ANOVA matches an independent numerical reference", {
  data <- repeated_example()
  fit <- pharma_repeated_anova(response ~ condition + Error(subject), data)
  tab <- summary(fit)[["Error: Within"]][[1L]]

  # Differences B - A are 1, 2, 1, 3. Their mean is 7/4, and their
  # centered sum of squares is 11/4. The condition SS is 49/8, within
  # residual SS is 11/8, and F(1, 3) = 147/11 = paired t^2.
  expect_s3_class(fit, "aovlist")
  expect_equal(as.numeric(tab[["Df"]]), c(1, 3))
  expect_equal(as.numeric(tab[["Sum Sq"]]), c(49/8, 11/8),
               tolerance = 1e-12)
  expect_equal(as.numeric(tab[["F value"]][1L]), 147/11,
               tolerance = 1e-12)
  # Independent upper-tail F(1, 3) from SciPy 1.17.0.
  expect_equal(as.numeric(tab[["Pr(>F)"]][1L]),
               0.03535284700251737, tolerance = 1e-12)
  expect_equal(as.numeric(tab[["F value"]][1L]),
               unname(stats::t.test(c(3, 6, 6, 10), c(2, 4, 5, 7),
                                    paired = TRUE)$statistic)^2,
               tolerance = 1e-12)
})

test_that("repeated ANOVA requires complete, unique pairs", {
  data <- repeated_example()
  expanded <- rbind(data, transform(data, condition = factor("C")))
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     expanded), "two observed conditions")
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     data[-1L, ]), "exactly one")
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     rbind(data, data[1L, ])), "exactly one")
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     data[1:4, ]), "three subjects")
  data$response[1L] <- NA_real_
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     data), "NA values")
  data$response[1L] <- Inf
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     data), "finite numeric")
  data <- repeated_example()
  data$response[c(2, 4, 6, 8)] <- data$response[c(1, 3, 5, 7)] + 1
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     data), "positive finite variance")
})

test_that("repeated ANOVA checks factor coding and exact model", {
  data <- repeated_example()
  data$subject <- as.integer(data$subject)
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     data), "must be factors")
  data <- repeated_example()
  data$condition <- as.integer(data$condition)
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     data), "must be factors")
  data <- repeated_example()
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject + condition),
                                     data), "simple column names")
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject) - 1,
                                     data), "intercept")
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     data, subset = subject != "1"),
               "not supported")
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     data, weights = rep(1, nrow(data))),
               "not supported")
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     data, na.action = stats::na.omit),
               "not supported")
  expect_error(pharma_repeated_anova(response ~ condition + Error(subject),
                                     data, offset = rep(0, nrow(data))),
               "not supported")
})

test_that("bundled repeated data can be explicitly factor coded", {
  paired <- transform(pharma_repeated, subject = factor(subject),
                      condition = factor(condition))
  fit <- pharma_repeated_anova(response ~ condition + Error(subject), paired)
  expect_s3_class(fit, "aovlist")
  expect_true(is.finite(summary(fit)[["Error: Within"]][[1L]][["F value"]][1L]))
})
