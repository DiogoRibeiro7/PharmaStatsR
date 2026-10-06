# Independent transition-risk-set arithmetic: docs/multistate.md.
multistate_reference_data <- function(drop_transition3_events = FALSE) {
  exit <- c(2, 3, 4, 4, 1, 5)
  trans1 <- data.frame(
    id = 1:6, Tstart = 0, Tstop = exit,
    status = c(1, 0, 0, 1, 1, 0), trans = 1L
  )
  trans2 <- data.frame(
    id = 1:6, Tstart = 0, Tstop = exit,
    status = c(0, 1, 0, 0, 0, 1), trans = 2L
  )
  trans3 <- data.frame(
    id = c(1, 4, 5),
    Tstart = c(2, 4, 1),
    Tstop = c(5, 6, 4),
    status = c(1, 0, 1),
    trans = 3L
  )
  if (drop_transition3_events) {
    trans3$status[] <- 0
  }
  rbind(trans1, trans2, trans3)
}

multistate_reference_fit <- function(data) {
  survival::coxph(
    survival::Surv(Tstart, Tstop, status) ~ strata(trans),
    data = data, method = "breslow"
  )
}

multistate_reference_hazards <- function(drop_transition3_events = FALSE) {
  increments <- data.frame(
    trans = c(1L, 1L, 1L, 2L, 2L, 3L, 3L),
    time = c(1, 2, 4, 3, 5, 4, 5),
    risk = c(6, 5, 3, 4, 1, 2, 2),
    events = c(1, 1, 1, 1, 1, 1, 1)
  )
  if (drop_transition3_events) {
    increments$events[increments$trans == 3L] <- 0
  }
  times <- 1:6
  expected <- do.call(rbind, lapply(1:3, function(k) {
    tab <- increments[increments$trans == k, ]
    data.frame(
      time = times,
      Haz = vapply(times, function(t) {
        sum(tab$events[tab$time <= t] / tab$risk[tab$time <= t])
      }, numeric(1)),
      trans = k
    )
  }))
  rownames(expected) <- NULL
  expected
}

test_that("multistate hazards match independent transition risk sets", {
  skip_if_not_installed("mstate")

  data <- multistate_reference_data()
  trans <- mstate::trans.illdeath()

  # Explicit event-time risk sets use start < t <= stop.
  risk_targets <- data.frame(
    trans = c(1L, 1L, 1L, 2L, 2L, 3L, 3L),
    time = c(1, 2, 4, 3, 5, 4, 5),
    risk = c(6L, 5L, 3L, 4L, 1L, 2L, 2L),
    events = rep(1L, 7)
  )
  reconstructed <- do.call(rbind, lapply(seq_len(nrow(risk_targets)), function(i) {
    k <- risk_targets$trans[i]
    t <- risk_targets$time[i]
    rows <- data[data$trans == k, ]
    data.frame(
      trans = k,
      time = t,
      risk = sum(rows$Tstart < t & rows$Tstop >= t),
      events = sum(rows$status == 1 & rows$Tstop == t)
    )
  }))
  rownames(reconstructed) <- NULL
  expect_identical(reconstructed, risk_targets)

  actual <- pharma_multistate_model(
    multistate_reference_fit(data), trans, variance = FALSE
  )
  expected <- multistate_reference_hazards()

  expect_s3_class(actual, "msfit")
  expect_identical(names(actual), c("Haz", "trans"))
  expect_equal(actual$trans, trans, tolerance = 0)
  expect_equal(actual$Haz, expected, tolerance = 1e-12)

  # Fixed cumulative targets: 7/10, 5/4 and 1.
  final <- actual$Haz[actual$Haz$time == 6, ]
  expect_equal(final$Haz, c(7 / 10, 5 / 4, 1), tolerance = 1e-12)
})

test_that("entry exactly at an event time is excluded from that risk set", {
  skip_if_not_installed("mstate")

  data <- multistate_reference_data()
  transition3 <- data[data$trans == 3L, ]

  # Subject 4 enters state 2 at t=4, so start == event time and is not at risk
  # for the subject-5 event at t=4. Subjects 1 and 5 are the two at risk.
  expect_identical(
    transition3$id[transition3$Tstart < 4 & transition3$Tstop >= 4],
    c(1, 5)
  )
  expect_equal(
    pharma_multistate_model(
      multistate_reference_fit(data), mstate::trans.illdeath(),
      variance = FALSE
    )$Haz$Haz[
      pharma_multistate_model(
        multistate_reference_fit(data), mstate::trans.illdeath(),
        variance = FALSE
      )$Haz$trans == 3 &
        pharma_multistate_model(
          multistate_reference_fit(data), mstate::trans.illdeath(),
          variance = FALSE
        )$Haz$time == 4
    ],
    1 / 2,
    tolerance = 1e-12
  )
})

test_that("a transition with no events has zero cumulative hazard", {
  skip_if_not_installed("mstate")

  data <- multistate_reference_data(drop_transition3_events = TRUE)
  actual <- pharma_multistate_model(
    multistate_reference_fit(data), mstate::trans.illdeath(),
    variance = FALSE
  )
  expected <- multistate_reference_hazards(drop_transition3_events = TRUE)
  # msfit() omits strata with no observed events rather than materializing a
  # zero-valued cumulative-hazard curve for that transition.
  expected <- expected[expected$trans != 3L, , drop = FALSE]
  rownames(expected) <- NULL

  expect_equal(actual$Haz, expected, tolerance = 1e-12)
  expect_false(any(actual$Haz$trans == 3L))
})

test_that("multistate hazard targets are invariant to input order", {
  skip_if_not_installed("mstate")

  data <- multistate_reference_data()
  order <- c(15, 2, 11, 1, 8, 13, 5, 17, 4, 9, 7, 14, 3, 12, 6, 10, 16)
  shuffled <- data[order, ]

  actual <- pharma_multistate_model(
    multistate_reference_fit(shuffled), mstate::trans.illdeath(),
    variance = FALSE
  )
  expect_equal(actual$Haz, multistate_reference_hazards(), tolerance = 1e-12)
})

test_that("common time translations shift times but not cumulative hazards", {
  skip_if_not_installed("mstate")

  data <- multistate_reference_data()
  translated <- data
  translated$Tstart <- translated$Tstart + 10
  translated$Tstop <- translated$Tstop + 10

  actual <- pharma_multistate_model(
    multistate_reference_fit(translated), mstate::trans.illdeath(),
    variance = FALSE
  )
  expected <- multistate_reference_hazards()
  expected$time <- expected$time + 10

  expect_equal(actual$Haz, expected, tolerance = 1e-12)
})
