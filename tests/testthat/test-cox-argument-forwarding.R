# Same six-subject interval design as docs/cox-timevarying.md.
# Keep this fixture self-contained; test files must not depend on load order.
cox_forwarding_data <- function() {
  data.frame(
    id = c("A", "B", "B", "C", "D", "E", "E", "F"),
    start = c(0, 0, 2, 0, 0, 0, 4, 2),
    stop = c(2, 2, 4, 3, 5, 4, 6, 7),
    event = c(1, 0, 1, 1, 1, 0, 1, 0),
    exposure = c(1, 0, 1, 0, 0, 1, 0, 1),
    selected = TRUE,
    row.names = c("A1", "B1", "B2", "C1", "D1", "E1", "E2", "F1"),
    stringsAsFactors = FALSE
  )
}

test_that("counting Cox forwards caller weight expressions without dot promises", {
  data <- cox_forwarding_data()
  for (multiplier in c(1, 2)) {
    case_weights <- rep(multiplier, nrow(data))
    actual <- pharma_cox_timevarying(
      survival::Surv(start, stop, event) ~ exposure, data,
      weights = case_weights, ties = "breslow", robust = FALSE, model = TRUE
    )
    # Constant replication weights preserve beta and scale model information.
    expect_equal(unname(stats::coef(actual)), -0.5181598058136135,
      tolerance = 1e-7
    )
    expect_equal(unname(stats::vcov(actual)),
      matrix(0.9145168032707050 / multiplier, nrow = 1),
      tolerance = 1e-7
    )
    expect_equal(unname(stats::model.weights(actual$model)), case_weights)
    expect_identical(rownames(actual$model), rownames(data))
    expect_equal(actual$n, 8)
  }
})

test_that("counting Cox resolves weights and IDs in selected data first", {
  retained <- cox_forwarding_data()
  retained$case_weight <- 1
  extra <- retained["A1", , drop = FALSE]
  extra$id <- "excluded"
  extra$selected <- FALSE
  extra$exposure <- NA_real_
  extra$case_weight <- NA_real_
  rownames(extra) <- "excluded"
  data <- rbind(retained, extra)
  # Incorrect caller bindings must not shadow columns in the selected data.
  case_weight <- -1
  id <- "not-a-subject"
  actual <- pharma_cox_timevarying(
    survival::Surv(start, stop, event) ~ exposure, data,
    subset = selected, weights = case_weight, id = id,
    ties = "breslow", robust = FALSE, model = TRUE
  )
  expect_identical(rownames(actual$model), rownames(retained))
  expect_equal(unname(stats::model.weights(actual$model)), rep(1, 8))
  expect_equal(as.character(stats::model.extract(actual$model, "id")), retained$id)
  expect_equal(unname(stats::coef(actual)), -0.5181598058136135,
    tolerance = 1e-7
  )
  expect_equal(actual$n, 8)
  expect_equal(actual$nevent, 5)
})

test_that("counting Cox preserves a supplied formula's weight environment", {
  data <- cox_forwarding_data()
  make_formula <- function() {
    formula_weights <- rep(1, 8)
    survival::Surv(start, stop, event) ~ exposure
  }
  formula <- make_formula()
  actual <- pharma_cox_timevarying(
    formula, data, weights = formula_weights,
    ties = "breslow", robust = FALSE, model = TRUE
  )
  expect_equal(unname(stats::model.weights(actual$model)), rep(1, 8))
  expect_equal(unname(stats::coef(actual)), -0.5181598058136135,
    tolerance = 1e-7
  )
})

test_that("counting Cox does not re-evaluate data or the original subset", {
  data <- cox_forwarding_data()
  data_reads <- subset_reads <- 0L
  get_data <- function() {
    data_reads <<- data_reads + 1L
    data
  }
  select_rows <- function(selected) {
    subset_reads <<- subset_reads + 1L
    selected
  }
  actual <- pharma_cox_timevarying(
    survival::Surv(start, stop, event) ~ exposure, get_data(),
    subset = select_rows(selected), weights = rep(1, 8),
    ties = "breslow", robust = FALSE, model = TRUE
  )
  expect_identical(data_reads, 1L)
  expect_identical(subset_reads, 1L)
  expect_identical(rownames(actual$model), rownames(data))
})
