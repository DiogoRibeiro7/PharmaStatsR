testthat::local_edition(3)

simulation_reference_data <- function() {
  time <- rep(c(-1, 0, 1), 4)
  data.frame(
    id = rep(1:4, each = 3), time = time,
    y = 2 + 1.5 * time + rep(c(-3, -1, 1, 3), each = 3) + rep(c(1, -2, 1), 4)
  )
}

test_that("seeded draws match independent balanced REML parameters", {
  d <- simulation_reference_data()
  model <- fit_covariate_model(d, "y", "id", "time")
  future <- data.frame(
    id = c(1, 99, 1), time = c(-1, 0, 1),
    row.names = c("visit-D", "visit-A", "visit-C")
  )
  before_model <- model
  before_data <- future
  # Balanced REML: within SS=24, df=7, between MS=20, m=3.
  # sigma^2=24/7; tau^2=(20-24/7)/3=116/21; fixed effects=(2,1.5).
  set.seed(217)
  expected <- replicate(4, {
    b <- rnorm(2, sd = sqrt(116 / 21))
    error <- rnorm(3, sd = sqrt(24 / 7))
    c(0.5, 2, 3.5) + b[c(1, 2, 1)] + error
  })
  expected_state <- .Random.seed
  set.seed(217)
  kind <- RNGkind()
  result <- simulate_covariate_model(model, future, nsim = 4)
  expect_equal(as.vector(result), as.vector(expected), tolerance = 1e-5)
  expect_identical(.Random.seed, expected_state)
  expect_identical(RNGkind(), kind)
  expect_identical(dim(result), c(3L, 4L))
  expect_identical(rownames(result), rownames(future))
  expect_identical(colnames(result), paste0("sim_", 1:4))
  parameters <- attr(result, "simulation_parameters")
  expect_equal(unname(parameters$mean), c(0.5, 2, 3.5), tolerance = 1e-7)
  expect_identical(names(parameters$mean), rownames(future))
  expect_equal(parameters$sd_subject^2, 116 / 21, tolerance = 1e-5)
  expect_equal(parameters$sd_residual^2, 24 / 7, tolerance = 1e-5)
  expect_identical(model, before_model)
  expect_identical(future, before_data)
  future$y <- c(NA, Inf, -Inf) # response is neither required nor used
  set.seed(217)
  expect_identical(simulate_covariate_model(model, future, 4), result)
})

test_that("replicated moments recover subject covariance and residual variance", {
  d <- simulation_reference_data()
  model <- fit_covariate_model(d, "y", "id", "time")
  future <- data.frame(id = c("A", "A", "B"), time = c(-1, 1, 0))
  set.seed(218)
  nsim <- 40000L
  result <- simulate_covariate_model(model, future, nsim)
  # Marginal variance=tau^2+sigma^2=188/21; same-subject covariance=116/21.
  target <- matrix(c(188, 116, 0, 116, 188, 0, 0, 0, 188) / 21, 3)
  tolerance_mean <- 6 * sqrt(diag(target) / nsim)
  tolerance_cov <- 6 * sqrt((outer(diag(target), diag(target)) + target^2) / (nsim - 1))
  expect_true(all(abs(rowMeans(result) - c(0.5, 3.5, 2)) < tolerance_mean))
  expect_true(all(abs(stats::cov(t(result)) - target) < tolerance_cov))
  # Subject effects cancel in the within-subject difference: Var(Y2-Y1)=2*sigma^2.
  difference_variance <- 48 / 7
  expect_lt(
    abs(stats::var(result[2, ] - result[1, ]) - difference_variance),
    6 * difference_variance * sqrt(2 / (nsim - 1))
  )
})

test_that("ID labels and storage types only define the supplied grouping", {
  d <- simulation_reference_data()
  model <- fit_covariate_model(d, "y", "id", "time")
  future <- data.frame(id = c(1, 2, 1), time = c(-1, 0, 1))
  set.seed(217)
  expected <- simulate_covariate_model(model, future, 5)
  ids <- list(
    c(100, 200, 100), c("new B", "new A", "new B"),
    factor(c("B", "A", "B"), levels = c("unused", "A", "B")),
    c(TRUE, FALSE, TRUE)
  )
  for (id in ids) {
    future$id <- id
    set.seed(217)
    expect_identical(simulate_covariate_model(model, future, 5), expected)
  }
})

