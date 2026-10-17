local_edition(3)

allometric_fixture <- function() {
  d <- data.frame(
    ID = rep(1:3, each = 5), TIME = rep(c(0, 0.5, 1, 2, 4), 3),
    DV = rep(c(NA_real_, 1, 2, 3, 2), 3),
    WT = rep(c(35, 70, 140), each = 5),
    EVID = rep(c(101, 0, 0, 0, 0), 3), AMT = rep(c(100, 0, 0, 0, 0), 3)
  )
  rownames(d) <- paste0("record-", seq_len(nrow(d)))
  d
}

prepare_allometric_fixture <- function(data = allometric_fixture(), weight = "WT",
                                       reference_weight = 70, response = "DV",
                                       id = "ID", time = "TIME") {
  PharmaStatsR:::prepare_allometric_data(data, weight, reference_weight, response, id, time)
}

test_that("allometry maps literal columns without overwriting or changing input", {
  d <- allometric_fixture()
  original <- d
  out <- prepare_allometric_fixture(d)
  expect_identical(d, original)
  expect_identical(names(out), c("ID", "TIME", "DV", "WT", "EVID", "AMT", "CMT"))
  expect_identical(rownames(out), rownames(d))
  expect_equal(out$DV[d$EVID == 0], d$DV[d$EVID == 0])
  expect_identical(out$DV[d$EVID != 0], rep(0, 3))
  expect_identical(out$EVID, as.integer(d$EVID != 0))
  expect_identical(out$CMT, ifelse(d$EVID != 0, 1L, 2L))
  names(d)[1:4] <- c("subject id", "visit time", "response + dose", "body ` mass")
  d$ID <- -1
  d$WT <- -1
  d$ignored <- list(NULL)
  mapped <- prepare_allometric_fixture(d, "body ` mass",
    response = "response + dose",
    id = "subject id", time = "visit time"
  )
  expect_identical(mapped, out)
  order <- c(11:15, 1:5, 6:10)
  expect_identical(prepare_allometric_fixture(original[order, ]), out[order, ])
  d <- original
  d$CMT <- out$CMT
  expect_identical(prepare_allometric_fixture(d), out)
})

test_that("allometry rejects ambiguous or incomplete schemas and controls", {
  d <- allometric_fixture()
  expect_error(prepare_allometric_fixture(1), "data.frame")
  expect_error(prepare_allometric_fixture(d[FALSE, ]), "dosing and observation")
  for (bad in list(NULL, character(), NA_character_, "", c("WT", "DV"), matrix("WT"), 1)) {
    expect_error(prepare_allometric_fixture(d, weight = bad), "must name one column")
  }
  expect_error(prepare_allometric_fixture(d, weight = "missing"), "Variables not found")
  expect_error(prepare_allometric_fixture(d, weight = "DV"), "must be distinct")
  expect_error(prepare_allometric_fixture(d, weight = "AMT"), "must be distinct")
  expect_error(prepare_allometric_fixture(d[names(d) != "EVID"]), "EVID")
  for (name in c("RATE", "DUR", "II", "ADDL", "SS", "MDV", "CENS", "LIMIT", "DVID", "rate")) {
    bad <- d
    bad[[name]] <- 0
    expect_error(prepare_allometric_fixture(bad), "Unsupported event modifier")
  }
  bad <- d
  names(bad)[2] <- "ID"
  expect_error(prepare_allometric_fixture(bad), "unique column names")
  for (control in list(NULL, 1, list(2), list(seed = 1, seed = 2), structure(list(1), names = NA_character_))) {
    expect_error(fit_nlmixr_allometric(d, "WT", control = control), "uniquely named")
  }
})

