local_edition(3)

allometric_prediction_fixture <- function() {
  d <- data.frame(
    ID = c(9, 4, 9, 4, 9, 9, 4, 9, 4),
    TIME = c(1, 0, 0, 0.5, 1, 1.5, 2, 3, 0),
    WT = c(70, 140, 70, 140, 70, 70, 140, 70, 140),
    EVID = c(0, 1, 101, 0, 0, 1, 0, 0, 0),
    AMT = c(0, 100, 100, 0, 0, 50, 0, 0, 0)
  )
  rownames(d) <- paste0("event-", seq_len(nrow(d)))
  d
}

allometric_prediction_reference <- function() {
  starts <- PharmaStatsR:::allometric_initial_values(list(ka = 2, cl = 4, v = 20))
  list(
    metadata = list(
      reference_weight = 70, exponents = c(cl = 0.75, v = 1),
      column_map = data.frame(
        role = c("response", "id", "time", "weight"),
        original = c("DV", "ID", "TIME", "WT"), model = c("DV", "ID", "TIME", "WT")
      )
    ),
    ui = nlmixr2est::nlmixr2(PharmaStatsR:::allometric_nlmixr_model(70, starts)),
    theta = c(tka = log(2), tcl = log(4), tv = log(20), add.sd = 0.7)
  )
}

test_that("population prediction restores rows and matches independent repeated-dose targets", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_prediction_reference()
  local_mocked_bindings(allometric_prediction_components = function(object) saved)
  d <- allometric_prediction_fixture()
  original <- d
  # Independent single-dose Bateman expression; multiple doses superpose.
  concentration <- function(time, weight, dose = 100) {
    v <- 20 * weight / 70
    ke <- (4 * (weight / 70)^0.75) / v
    dose * 2 / (v * (2 - ke)) * (exp(-ke * time) - exp(-2 * time))
  }
  expected <- c(
    3.796641499118717, NA, NA, concentration(0.5, 140),
    3.796641499118717, NA, concentration(2, 140),
    concentration(3, 70) + concentration(1.5, 70, 50), 0
  )
  out <- predict_nlmixr_allometric(NULL, d)
  expect_equal(out, setNames(expected, rownames(d)), tolerance = 1e-8)
  expect_identical(d, original)
  expect_identical(predict_nlmixr_allometric(NULL, d), out)
  order <- c(9, 6, 2, 8, 5, 4, 3, 1, 7)
  expect_equal(predict_nlmixr_allometric(NULL, d[order, ]), out[order], tolerance = 1e-8)
  # Every batch supplies its own complete schedule; IDs carry no fitted effects.
  one <- d[d$ID == 9, ]
  expect_equal(predict_nlmixr_allometric(NULL, one), out[d$ID == 9], tolerance = 1e-8)
  one$ID <- 12345
  expect_equal(predict_nlmixr_allometric(NULL, one), out[d$ID == 9], tolerance = 1e-8)
  # Changing reference and parameterization preserves the same physical model.
  saved$metadata$reference_weight <- 140
  saved$ui <- nlmixr2est::nlmixr2(PharmaStatsR:::allometric_nlmixr_model(140))
  saved$theta[c("tcl", "tv")] <- log(c(4 * 2^0.75, 40))
  expect_equal(predict_nlmixr_allometric(NULL, d), out, tolerance = 1e-8)
})

test_that("prediction uses literal saved names and ignores responses without collisions", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_prediction_reference()
  local_mocked_bindings(allometric_prediction_components = function(object) saved)
  d <- allometric_prediction_fixture()
  expected <- predict_nlmixr_allometric(NULL, d)
  saved$metadata$column_map$original <- c("response + value", "subject id", "sample time", "PSR_ROW")
  names(d)[1:3] <- c("subject id", "sample time", "PSR_ROW")
  d$ID <- -1
  d$TIME <- -1
  d$WT <- -1
  d[["response + value"]] <- list(NULL)
  d$extra <- Inf
  original <- d
  expect_equal(predict_nlmixr_allometric(NULL, d), expected)
  expect_identical(d, original)
  expect_error(predict_nlmixr_allometric(NULL, d[names(d) != "PSR_ROW"]), "Variables not found")
  d$CMT <- ifelse(d$EVID == 0, 2, 1)
  expect_equal(predict_nlmixr_allometric(NULL, d), expected)
})