test_that("literal names, categorical covariates and restored fits simulate identically", {
  d <- data.frame(
    id = rep(1:10, each = 4), time = rep(0:3, 10),
    group = factor(rep(c("A", "B"), 20))
  )
  d$y <- 2 + 0.5 * d$time + (d$group == "B") +
    rep(seq(-2, 2, length.out = 10), each = 4) + cos(seq_len(40))
  plain <- fit_covariate_model(d, "y", "id", c("time", "group"))
  set.seed(219)
  expected <- simulate_covariate_model(plain, d, 5)
  names(d) <- c("subject id", "visit time", "arm + group", "response value")
  repaired <- fit_covariate_model(d, "response value", "subject id",
    c("visit time", "arm + group"),
    repair_names = TRUE
  )
  saved <- unserialize(serialize(repaired, NULL))
  d$visit.time <- NA_real_ # alias distractors must not replace original names
  d$subject.id <- NA_real_
  for (fit in list(repaired, saved)) {
    set.seed(219)
    expect_equal(simulate_covariate_model(fit, d, 5), expected, tolerance = 1e-8)
  }
  d[["arm + group"]] <- "new"
  set.seed(219)
  before <- .Random.seed
  expect_error(simulate_covariate_model(saved, d, 5), "new level|not allowed")
  expect_identical(.Random.seed, before)
})

test_that("singletons, empty data and intercept-only fits have stable shapes", {
  d <- simulation_reference_data()
  model <- fit_covariate_model(d, "y", "id", "time")
  set.seed(217)
  one <- simulate_covariate_model(model, d[1, ], 1)
  expect_identical(dim(one), c(1L, 1L))
  before <- .Random.seed
  empty <- simulate_covariate_model(model, d[FALSE, ], 3)
  expect_identical(dim(empty), c(0L, 3L))
  expect_identical(colnames(empty), paste0("sim_", 1:3))
  expect_length(attr(empty, "simulation_parameters")$mean, 0)
  expect_identical(.Random.seed, before)
  intercept <- fit_covariate_model(d, "y", "id", character())
  result <- simulate_covariate_model(intercept, data.frame(id = c("A", "A")), 2)
  expect_identical(dim(result), c(2L, 2L))
  expect_equal(unname(attr(result, "simulation_parameters")$mean), c(2, 2))
  names(d)[2:3] <- c("Time", "DV")
  fitted <- fit_covariate_model(d, "DV", "id", "Time")
  simulated <- simulate_covariate_model(fitted, d, 100)
  plot <- plot_simulated_vpc(d, simulated, bins = 3)
  expect_s3_class(plot, "ggplot")
  expect_equal(plot$data$nsim, rep(100L, 9))
  expect_equal(plot$data$n, rep(4L, 9))
})

