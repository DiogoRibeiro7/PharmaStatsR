local_edition(3)

allometric_simulation_fixture <- function() {
  d <- data.frame(
    ID = c(9, 4, 9, 4, 9, 9, 4, 9, 4),
    TIME = c(1, 0, 0, 0.5, 1, 1.5, 2, 3, 0),
    WT = c(70, 140, 70, 140, 70, 70, 140, 70, 140),
    EVID = c(0, 1, 101, 0, 0, 1, 0, 0, 0),
    AMT = c(0, 100, 100, 0, 0, 50, 0, 0, 0)
  )
  rownames(d) <- paste0("record-", seq_len(nrow(d)))
  d
}

allometric_simulation_reference <- function() {
  effects <- c("eta.ka", "eta.cl")
  list(
    metadata = list(
      reference_weight = 70, exponents = c(cl = 0.75, v = 1),
      column_map = data.frame(
        role = c("response", "id", "time", "weight"),
        original = c("DV", "ID", "TIME", "WT"), model = c("DV", "ID", "TIME", "WT")
      )
    ),
    ui = nlmixr2est::nlmixr2(PharmaStatsR:::allometric_nlmixr_model(70)),
    theta = c(tka = log(2), tcl = log(4), tv = log(20), add.sd = 0.7),
    omega = matrix(c(0.25, 0, 0, 0.36), 2, dimnames = list(effects, effects))
  )
}

test_that("seeded simulations match independent subject effects and repeated-dose concentrations", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_simulation_reference()
  local_mocked_bindings(allometric_simulation_components = function(object) saved)
  d <- allometric_simulation_fixture()
  original <- d
  obs <- which(d$EVID == 0)
  groups <- match(d$ID, unique(d$ID))
  set.seed(227)
  expected <- replicate(4, {
    ka <- 2 * exp(rnorm(2, sd = 0.5))
    cl <- 4 * exp(rnorm(2, sd = 0.6))
    residuals <- rnorm(length(obs), sd = 0.7)
    # Evaluate the independent closed-form oral concentration once per dose,
    # then sum each subject's contributions at the requested observation.
    concentrations <- vapply(obs, function(i) {
      g <- groups[i]
      v <- 20 * d$WT[i] / 70
      ke <- cl[g] * (d$WT[i] / 70)^0.75 / v
      doses <- which(d$ID == d$ID[i] & d$EVID != 0 & d$TIME <= d$TIME[i])
      lag <- d$TIME[i] - d$TIME[doses]
      sum(d$AMT[doses] * ka[g] / (v * (ka[g] - ke)) *
        (exp(-ke * lag) - exp(-ka[g] * lag)))
    }, numeric(1))
    concentrations + residuals
  })
  expected_state <- .Random.seed
  set.seed(227)
  kind <- RNGkind()
  out <- simulate_nlmixr_allometric(NULL, d, 4)
  expect_equal(as.vector(out[obs, ]), as.vector(expected), tolerance = 1e-8)
  expect_identical(.Random.seed, expected_state)
  expect_identical(RNGkind(), kind)
  expect_true(all(is.na(out[-obs, ])))
  expect_identical(dim(out), c(nrow(d), 4L))
  expect_identical(rownames(out), rownames(d))
  expect_identical(colnames(out), paste0("sim_", 1:4))
  expect_identical(d, original)
  metadata <- attr(out, "simulation_parameters")
  expect_identical(metadata$omega, saved$omega)
  expect_identical(metadata$theta, saved$theta)
  expect_identical(metadata$sd_residual, 0.7)
  expect_identical(metadata$reference_weight, 70)
  expect_identical(metadata$exponents, c(cl = 0.75, v = 1))
  set.seed(227)
  expect_identical(simulate_nlmixr_allometric(NULL, d, 4), out)
  set.seed(227)
  shorter <- simulate_nlmixr_allometric(NULL, d, 2)
  expect_equal(shorter[, ], out[, 1:2])
  set.seed(227)
  one <- simulate_nlmixr_allometric(NULL, d, 1)
  expect_equal(one[, 1], out[, 1], tolerance = 1e-8)
  expect_identical(dim(one), c(nrow(d), 1L))
})

test_that("relabeling, literal columns and re-referencing preserve seeded responses", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_simulation_reference()
  local_mocked_bindings(allometric_simulation_components = function(object) saved)
  d <- allometric_simulation_fixture()
  set.seed(228)
  expected <- simulate_nlmixr_allometric(NULL, d, 3)
  d$ID <- ifelse(d$ID == 9, 1, 999)
  saved$metadata$column_map$original <- c("response + value", "subject id", "sample time", "PSR_ROW")
  names(d)[1:3] <- c("subject id", "sample time", "PSR_ROW")
  d$ID <- -1
  d$TIME <- -1
  d$WT <- -1
  d[["response + value"]] <- list(NULL)
  original <- d
  set.seed(228)
  expect_identical(simulate_nlmixr_allometric(NULL, d, 3), expected)
  expect_identical(d, original)
  saved$metadata$reference_weight <- 140
  saved$ui <- nlmixr2est::nlmixr2(PharmaStatsR:::allometric_nlmixr_model(140))
  saved$theta[c("tcl", "tv")] <- log(c(4 * 2^0.75, 40))
  set.seed(228)
  expect_equal(as.vector(simulate_nlmixr_allometric(NULL, d, 3)), as.vector(expected), tolerance = 1e-8)
})

