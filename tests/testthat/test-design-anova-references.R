# Balanced AB/BA with four subjects and two periods. The additive
# components are grand mean 10, treatment A/B = -1.5/+1.5,
# period 1/2 = -1/+1, and subject = -1/0/0/+1.
# Residual pairs are (+1,-1), (-1,+1), (+2,-2), (-2,+2);
# their sums within each subject, treatment, and period are zero.
crossover_reference_data <- function() {
  data.frame(
    subject = factor(rep(seq_len(4L), each = 2L)),
    period = factor(rep(seq_len(2L), times = 4L)),
    treatment = factor(c("A", "B", "A", "B",
                         "B", "A", "B", "A")),
    response = c(7.5, 10.5, 6.5, 13.5,
                 12.5, 7.5, 9.5, 12.5)
  )
}

test_that("crossover ANOVA has independently calculated terms", {
  dat <- crossover_reference_data()
  fit <- pharma_crossover_anova(
    response ~ treatment + period + subject, dat
  )
  tab <- summary(fit)[[1L]]

  # Treatment means are 8.5 and 11.5; period means are 9 and 11;
  # subject means are 9, 10, 10, 11. The balanced factors are
  # orthogonal. SS = 4*(1.5^2 + 1.5^2) for treatment,
  # 4*(1^2 + 1^2) for period, and 2*(1^2 + 1^2) for subjects.
  # Residual SSE = 2*(1^2 + 1^2 + 2^2 + 2^2) = 20.
  expect_s3_class(fit, "aov")
  expect_equal(as.numeric(tab[["Df"]]), c(1, 1, 3, 2))
  expect_equal(as.numeric(tab[["Sum Sq"]]), c(18, 8, 4, 20),
               tolerance = 1e-12)
  expect_equal(as.numeric(tab[["Mean Sq"]]), c(18, 8, 4 / 3, 10),
               tolerance = 1e-12)
  expect_equal(as.numeric(tab[["F value"]][1:3]),
               c(1.8, 0.8, 2 / 15), tolerance = 1e-12)
  expect_equal(unname(stats::coef(fit)[["treatmentB"]]), 3,
               tolerance = 1e-12)
  # For F(1,2), upper tail = 1 - sqrt(F/(F+2)).
  expect_equal(as.numeric(tab[["Pr(>F)"]][1:2]),
               c(0.3117527983883147, 0.4654775161751512),
               tolerance = 1e-12)
})

# A cyclic 3x3 Latin square. Row effects -1/0/+1, column effects
# -2/0/+2, treatment effects A/B/C = -3/0/+3, grand mean 10.
# Residuals (1,-1,0; 0,1,-1; -1,0,1) sum to zero for every
# row, column, and treatment. Their squared sum is 6.
latin_square_reference_data <- function() {
  data.frame(
    row = factor(rep(seq_len(3L), each = 3L)),
    column = factor(rep(seq_len(3L), times = 3L)),
    treatment = factor(c("A", "B", "C",
                         "B", "C", "A",
                         "C", "A", "B")),
    response = c(5, 8, 14,
                 8, 14, 8,
                 11, 8, 14)
  )
}

test_that("Latin-square ANOVA has independently calculated terms", {
  dat <- latin_square_reference_data()
  fit <- pharma_latin_square_anova(
    response ~ treatment + row + column, dat
  )
  tab <- summary(fit)[[1L]]

  # Treatment means are 7, 10, 13; row means 9, 10, 11;
  # column means 8, 10, 12. The orthogonal term sums of squares
  # are 3*(3^2 + 3^2) = 54, 3*(1^2 + 1^2) = 6, and
  # 3*(2^2 + 2^2) = 24. Residual SSE = 6 with two df.
  expect_s3_class(fit, "aov")
  expect_equal(as.numeric(tab[["Df"]]), c(2, 2, 2, 2))
  expect_equal(as.numeric(tab[["Sum Sq"]]), c(54, 6, 24, 6),
               tolerance = 1e-12)
  expect_equal(as.numeric(tab[["Mean Sq"]]), c(27, 3, 12, 3),
               tolerance = 1e-12)
  expect_equal(as.numeric(tab[["F value"]][1:3]), c(9, 1, 4),
               tolerance = 1e-12)
  expect_equal(unname(stats::coef(fit)[["treatmentC"]]), 6,
               tolerance = 1e-12)
  # For F(2,2), the upper tail is 1/(1+F).
  expect_equal(as.numeric(tab[["Pr(>F)"]][1:3]),
               c(0.1, 0.5, 0.2), tolerance = 1e-12)
})