test_that("invalid inputs fail without advancing the random stream", {
  d <- simulation_reference_data()
  model <- fit_covariate_model(d, "y", "id", "time")
  set.seed(220)
  before <- .Random.seed
  for (n in list(NULL, 0, -1, 1.5, NA, Inf, c(1, 2), "2", 2i, matrix(2), .Machine$integer.max)) {
    expect_error(simulate_covariate_model(model, d, n), "nsim.*positive integer")
  }
  expect_error(simulate_covariate_model(model, d, 1000000000), "too large")
  for (value in c(NA, NaN, Inf, -Inf)) {
    changed <- d
    changed$id[1] <- value
    expect_error(simulate_covariate_model(model, changed), "identifiers.*observed and finite")
    changed <- d
    changed$time[1] <- value
    expect_error(simulate_covariate_model(model, changed), "Prediction column.*observed and finite")
  }
  for (bad in list(NULL, d[c("time", "y")], d[c("id", "y")])) {
    expect_error(simulate_covariate_model(model, bad))
  }
  changed <- d
  changed$id <- as.list(changed$id)
  expect_error(simulate_covariate_model(model, changed), "numeric, logical, character, or factor")
  changed <- d
  changed$time <- as.character(changed$time)
  expect_error(simulate_covariate_model(model, changed), "incompatible type")
  names(changed)[2] <- "id"
  expect_error(simulate_covariate_model(model, changed), "unique column names")
  expect_error(simulate_covariate_model(NULL, d), "Invalid covariate model")
  for (sigma in list(NULL, -1, 0, NA, Inf, c(1, 2), "1", 1i)) {
    bad <- model
    bad$sigma <- sigma
    expect_error(simulate_covariate_model(bad, d), "residual standard deviation")
  }
  bad <- model
  bad$sigma <- .Machine$double.xmax
  expect_error(simulate_covariate_model(bad, d), "variance must be finite")
  bad <- model
  bad$modelStruct$reStruct <- nlme::reStruct(~ 1 | id)
  expect_error(simulate_covariate_model(bad, d), "covariance is invalid")
  bad <- model
  bad$data <- NULL
  expect_error(simulate_covariate_model(bad, d), "Invalid covariate model")
  bad <- model
  bad$column_map <- data.frame(role = "id", original = "id", model = "id")
  expect_error(simulate_covariate_model(bad, d), "Invalid covariate model")
  bad <- model
  bad$groups$nested <- 1
  expect_error(simulate_covariate_model(bad, d), "Invalid covariate model")
  bad <- model
  class(bad) <- c("nlme", "lme")
  expect_error(simulate_covariate_model(bad, d), "linear random-intercept model")
  expect_identical(.Random.seed, before)
})

test_that("random slopes and correlated or weighted residual models are rejected", {
  set.seed(221)
  d <- data.frame(id = rep(1:20, each = 6), time = rep(seq(-1, 1, length.out = 6), 20))
  d$y <- 2 + 1.5 * d$time + rep(rnorm(20, sd = 2), each = 6) +
    rep(rnorm(20, sd = 1.5), each = 6) * d$time + rnorm(120)
  slope <- nlme::lme(y ~ time, random = ~ time | id, data = d)
  slope_only <- nlme::lme(y ~ time, random = ~ 0 + time | id, data = d)
  correlated <- nlme::lme(y ~ time,
    random = ~ 1 | id, data = d,
    correlation = nlme::corCompSymm(value = 0.1, form = ~ 1 | id)
  )
  weighted <- nlme::lme(y ~ time,
    random = ~ 1 | id, data = d,
    weights = nlme::varExp(form = ~time)
  )
  before <- .Random.seed
  expect_error(simulate_covariate_model(slope, d), "without random slopes")
  expect_error(simulate_covariate_model(slope_only, d), "without random slopes")
  expect_error(simulate_covariate_model(correlated, d), "independent constant-variance")
  expect_error(simulate_covariate_model(weighted, d), "independent constant-variance")
  expect_identical(.Random.seed, before)
})

test_that("empty input and validation do not initialize an absent RNG state", {
  d <- simulation_reference_data()
  model <- fit_covariate_model(d, "y", "id", "time")
  check_without_seed <- function() {
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
    on.exit({
      if (had_seed) {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    })
    if (had_seed) rm(".Random.seed", envir = .GlobalEnv)
    simulate_covariate_model(model, d[FALSE, ], 2)
    expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
    expect_error(simulate_covariate_model(model, d, 0), "positive integer")
    expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
  }
  check_without_seed()
})


test_that("training-row omission does not silently select simulation rows", {
  d <- simulation_reference_data()
  d$y[1] <- NA_real_
  model <- fit_covariate_model(d, "y", "id", "time")
  set.seed(217)
  result <- simulate_covariate_model(model, d, 3)
  expect_identical(dim(result), c(12L, 3L))
  expect_true(all(is.finite(result)))
  expect_identical(rownames(result), rownames(d))
  expect_equal(attr(result, "simulation_parameters")$mean, predict_covariate_model(model, d))
})
