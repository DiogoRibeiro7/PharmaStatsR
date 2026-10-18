local_edition(3)

bic_reference_data <- function() {
  x <- rep(c(-3, -1, 1, 3), 3)
  error <- rep(c(1, -1, -1, 1), 3)
  group <- rep(c(-4, 0, 4), each = 4)
  data.frame(
    y = 2 + 1.5 * x + group + error,
    x = x, group = factor(group), weak = error
  )
}

# The three centered components are orthogonal. Their sums of squares are
# 135 (1.5*x), 128 (group), and 12 (error), so RSS0 = 275. A numeric x fit
# leaves RSS1 = 140, group means leave 147, and a weak fit leaves 263.
# Ranks are 1 for the null and 2/3/2 for the alternatives. Gaussian ML
# variance parameters cancel. These targets use no lm(), BIC(), or logLik().
bic_reference_log_scores <- function() {
  (12 * log(275 / c(x = 140, group = 147, weak = 263)) -
    c(1, 2, 1) * log(12)) / 2
}

test_that("BIC selection agrees with independent RSS and rank penalties", {
  d <- bic_reference_data()
  scores <- bic_reference_log_scores()
  expect_equal(
    exp(scores), c(x = 16.5820158483465, group = 3.57199554402121, weak = 0.377286311823438),
    tolerance = 1e-8
  )
  for (threshold in c(0.3, 1, 3, 5, 20)) {
    expect_identical(
      screen_covariates_bayesian(d, "y", names(scores), threshold),
      names(scores)[scores >= log(threshold)]
    )
  }
  for (candidate in names(scores)) {
    # Bracket the analytic threshold without relying on bit-identical logs
    # from a QR likelihood and the independent RSS calculation.
    for (delta in c(-1e-10, 1e-10)) {
      threshold <- exp(scores[[candidate]] + delta)
      expect_identical(
        screen_covariates_bayesian(d, "y", candidate, threshold),
        if (delta < 0) candidate else character(0)
      )
    }
  }
  expect_identical(
    screen_covariates_bayesian(d, "y", c("group", "weak", "x")),
    c("group", "x")
  )
})

test_that("independent scores use the common complete-case population", {
  d <- bic_reference_data()
  extra <- data.frame(
    y = c(10000, -10000, NA, 30000),
    x = c(NA, 1000, 2000, 3000),
    group = factor(c("0", NA, "4", "-4"), levels = levels(d$group)),
    weak = c(500, 1000, 2000, NaN)
  )
  full <- rbind(d, extra)
  full$unused <- NA_real_
  full$SubjectID <- NA_integer_
  scores <- bic_reference_log_scores()
  for (threshold in c(0.3, 1, 3, 5, 20)) {
    expect_identical(
      screen_covariates_bayesian(full, "y", names(scores), threshold),
      names(scores)[scores >= log(threshold)]
    )
  }
  expect_identical(nrow(full), 16L)
})

test_that("selection preserves rows, literal names and equivalent designs", {
  d <- bic_reference_data()
  original <- d
  scores <- bic_reference_log_scores()
  for (a in c(-7, 0.25, 1e-100, 1e100)) {
    changed <- d[rev(seq_len(nrow(d))), ]
    changed$y <- a * (changed$y + 13)
    changed$x <- 8 - 3 * changed$x
    changed$group <- factor(changed$group, levels = c("4", "-4", "0", "unused"))
    for (threshold in c(1, 3, 5, 20)) {
      expect_identical(
        screen_covariates_bayesian(changed, "y", names(scores), threshold),
        names(scores)[scores >= log(threshold)]
      )
    }
  }
  for (contrasts in list(c("contr.sum", "contr.poly"), c("contr.helmert", "contr.poly"))) {
    withr::local_options(contrasts = contrasts)
    expect_identical(
      screen_covariates_bayesian(d, "y", c("x", "group", "weak")),
      c("x", "group")
    )
  }
  for (group in list(as.character(d$group), ordered(d$group))) {
    changed <- d
    changed$group <- group
    expect_identical(screen_covariates_bayesian(changed, "y", "group"), "group")
  }
  names(d) <- c("response + units", "body mass", "treatment:group", "noise")
  expect_identical(
    screen_covariates_bayesian(
      d, "response + units", c(first = "treatment:group", second = "body mass")
    ),
    c("treatment:group", "body mass")
  )
  expect_identical(unname(d), unname(original))
})

test_that("finite strong evidence stays on the log scale", {
  x <- rep(c(-1, 1), 500)
  error <- rep(c(-1, -1, 1, 1), 250)
  d <- data.frame(y = 10 * x + 0.1 * error, x = x)
  # RSS0 = 100010, RSS1 = 10, rank difference = 1, n = 1000.
  log_score <- (1000 * log(10001) - log(1000)) / 2
  expect_gt(log_score, log(.Machine$double.xmax))
  expect_identical(
    screen_covariates_bayesian(d, "y", "x", .Machine$double.xmax), "x"
  )
})

test_that("saturated candidates fail with their original name", {
  d <- data.frame(y = c(2, 5, 3), x = c(-1, 0, 1))
  d[["one per subject"]] <- factor(letters[1:3])
  expect_error(
    screen_covariates_bayesian(d, "y", c("x", "one per subject"), 0.01),
    "candidate 'one per subject' needs positive residual degrees of freedom",
    fixed = TRUE
  )
  # The restriction is on the retained cohort, after all missing-row removal.
  d <- rbind(d, d[1, ])
  d$x[4] <- NA
  expect_error(
    screen_covariates_bayesian(d, "y", c("x", "one per subject")),
    "positive residual degrees of freedom"
  )
  # One residual degree of freedom is allowed. RSS0 = 35, RSS1 = 2,
  # n = 4, rank difference = 2, hence BF = (35/2)^2 / 4 = 76.5625.
  valid <- data.frame(y = c(1, 3, 5, 9), group = factor(c("a", "a", "b", "c")))
  expect_identical(screen_covariates_bayesian(valid, "y", "group", 76), "group")
  expect_identical(screen_covariates_bayesian(valid, "y", "group", 77), character(0))
})

test_that("non-finite likelihoods fail instead of silently selecting or omitting", {
  for (scale in c(1e-200, 1e200)) {
    d <- bic_reference_data()
    d$y <- scale * d$y
    expect_error(
      screen_covariates_bayesian(d, "y", c("x", "group", "weak")),
      "intercept-only model has a non-finite BIC",
      fixed = TRUE
    )
  }
  # The null variance is representable, while the exact categorical fit has
  # residual squares below the floating-point range even after QR rounding.
  d <- data.frame(y = c(-1, -1, 1, 1) * 1e-150, group = factor(c(1, 1, 2, 2)))
  expect_error(
    screen_covariates_bayesian(d, "y", "group"),
    "candidate 'group' has a non-finite BIC",
    fixed = TRUE
  )
})

test_that("the documented inclusive threshold accepts exact equality", {
  # Exact equality is a comparison contract; analytic scores above test
  # actual fitting and the two sides of each numerical threshold.
  local_mocked_bindings(BIC = function(object, ...) 10, .package = "stats")
  d <- bic_reference_data()
  expect_identical(screen_covariates_bayesian(d, "y", "x", 1), "x")
  expect_identical(screen_covariates_bayesian(d, "y", "x", 1 + 1e-8), character(0))
})