test_that("weight and reference scales have explicit finite and subject boundaries", {
  d <- allometric_fixture()
  for (ref in list(0, -1, Inf, NaN, NA_real_, "70", numeric(), c(70, 80), matrix(70), 1 + 1i)) {
    expect_error(prepare_allometric_fixture(d, reference_weight = ref), "positive finite")
  }
  for (value in c(0, -1, Inf, NA_real_, NaN)) {
    bad <- d
    bad$WT[1:5] <- value
    expect_error(prepare_allometric_fixture(bad), "positive|finite")
  }
  bad <- d
  bad$WT[1] <- 36
  expect_error(prepare_allometric_fixture(bad), "constant within each subject")
  bad <- d
  bad$WT <- as.character(bad$WT)
  expect_error(prepare_allometric_fixture(bad), "real numeric")
  bad <- d
  bad$WT <- .Machine$double.xmax
  expect_error(prepare_allometric_fixture(bad, reference_weight = .Machine$double.xmin), "ratios")
  bad$WT <- .Machine$double.xmin
  expect_error(prepare_allometric_fixture(bad, reference_weight = .Machine$double.xmax), "ratios")
  d$WT <- 70
  expect_identical(prepare_allometric_fixture(d)$WT, d$WT)
})

test_that("event and observation validation prevents silent exclusions", {
  d <- allometric_fixture()
  for (value in c(0, -1, 1.5, .Machine$integer.max + 1, NA_real_)) {
    bad <- d
    bad$ID[1] <- value
    expect_error(prepare_allometric_fixture(bad), "positive integers|finite real")
  }
  expect_error(prepare_allometric_fixture(d[d$ID == 1, ]), "two subjects")
  for (value in c(-1, Inf, NA_real_)) {
    bad <- d
    bad$TIME[2] <- value
    expect_error(prepare_allometric_fixture(bad), "nonnegative|finite real")
  }
  bad <- d
  bad$EVID[1] <- 2
  expect_error(prepare_allometric_fixture(bad), "only 0, 1, or 101")
  bad <- d
  bad$AMT[1] <- 0
  expect_error(prepare_allometric_fixture(bad), "positive AMT")
  bad <- d
  bad$AMT[2] <- 1
  expect_error(prepare_allometric_fixture(bad), "zero AMT")
  expect_error(prepare_allometric_fixture(d[-1, ]), "at least one dose")
  expect_error(prepare_allometric_fixture(d[-c(3, 4, 5), ]), "two observations")
  for (value in c(NA_real_, NaN, Inf, -Inf)) {
    bad <- d
    bad$DV[2] <- value
    expect_error(prepare_allometric_fixture(bad), "finite on observations")
  }
  bad <- d
  bad$CMT <- 1
  expect_error(prepare_allometric_fixture(bad), "2 for observations")
  bad$CMT <- ifelse(bad$EVID == 0, 2, 1)
  bad$CMT[2] <- NA
  expect_error(prepare_allometric_fixture(bad), "CMT")
})

test_that("allometric fitting reports an unavailable backend after validation", {
  local_mocked_bindings(
    requireNamespace = function(package, quietly = TRUE) FALSE, .package = "base"
  )
  expect_error(fit_nlmixr_allometric(allometric_fixture(), "WT"), "Package 'nlmixr2est' is required")
})

