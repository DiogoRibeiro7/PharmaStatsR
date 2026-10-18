local_edition(3)

aic_reference_data <- function(proxy_noise = 1, v_effect = 1.1) {
  u <- rep(c(-1, 1), 8)
  v <- rep(c(-1, -1, 1, 1), 4)
  w <- rep(c(rep(-1, 4), rep(1, 4)), 2)
  z <- rep(c(-1, 1), each = 8)
  data.frame(
    id = seq_len(16), y = u + v_effect * v + 0.2 * z,
    u = u, v = v, proxy = u + v + proxy_noise * w
  )
}

test_that("the forward and backward path matches an independent RSS ledger", {
  d <- aic_reference_data()
  # u, v, w and z are orthogonal, centered, and each has squared norm 16.
  # Null RSS = 16*(1 + 1.1^2 + .2^2) = 36. The proxy has norm^2 48 and
  # inner product with y of 33.6, giving RSS = 36 - 33.6^2/48 = 12.48.
  # After adding v, u+w leaves half of u unexplained: RSS = 16*(.5+.04).
  # Adding u leaves only .2*z (RSS .64); removing proxy leaves that unchanged.
  rss <- c(36, 12.48, 8.64, 0.64, 0.64)
  rank <- c(1, 2, 3, 4, 3)
  expected_aic <- 16 * log(rss / 16) + 2 * rank
  ledger <- NULL
  real_step <- stats::step
  local_mocked_bindings(
    step = function(...) {
      # step() evaluates updated lm calls in its caller; keep that frame.
      call <- match.call()
      call[[1L]] <- real_step
      result <- eval(call, parent.frame())
      ledger <<- result$anova
      result
    },
    .package = "stats"
  )
  expect_identical(
    screen_covariates_stepwise(d, "y", "id", c("u", "v", "proxy")),
    c("v", "u")
  )
  expect_identical(as.character(ledger$Step), c(
    "", "+ .screen_covariate_3", "+ .screen_covariate_2",
    "+ .screen_covariate_1", "- .screen_covariate_3"
  ))
  expect_equal(ledger$`Resid. Dev`, rss, tolerance = 1e-10)
  expect_equal(ledger$`Resid. Df`, 16 - rank)
  expect_equal(ledger$AIC, expected_aic, tolerance = 1e-10)
  expect_true(all(diff(expected_aic) < 0))
  # All eight subsets have independently derived RSS; only u+v minimizes AIC.
  all_rss <- c(36, 20, 16.64, 12.48, 0.64, 10.32, 8.64, 0.64)
  all_rank <- c(1, 2, 2, 2, 3, 3, 3, 4)
  expect_identical(which.min(16 * log(all_rss / 16) + 2 * all_rank), 5L)
})

test_that("stepwise can stop at a local rather than global minimum", {
  d <- aic_reference_data(proxy_noise = 0.5, v_effect = 1)
  # RSS(proxy) = 16*(2.04 - 4/2.25), RSS(proxy+u) = RSS(proxy+v) = 3.84.
  # Neither one-term addition improves AIC, even though RSS(u+v) = .64.
  proxy_aic <- 16 * log((2.04 - 4 / 2.25)) + 4
  next_aic <- 16 * log(3.84 / 16) + 6
  best_aic <- 16 * log(0.64 / 16) + 6
  expect_gt(next_aic, proxy_aic)
  expect_lt(best_aic, proxy_aic)
  expect_identical(
    screen_covariates_stepwise(d, "y", "id", c("u", "v", "proxy")),
    "proxy"
  )
})

test_that("the independent path uses one complete-case cohort", {
  d <- aic_reference_data()
  extra <- data.frame(
    id = 17:20, y = c(10000, -10000, NA, 30000),
    u = c(NA, 1000, 2000, 3000), v = c(500, NA, 2000, 3000),
    proxy = c(1000, 2000, 3000, NaN)
  )
  full <- rbind(d, extra)
  full$id <- NA_integer_
  full$unused <- NA_real_
  original <- full
  expect_identical(
    screen_covariates_stepwise(full, "y", "id", c("u", "v", "proxy")),
    c("v", "u")
  )
  expect_identical(full, original)
})