test_that("shared subject concentrations cancel in duplicate-time response differences", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_simulation_reference()
  local_mocked_bindings(allometric_simulation_components = function(object) saved)
  d <- allometric_simulation_fixture()
  # Rows 1 and 5 are the same subject and time: only independent errors differ.
  set.seed(229)
  nsim <- 10000L
  responses <- simulate_nlmixr_allometric(NULL, d, nsim)
  difference <- responses[1, ] - responses[5, ]
  variance <- 2 * 0.7^2
  expect_lt(abs(mean(difference)), 6 * sqrt(variance / nsim))
  expect_lt(abs(var(difference) - variance), 6 * variance * sqrt(2 / (nsim - 1)))
  # At time zero the oral concentration is zero; additive noise is not clipped.
  expect_lt(abs(mean(responses[9, ])), 6 * 0.7 / sqrt(nsim))
  expect_lt(abs(var(responses[9, ]) - 0.7^2), 6 * 0.7^2 * sqrt(2 / (nsim - 1)))
  expect_true(any(responses[9, ] < 0))
  saved$theta[["add.sd"]] <- 0
  set.seed(229)
  no_residual <- simulate_nlmixr_allometric(NULL, d, 3)
  expect_identical(unname(no_residual[1, ]), unname(no_residual[5, ]))
  expect_gt(stats::var(no_residual[1, ]), 0)
  saved$omega[, ] <- 0
  fixed <- simulate_nlmixr_allometric(NULL, d, 3)
  expect_equal(unname(fixed[1, ]), rep(3.796641499118717, 3), tolerance = 1e-8)
  expect_equal(fixed[, 1], fixed[, 2])
})

test_that("singleton, empty, dose-only and mixed schedules keep their row contract", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_simulation_reference()
  local_mocked_bindings(allometric_simulation_components = function(object) saved)
  d <- allometric_simulation_fixture()
  one <- simulate_nlmixr_allometric(NULL, d[c(1, 3), ], 1)
  expect_identical(dim(one), c(2L, 1L))
  expect_true(is.finite(one[1, 1]))
  expect_true(is.na(one[2, 1]))
  extra <- d[3, ]
  extra$ID <- 77
  mixed <- rbind(extra, d)
  result <- simulate_nlmixr_allometric(NULL, mixed, 2)
  expect_identical(dim(result), c(10L, 2L))
  expect_true(all(is.na(result[mixed$EVID != 0, ])))
  expect_true(all(is.finite(result[mixed$EVID == 0, ])))
  set.seed(230)
  before <- .Random.seed
  local_mocked_bindings(rxSolve = function(...) stop("must not solve"), .package = "nlmixr2est")
  empty <- simulate_nlmixr_allometric(NULL, d[FALSE, ], 3)
  expect_identical(dim(empty), c(0L, 3L))
  expect_identical(colnames(empty), paste0("sim_", 1:3))
  only_doses <- simulate_nlmixr_allometric(NULL, d[d$EVID != 0, ], 2)
  expect_identical(dim(only_doses), c(3L, 2L))
  expect_true(all(is.na(only_doses)))
  expect_identical(.Random.seed, before)
})

test_that("observation-only subsetting composes with percentile diagnostics", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_simulation_reference()
  local_mocked_bindings(allometric_simulation_components = function(object) saved)
  d <- allometric_simulation_fixture()
  d$DV <- ifelse(d$EVID == 0, 2, NA_real_)
  set.seed(231)
  result <- simulate_nlmixr_allometric(NULL, d, 20)
  obs <- d$EVID == 0
  plot <- plot_simulated_vpc(d[obs, ], result[obs, , drop = FALSE], time = "TIME", bins = 3)
  expect_s3_class(plot, "ggplot")
  expect_true(all(plot$data$nsim == 20L))
  expect_identical(attr(plot, "vpc_bins")$row, rownames(d)[obs])
  expect_equal(sum(plot$data$n[plot$data$probability == 0.5]), sum(obs))
})