test_that("backend allometric concentrations match closed-form oral targets", {
  skip_if_not_installed("nlmixr2est")
  d <- prepare_allometric_fixture()
  ui <- nlmixr2est::nlmixr2(PharmaStatsR:::allometric_nlmixr_model(70))
  expect_identical(ui$covariates, "WT")
  parameters <- c(tka = log(2), tcl = log(4), tv = log(20), eta.ka = 0, eta.cl = 0, add.sd = 0)
  solve <- function(ui, data = d, params = parameters) {
    nlmixr2est::rxSolve(ui,
      params = params, events = data,
      omega = NA, sigma = NA, returnType = "data.frame"
    )
  }
  solved <- solve(ui)
  obs <- d[d$EVID == 0, ]
  cl <- 4 * (obs$WT / 70)^0.75
  v <- 20 * obs$WT / 70
  ke <- cl / v
  target <- 100 * 2 / (v * (2 - ke)) * (exp(-ke * obs$TIME) - exp(-2 * obs$TIME))
  expect_equal(solved$pred, target, tolerance = 1e-8)
  expect_equal(solved$ka, rep(2, nrow(obs)), tolerance = 1e-12)
  expect_equal(solved$cl, cl, tolerance = 1e-12)
  expect_equal(solved$v, v, tolerance = 1e-12)
  expect_equal(solved$time, obs$TIME)
  expect_equal(solved$WT, obs$WT)
  # Fixed numeric values at 70 kg distinguish the dose/clearance/volume scale.
  expect_equal(solved$pred[5:8], c(2.98309987146954, 3.796641499118717, 3.622246706371695, 2.494408341607328), tolerance = 1e-8)

  # Re-reference the same physical model: predictions must not change.
  ui140 <- nlmixr2est::nlmixr2(PharmaStatsR:::allometric_nlmixr_model(140))
  reparameterized <- parameters
  reparameterized["tcl"] <- log(4 * 2^0.75)
  reparameterized["tv"] <- log(40)
  expect_equal(solve(ui140, params = reparameterized)$pred, target, tolerance = 1e-8)
  # Changing weight and the reference to a common new unit has no effect.
  rescaled <- d
  rescaled$WT <- rescaled$WT / 1000
  ui_rescaled <- nlmixr2est::nlmixr2(PharmaStatsR:::allometric_nlmixr_model(0.07))
  expect_equal(solve(ui_rescaled, rescaled)$pred, target, tolerance = 1e-8)
  # Subject effects act on absorption and clearance, not on volume.
  conditional <- parameters
  conditional[c("eta.ka", "eta.cl")] <- log(c(1.5, 2))
  conditional_target <- 100 * 3 / (v * (3 - 2 * ke)) * (exp(-2 * ke * obs$TIME) - exp(-3 * obs$TIME))
  # A parameter data frame supplies one fixed eta pair per subject. omega=NA
  # instead zeros the UI random effects, even when eta names occur in params.
  subject_params <- as.data.frame(as.list(conditional))
  subject_params <- subject_params[rep(1L, 3L), , drop = FALSE]
  conditional_solved <- nlmixr2est::rxSolve(ui,
    params = subject_params, events = d,
    sigma = NA, returnType = "data.frame"
  )
  expect_equal(conditional_solved$pred, conditional_target, tolerance = 1e-8)
  expect_equal(conditional_solved$ka, rep(3, nrow(obs)))
  expect_equal(conditional_solved$cl, 2 * cl)
  expect_equal(conditional_solved$v, v)
  restored <- unserialize(serialize(ui, NULL))
  expect_equal(solve(restored)$pred, target, tolerance = 1e-8)

  # Explicit repeated doses add their independent single-dose contributions.
  repeated <- d
  extra <- d[d$EVID == 1, ]
  extra$TIME <- 1.5
  extra$AMT <- 50
  repeated <- rbind(repeated, extra)
  repeated <- repeated[order(repeated$ID, repeated$TIME), ]
  lag <- pmax(obs$TIME - 1.5, 0)
  extra_target <- 50 * 2 / (v * (2 - ke)) * (exp(-ke * lag) - exp(-2 * lag))
  expect_equal(solve(ui, repeated)$pred, target + extra_target, tolerance = 1e-8)
})

test_that("fitting forwards named controls and records original literal names", {
  skip_if_not_installed("nlmixr2est")
  captured <- NULL
  parse_model <- nlmixr2est::nlmixr2
  local_mocked_bindings(
    nlmixr2 = function(object, data, est, control) {
      captured <<- list(model = object, data = data, est = est, control = control)
      data.frame(PRED = seq_len(sum(data$EVID == 0)))
    }, .package = "nlmixr2est"
  )
  d <- allometric_fixture()
  names(d)[1:4] <- c("subject id", "sample time", "response value", "weight kg")
  original <- d
  fit <- fit_nlmixr_allometric(d, "weight kg",
    reference_weight = 80,
    response = "response value", id = "subject id", time = "sample time",
    control = list(seed = 123, nBurn = 50, nEm = 50, print = 1),
    initial = list(
      ka = 2, cl = 4, v = 20, eta_ka_var = 0.25,
      eta_cl_var = 0.36, residual_sd = 0.7
    )
  )
  expect_identical(d, original)
  expect_identical(captured$est, "saem")
  expect_equal(captured$control$seed, 123)
  expect_identical(
    captured$control,
    nlmixr2est::saemControl(seed = 123, nBurn = 50, nEm = 50, print = 1)
  )
  expect_identical(captured$data, prepare_allometric_fixture())
  expect_identical(attr(fit, "allometry")$reference_weight, 80)
  expect_identical(
    attr(fit, "allometry")$column_map$original,
    c("response value", "subject id", "sample time", "weight kg")
  )
  expect_identical(fit$PRED, 1:12)
  ui <- parse_model(captured$model)
  expect_equal(ui$theta, c(tka = log(2), tcl = log(4), tv = log(20), add.sd = 0.7))
  expect_equal(unname(ui$omega), diag(c(0.25, 0.36)))
  expect_identical(
    attr(fit, "allometry")$initial,
    c(ka = 2, cl = 4, v = 20, eta_ka_var = 0.25, eta_cl_var = 0.36, residual_sd = 0.7)
  )
})