test_that("unambiguous selections survive equivalent rows, scales and names", {
  d <- aic_reference_data()
  for (scale in c(-7, 0.25, 1e-100, 1e100)) {
    changed <- d[rev(seq_len(nrow(d))), ]
    changed$y <- scale * (changed$y + 13)
    changed$u <- 8 - 3 * changed$u
    changed$v <- 2 + 7 * changed$v
    expect_identical(
      screen_covariates_stepwise(changed, "y", "id", c("proxy", "u", "v")),
      c("v", "u")
    )
  }
  names(d) <- c("subject id", "response + units", "u mass", "v:group", "proxy(w)")
  expect_identical(
    screen_covariates_stepwise(
      d, "response + units", "subject id",
      c(first = "u mass", second = "v:group", third = "proxy(w)")
    ),
    c("v:group", "u mass")
  )
})

test_that("categorical terms receive the full rank penalty", {
  group <- rep(c(-1, 0, 1), each = 4)
  error <- rep(c(1, -1, -1, 1), 3)
  d <- data.frame(id = 1:12, y = group + error, group = factor(group))
  # Null RSS = 20, group RSS = 12, ranks 1 and 3. AIC difference < 0.
  expect_lt(12 * log(12 / 20) + 4, 0)
  expect_identical(screen_covariates_stepwise(d, "y", "id", "group"), "group")
  d$y <- 0.5 * group + error
  # Now null RSS = 14; the two-coefficient penalty outweighs the improvement.
  expect_gt(12 * log(12 / 14) + 4, 0)
  expect_identical(screen_covariates_stepwise(d, "y", "id", "group"), character(0))
  previous <- getOption("contrasts")
  on.exit(options(contrasts = previous), add = TRUE)
  for (contrasts in list(c("contr.sum", "contr.poly"), c("contr.helmert", "contr.poly"))) {
    options(contrasts = contrasts)
    for (candidate in list(
      factor(group, levels = c(1, -1, 0, 2)), ordered(group), as.character(group)
    )) {
      d$group <- candidate
      d$y <- group + error
      expect_identical(screen_covariates_stepwise(d, "y", "id", "group"), "group")
    }
  }
})

test_that("saturated accepted models are rejected with original names", {
  d <- data.frame(id = 1:3, y = c(2, 5, 3))
  d[["one per subject"]] <- factor(letters[1:3])
  expect_error(
    screen_covariates_stepwise(d, "y", "id", "one per subject"),
    "model with terms 'one per subject' needs positive residual degrees of freedom",
    fixed = TRUE
  )
  d <- rbind(d, d[1, ])
  d$y[4] <- NA
  expect_error(
    screen_covariates_stepwise(d, "y", "id", "one per subject"),
    "positive residual degrees of freedom"
  )
  # One residual degree of freedom is valid: n=4, null RSS=35, group RSS=2.
  valid <- data.frame(id = 1:4, y = c(1, 3, 5, 9), group = factor(c("a", "a", "b", "c")))
  expect_lt(4 * log(2 / 35) + 4, 0)
  expect_identical(screen_covariates_stepwise(valid, "y", "id", "group"), "group")
})

test_that("non-finite starting and accepted criteria stop selection", {
  for (scale in c(1e-200, 1e200)) {
    d <- aic_reference_data()
    d$y <- scale * d$y
    expect_error(
      screen_covariates_stepwise(d, "y", "id", c("u", "v", "proxy")),
      "intercept-only model has a non-finite criterion",
      fixed = TRUE
    )
  }
  d <- data.frame(id = 1:4, y = c(-1, -1, 1, 1) * 1e-150, group = factor(c(1, 1, 2, 2)))
  expect_error(
    screen_covariates_stepwise(d, "y", "id", "group"),
    "model with terms 'group' has a non-finite criterion",
    fixed = TRUE
  )
})

test_that("redundant candidate columns need not invalidate a valid path", {
  d <- aic_reference_data()
  d$duplicate <- d$u
  selected <- screen_covariates_stepwise(d, "y", "id", c("u", "v", "duplicate"))
  expect_true("v" %in% selected)
  expect_equal(sum(c("u", "duplicate") %in% selected), 1)
  expect_length(selected, 2)
})

test_that("a saturated upper scope does not forbid an intercept-only result", {
  # A 16-row Hadamard basis: all 15 centered columns have norm^2 = 16.
  # With y their sum, null RSS = 240 and every single-term RSS = 224.
  # Every addition costs AIC, so the valid search stops before saturation.
  basis <- matrix(1)
  for (i in seq_len(4)) {
    basis <- kronecker(basis, matrix(c(1, 1, 1, -1), 2))
  }
  predictors <- as.data.frame(basis[, -1])
  d <- cbind(data.frame(id = 1:16, y = rowSums(predictors)), predictors)
  expect_gt(16 * log(224 / 240) + 2, 0)
  expect_identical(
    screen_covariates_stepwise(d, "y", "id", names(predictors)), character(0)
  )
})