test_that("invalid input and absent RNG state are preserved before drawing", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_simulation_reference()
  local_mocked_bindings(allometric_simulation_components = function(object) saved)
  d <- allometric_simulation_fixture()
  set.seed(232)
  before <- .Random.seed
  for (n in list(NULL, 0, -1, 1.5, NA, Inf, c(1, 2), "2", 2i, matrix(2), .Machine$integer.max)) {
    expect_error(simulate_nlmixr_allometric(NULL, d, n), "nsim.*positive integer")
  }
  expect_error(simulate_nlmixr_allometric(NULL, d, 1000000000), "too large")
  expect_error(simulate_nlmixr_allometric(NULL, d[d$EVID == 0, ]), "explicit dose history")
  for (column in c("RATE", "DUR", "II", "ADDL", "SS", "MDV", "CENS", "LIMIT", "DVID")) {
    bad <- d
    bad[[column]] <- 0
    expect_error(simulate_nlmixr_allometric(NULL, bad, 1), "Unsupported event modifier")
  }
  for (column in c("ID", "TIME", "WT", "EVID", "AMT")) {
    bad <- d
    bad[[column]][1] <- NA_real_
    expect_error(simulate_nlmixr_allometric(NULL, bad), "finite real numeric")
  }
  bad <- d
  bad$WT[1] <- 71
  expect_error(simulate_nlmixr_allometric(NULL, bad), "constant within each subject")
  expect_identical(.Random.seed, before)
  on.exit(assign(".Random.seed", before, envir = .GlobalEnv), add = TRUE)
  rm(".Random.seed", envir = .GlobalEnv)
  expect_error(simulate_nlmixr_allometric(NULL, d, 0), "positive integer")
  expect_identical(dim(simulate_nlmixr_allometric(NULL, d[FALSE, ], 2)), c(0L, 2L))
  expect_true(all(is.na(simulate_nlmixr_allometric(NULL, d[d$EVID != 0, ], 2))))
  expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
})

test_that("only finite nonnegative diagonal absorption/clearance covariance is accepted", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_simulation_reference()
  local_mocked_bindings(allometric_prediction_components = function(object) saved)
  resolve <- PharmaStatsR:::allometric_simulation_components
  expect_identical(resolve(list(omega = saved$omega))$omega, saved$omega)
  invalid <- list(
    NULL, 1, diag(2), saved$omega[2:1, 2:1], saved$omega + 0.1,
    matrix(NA_real_, 2, 2, dimnames = dimnames(saved$omega))
  )
  negative <- saved$omega
  negative[1, 1] <- -1
  infinite <- saved$omega
  infinite[1, 1] <- Inf
  for (omega in c(invalid, list(negative, infinite))) {
    expect_error(resolve(list(omega = omega)), "diagonal covariance")
  }
})

test_that("incomplete and repeated backend records fail without leaking backend RNG draws", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_simulation_reference()
  local_mocked_bindings(allometric_simulation_components = function(object) saved)
  d <- allometric_simulation_fixture()
  obs <- which(d$EVID == 0)
  good <- data.frame(PSR_ROW = rep(obs, 2), sim.id = rep(1:2, each = length(obs)), pred = 1)
  bad <- list(
    NULL, good[-1, ], good[, c("PSR_ROW", "pred")],
    transform(good, sim.id = 0), transform(good, sim.id = 1.5),
    transform(good, sim.id = Inf), transform(good, pred = Inf),
    transform(good, PSR_ROW = NA_real_), transform(good, PSR_ROW = 2),
    transform(good, PSR_ROW = obs[1])
  )
  set.seed(233)
  for (i in 1:2) {
    rnorm(2, sd = 0.5)
    rnorm(2, sd = 0.6)
    rnorm(length(obs), sd = 0.7)
  }
  expected_state <- .Random.seed
  result <- good
  local_mocked_bindings(rxSolve = function(...) {
    runif(20)
    result
  }, .package = "nlmixr2est")
  for (value in bad) {
    result <- value
    set.seed(233)
    expect_error(simulate_nlmixr_allometric(NULL, d, 2), "observation.*replicate")
    expect_identical(.Random.seed, expected_state)
  }
  local_mocked_bindings(rxSolve = function(...) {
    runif(20)
    stop("solver failed")
  }, .package = "nlmixr2est")
  set.seed(233)
  expect_error(simulate_nlmixr_allometric(NULL, d, 2), "solver failed")
  expect_identical(.Random.seed, expected_state)
})

test_that("foreign models and unavailable optional backends fail clearly", {
  skip_if_not_installed("nlmixr2est")
  for (object in list(NULL, list(), data.frame(), lm(mpg ~ wt, data = mtcars))) {
    expect_error(simulate_nlmixr_allometric(object, allometric_simulation_fixture()), "Invalid allometric fit")
  }
  local_mocked_bindings(requireNamespace = function(...) FALSE, .package = "base")
  expect_error(simulate_nlmixr_allometric(NULL, NULL), "Package 'nlmixr2est' is required")
})


test_that("numerical overflow fails after drawing instead of returning partial simulations", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_simulation_reference()
  local_mocked_bindings(allometric_simulation_components = function(object) saved)
  d <- allometric_simulation_fixture()
  saved$omega[1, 1] <- .Machine$double.xmax
  set.seed(234)
  before <- .Random.seed
  expect_error(simulate_nlmixr_allometric(NULL, d, 2), "absorption and clearance.*positive and finite")
  expect_false(identical(.Random.seed, before))
  saved$omega[, ] <- 0
  saved$theta[["add.sd"]] <- .Machine$double.xmax
  set.seed(234)
  expect_error(simulate_nlmixr_allometric(NULL, d, 20), "finite")
})