test_that("real SAEM fitting retains allometry and native population predictions", {
  skip_if_not_installed("nlmixr2est")
  skip_if_not_installed("nlmixr2data")
  d <- nlmixr2data::theo_sd
  expect_error(fit_nlmixr_allometric(d, "WT", control = list(not_a_control = 1)), "Unknown SAEM")
  fit <- fit_nlmixr_allometric(d, "WT", control = list(seed = 99))
  expect_s3_class(fit, "nlmixr2FitData")
  expect_true(all(is.finite(fit$PRED)))
  expect_equal(nrow(fit), sum(d$EVID == 0))
  metadata <- attr(fit, "allometry")
  expect_identical(metadata$reference_weight, 70)
  expect_identical(metadata$exponents, c(cl = 0.75, v = 1))
  expect_identical(
    metadata$initial,
    c(ka = 1, cl = 1, v = exp(1), eta_ka_var = 1, eta_cl_var = 1, residual_sd = 1)
  )
  expect_identical(metadata$column_map$model, c("DV", "ID", "TIME", "WT"))
  params <- c(fit$theta, eta.ka = 0, eta.cl = 0)
  solved <- nlmixr2est::rxSolve(fit$ui,
    params = params,
    events = prepare_allometric_fixture(d), omega = NA, sigma = NA, returnType = "data.frame"
  )
  expect_equal(solved$pred, fit$PRED, tolerance = 1e-6)
  restored <- unserialize(serialize(fit, NULL))
  expect_identical(attr(restored, "allometry"), metadata)
  expect_equal(restored$PRED, fit$PRED)
})


test_that("starting values preserve defaults and resolve named natural-scale overrides", {
  defaults <- c(ka = 1, cl = 1, v = exp(1), eta_ka_var = 1, eta_cl_var = 1, residual_sd = 1)
  resolve <- PharmaStatsR:::allometric_initial_values
  expect_identical(resolve(), defaults)
  initial <- list(residual_sd = 0.7, ka = c(named = 2L), eta_cl_var = 0.36)
  original <- initial
  expected <- defaults
  expected[c("ka", "eta_cl_var", "residual_sd")] <- c(2, 0.36, 0.7)
  expect_identical(resolve(initial), expected)
  expect_identical(initial, original)
  expect_identical(resolve(rev(initial)), expected)
  expect_identical(resolve(as.list(defaults)), defaults)
})

test_that("invalid starting values fail before backend loading or estimation", {
  local_mocked_bindings(
    requireNamespace = function(...) stop("backend must not be consulted"), .package = "base"
  )
  d <- allometric_fixture()
  for (bad in list(
    NULL, c(ka = 2), list(2), list(ka = 1, ka = 2),
    structure(list(1), names = NA_character_), structure(list(1), names = ""),
    structure(list(ka = 2), class = "custom"), structure(list(ka = 2), dim = c(1L, 1L))
  )) {
    expect_error(fit_nlmixr_allometric(d, "WT", initial = bad), "uniquely named")
  }
  expect_error(fit_nlmixr_allometric(d, "WT", initial = list(tka = 0)), "Unknown initial values: tka")
  expect_error(fit_nlmixr_allometric(d, "WT", initial = list(KA = 2)), "Allowed names")
  for (name in c("ka", "cl", "v", "eta_ka_var", "eta_cl_var", "residual_sd")) {
    for (value in list(
      NULL, 0, -1, NA_real_, NaN, Inf, -Inf, "2", TRUE,
      c(1, 2), numeric(), matrix(2), 1 + 1i, list(2), quote(stop("not evaluated")),
      structure(2, class = "custom")
    )) {
      initial <- setNames(list(value), name)
      expect_error(
        fit_nlmixr_allometric(d, "WT", initial = initial),
        paste0("initial\\$", name, ".*positive finite numeric")
      )
    }
  }
})