test_that("prediction supports singleton observations, empty and dose-only schedules", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_prediction_reference()
  local_mocked_bindings(allometric_prediction_components = function(object) saved)
  d <- allometric_prediction_fixture()
  one <- d[c(1, 3), ]
  expect_equal(predict_nlmixr_allometric(NULL, one),
    setNames(c(3.796641499118717, NA), rownames(one)),
    tolerance = 1e-8
  )
  local_mocked_bindings(rxSolve = function(...) stop("must not solve"), .package = "nlmixr2est")
  expect_identical(predict_nlmixr_allometric(NULL, d[FALSE, ]), setNames(numeric(), character()))
  doses <- d[d$EVID != 0, ]
  expect_identical(predict_nlmixr_allometric(NULL, doses), setNames(rep(NA_real_, 3), rownames(doses)))
  expect_error(predict_nlmixr_allometric(NULL, data.frame()), "Variables not found")
  doses$AMT[1] <- -1
  expect_error(predict_nlmixr_allometric(NULL, doses), "positive AMT")
})

test_that("prediction rejects incomplete histories and unsupported input before solving", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_prediction_reference()
  local_mocked_bindings(allometric_prediction_components = function(object) saved)
  local_mocked_bindings(rxSolve = function(...) stop("must not solve"), .package = "nlmixr2est")
  d <- allometric_prediction_fixture()
  expect_error(predict_nlmixr_allometric(NULL, d[d$EVID == 0, ]), "explicit dose history")
  expect_error(predict_nlmixr_allometric(NULL, d[-2, ]), "explicit dose history")
  for (column in c("RATE", "DUR", "II", "ADDL", "SS", "MDV", "CENS", "LIMIT", "DVID", "rate")) {
    bad <- d
    bad[[column]] <- 0
    expect_error(predict_nlmixr_allometric(NULL, bad), "Unsupported event modifier")
  }
  for (column in c("ID", "TIME", "WT", "EVID", "AMT")) {
    bad <- d
    bad[[column]][1] <- NA_real_
    expect_error(predict_nlmixr_allometric(NULL, bad), "finite real numeric")
    bad[[column]] <- as.character(d[[column]])
    expect_error(predict_nlmixr_allometric(NULL, bad), "finite real numeric")
  }
  bad <- d
  bad$WT[1] <- 71
  expect_error(predict_nlmixr_allometric(NULL, bad), "constant within each subject")
  bad <- d
  bad$CMT <- 1
  expect_error(predict_nlmixr_allometric(NULL, bad), "CMT")
  bad <- d
  names(bad)[1] <- "TIME"
  expect_error(predict_nlmixr_allometric(NULL, bad), "unique column names")
})

test_that("prediction fails on missing, repeated or nonfinite backend records", {
  skip_if_not_installed("nlmixr2est")
  saved <- allometric_prediction_reference()
  local_mocked_bindings(allometric_prediction_components = function(object) saved)
  d <- allometric_prediction_fixture()
  good <- data.frame(PSR_ROW = which(d$EVID == 0), pred = 1)
  bad <- list(
    NULL, good[-1, ], good[, "pred", drop = FALSE],
    transform(good, PSR_ROW = 1), transform(good, PSR_ROW = NA_real_),
    transform(good, PSR_ROW = PSR_ROW + 0.5), transform(good, pred = Inf),
    transform(good, pred = NA_real_), transform(good, pred = "1")
  )
  result <- good
  local_mocked_bindings(rxSolve = function(...) result, .package = "nlmixr2est")
  for (value in bad) {
    result <- value
    expect_error(predict_nlmixr_allometric(NULL, d), "one finite value per observation row")
  }
})

test_that("prediction rejects foreign fits and reports a missing optional backend", {
  skip_if_not_installed("nlmixr2est")
  for (object in list(NULL, list(), data.frame(), lm(mpg ~ wt, data = mtcars))) {
    expect_error(predict_nlmixr_allometric(object, allometric_prediction_fixture()), "Invalid allometric fit")
  }
  local_mocked_bindings(requireNamespace = function(...) FALSE, .package = "base")
  expect_error(predict_nlmixr_allometric(NULL, NULL), "Package 'nlmixr2est' is required")
})