test_that("compiled initialization uses logs, variances and residual SD without fixing them", {
  skip_if_not_installed("nlmixr2est")
  resolve <- PharmaStatsR:::allometric_initial_values
  build <- function(starts = resolve(), reference = 70) {
    nlmixr2est::nlmixr2(PharmaStatsR:::allometric_nlmixr_model(reference, starts))
  }
  default <- build()
  expect_equal(default$theta, c(tka = 0, tcl = 0, tv = 1, add.sd = 1), tolerance = 1e-14)
  expect_equal(unname(default$omega), diag(2))
  expect_false(any(default$iniDf$fix))
  starts <- resolve(list(
    ka = 2, cl = 4, v = 20,
    eta_ka_var = 0.25, eta_cl_var = 0.36, residual_sd = 0.7
  ))
  ui <- build(starts)
  expect_equal(ui$theta, c(tka = log(2), tcl = log(4), tv = log(20), add.sd = 0.7), tolerance = 1e-14)
  expect_equal(
    ui$omega,
    matrix(c(0.25, 0, 0, 0.36), 2, dimnames = list(c("eta.ka", "eta.cl"), c("eta.ka", "eta.cl")))
  )
  expect_false(any(ui$iniDf$fix))
  expect_identical(ui$covariates, "WT")
  restored <- unserialize(serialize(ui, NULL))
  expect_equal(restored$theta, ui$theta)
  expect_equal(restored$omega, ui$omega)

  # No parameter override: the solver must use the supplied initialization.
  d <- prepare_allometric_fixture()
  solve <- function(model) {
    nlmixr2est::rxSolve(model,
      events = d,
      omega = NA, sigma = NA, returnType = "data.frame"
    )
  }
  out <- solve(ui)
  obs <- d[d$EVID == 0, ]
  cl <- 4 * (obs$WT / 70)^0.75
  v <- 20 * obs$WT / 70
  ke <- cl / v
  target <- 200 / (v * (2 - ke)) * (exp(-ke * obs$TIME) - exp(-2 * obs$TIME))
  expect_equal(out$pred, target, tolerance = 1e-8)
  expect_equal(out$pred[5:8], c(
    2.983099871469540, 3.796641499118717,
    3.622246706371695, 2.494408341607328
  ), tolerance = 1e-8)
  expect_equal(solve(restored)$pred, target, tolerance = 1e-8)
  starts[c("cl", "v")] <- starts[c("cl", "v")] * c(2^0.75, 2)
  expect_equal(solve(build(starts, 140))$pred, target, tolerance = 1e-8)
})

test_that("custom starts reach a real fit and remain distinct from fitted estimates", {
  skip_if_not_installed("nlmixr2est")
  skip_if_not_installed("nlmixr2data")
  initial <- list(
    ka = 1.5, cl = 3.2, v = 32, eta_ka_var = 0.25,
    eta_cl_var = 0.36, residual_sd = 0.7
  )
  original <- initial
  fit <- fit_nlmixr_allometric(nlmixr2data::theo_sd, "WT",
    control = list(seed = 99), initial = initial
  )
  expect_s3_class(fit, "nlmixr2FitData")
  expect_true(all(is.finite(fit$PRED)))
  expect_true(all(is.finite(fit$theta)))
  expect_identical(initial, original)
  metadata <- attr(fit, "allometry")
  expect_identical(metadata$initial, unlist(initial))
  expect_identical(metadata$reference_weight, 70)
  expect_identical(metadata$exponents, c(cl = 0.75, v = 1))
  expect_false(isTRUE(all.equal(
    unname(fit$theta[c("tka", "tcl", "tv")]),
    log(c(1.5, 3.2, 32))
  )))
  restored <- unserialize(serialize(fit, NULL))
  expect_identical(attr(restored, "allometry"), metadata)
  expect_equal(restored$PRED, fit$PRED)
  # Native fitted predictions still agree with the fitted stored model.
  solved <- nlmixr2est::rxSolve(restored$ui,
    params = restored$theta,
    events = prepare_allometric_fixture(nlmixr2data::theo_sd),
    omega = NA, sigma = NA, returnType = "data.frame"
  )
  expect_equal(solved$pred, fit$PRED, tolerance = 1e-6)
})
