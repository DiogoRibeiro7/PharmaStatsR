local_edition(3)

make_model_input_data <- function() {
  set.seed(42)
  d <- data.frame(
    SubjectID = rep(seq_len(20), each = 4),
    Time = rep(0:3, 20), x = rnorm(80), group = rep(c("a", "b"), 40)
  )
  d$DV <- 2 * d$x + 0.3 * d$Time +
    rep(rnorm(20, sd = 2), each = 4) + rnorm(80)
  d
}

test_that("model matrices preserve rows and missing values under NA options", {
  d <- data.frame(
    x = c(1, NA_real_, 3, NaN),
    group = factor(c("a", "b", NA, "a"), levels = c("a", "b", "unused")),
    unrelated = NA_real_, row.names = c("a", "b", "c", "d")
  )
  original <- d
  check_option <- function(action) {
    previous <- options(na.action = action)
    on.exit(options(previous))
    design <- prepare_model_matrix(d, c("x", "group"))
    expect_identical(dim(design), c(4L, 4L))
    expect_identical(rownames(design), rownames(d))
    expect_identical(unname(design[, "x"]), d$x)
    expect_equal(unname(design[2, -1]), c(0, 1, 0))
    expect_true(all(is.na(design[3, -1])))
    expect_equal(unname(design[c(1, 2, 4), "groupunused"]), rep(0, 3))
  }
  for (action in c("na.omit", "na.exclude", "na.fail")) {
    check_option(action)
  }
  expect_identical(d, original)
})

test_that("empty selections and empty numeric data have defined dimensions", {
  d <- data.frame(x = 1:3, row.names = c("first", "second", "third"))
  for (selection in list(character(0), NULL)) {
    design <- prepare_model_matrix(d, selection)
    expect_identical(dim(design), c(3L, 0L))
    expect_identical(rownames(design), rownames(d))
    expect_type(design, "double")
  }
  expect_identical(
    dim(prepare_model_matrix(data.frame(x = numeric(0)), "x")), c(0L, 1L)
  )
  expect_equal(
    prepare_model_matrix(data.frame(x = rep(1, 3)), "x")[, 1],
    c(`1` = 1, `2` = 1, `3` = 1)
  )
})

test_that("matrix column names are literal except R evaluation symbols", {
  for (name in c("body mass", "x+y", "`x`", ".", "stop('not code')")) {
    d <- data.frame(x = 1:3)
    names(d) <- name
    expect_equal(unname(prepare_model_matrix(d, name)[, 1]), 1:3)
  }
  for (name in c("...", "..1", "..12")) {
    d <- data.frame(x = 1:3)
    names(d) <- name
    expect_error(prepare_model_matrix(d, name), "Rename unsupported")
  }
})

test_that("model helpers reject ambiguous selections and unsupported columns", {
  d <- make_model_input_data()
  methods <- list(
    prepare_model_matrix,
    function(data, covariates) {
      fit_covariate_model(data, "DV", "SubjectID", covariates)
    }
  )
  for (method in methods) {
    for (selection in list(1, c("x", "x"), c("x", NA), matrix("x"))) {
      expect_error(method(d, selection), "unique column names")
    }
    expect_error(method(d, "missing"), "Covariates not found")
    duplicate <- d
    names(duplicate)[2] <- "x"
    expect_error(method(duplicate, "x"), "unique column names")
    for (column in list(rep(1 + 1i, 80), matrix(1:160, 80), as.list(1:80))) {
      invalid <- d
      invalid$x <- column
      expect_error(method(invalid, "x"), "numeric, logical, character")
    }
  }
  expect_error(
    prepare_model_matrix(data.frame(x = c(1, Inf)), "x"), "infinite values"
  )
  expect_error(
    prepare_model_matrix(data.frame(x = c("a", NA)), "x"), "two factor levels"
  )
})

test_that("mixed models match nlme and preserve prediction and NA alignment", {
  d <- make_model_input_data()
  d$DV[1] <- NA
  d$SubjectID[2] <- NA
  d$x[3] <- NA
  d$DV[3] <- Inf # This row is excluded because x is missing.
  d$group[4] <- NA
  d$unrelated <- NA_real_
  original <- d
  model <- fit_covariate_model(d, "DV", "SubjectID", c("x", "Time", "group"))
  reference <- nlme::lme(
    DV ~ x + Time + group,
    random = ~ 1 | SubjectID, data = d,
    na.action = stats::na.exclude
  )
  expect_s3_class(model, "lme")
  expect_equal(nlme::fixef(model), nlme::fixef(reference))
  expect_equal(
    as.numeric(stats::logLik(model)), as.numeric(stats::logLik(reference))
  )
  expect_equal(stats::residuals(model), stats::residuals(reference))
  expect_length(stats::residuals(model), nrow(d))
  expect_true(all(is.na(stats::residuals(model)[1:4])))
  new_data <- original[5:12, ]
  expect_equal(
    stats::predict(model, new_data), stats::predict(reference, new_data)
  )
  expect_equal(
    stats::predict(model, new_data, level = 0),
    stats::predict(reference, new_data, level = 0)
  )
  expect_identical(model$data, original)
  expect_identical(d, original)
})

test_that("intercept-only mixed models retain their supported interface", {
  d <- make_model_input_data()
  for (selection in list(character(0), NULL)) {
    model <- fit_covariate_model(d, "DV", "SubjectID", selection)
    expect_identical(names(nlme::fixef(model)), "(Intercept)")
  }
})

test_that("mixed-model column roles and names are validated before formulas", {
  d <- make_model_input_data()
  for (argument in list(NULL, NA_character_, 1, c("DV", "x"), matrix("DV"))) {
    expect_error(
      fit_covariate_model(d, argument, "SubjectID", "x"), "each name one column"
    )
    expect_error(
      fit_covariate_model(d, "DV", argument, "x"), "each name one column"
    )
  }
  expect_error(fit_covariate_model(d, "DV", "DV", "x"), "must be distinct")
  for (selection in list(c("DV", "x"), c("SubjectID", "x"))) {
    expect_error(
      fit_covariate_model(d, "DV", "SubjectID", selection), "must be distinct"
    )
  }
  for (role in c("DV", "SubjectID", "x")) {
    for (name in c("body mass", "x+y", "`x`", ".", "...", "..1")) {
      renamed <- d
      names(renamed)[names(renamed) == role] <- name
      roles <- c("DV", "SubjectID", "x")
      roles[roles == role] <- name
      expect_error(
        fit_covariate_model(renamed, roles[1], roles[2], roles[3]),
        "Rename unsupported model column names"
      )
    }
  }
})

test_that("mixed models reject invalid responses and grouping data", {
  d <- make_model_input_data()
  for (column in list(
    rep("a", 80), factor(rep(c("a", "b"), 40)),
    rep(1 + 1i, 80), matrix(1:160, 80)
  )) {
    invalid <- d
    invalid$DV <- column
    expect_error(
      fit_covariate_model(invalid, "DV", "SubjectID", "x"), "real numeric"
    )
  }
  invalid <- d
  invalid$SubjectID <- matrix(1:160, 80)
  expect_error(
    fit_covariate_model(invalid, "DV", "SubjectID", "x"), "numeric, logical"
  )
  invalid$SubjectID <- 1
  expect_error(
    fit_covariate_model(invalid, "DV", "SubjectID", "x"), "two subjects"
  )
  invalid$SubjectID <- seq_len(nrow(invalid))
  expect_error(
    fit_covariate_model(invalid, "DV", "SubjectID", "x"),
    "repeated observations"
  )
  for (v in c("DV", "SubjectID", "x")) {
    invalid <- d
    invalid[[v]][1] <- Inf
    expect_error(
      fit_covariate_model(invalid, "DV", "SubjectID", "x"), "must be finite"
    )
  }
})

test_that("mixed models reject unusable cohorts and fixed-effects designs", {
  d <- make_model_input_data()
  invalid <- d
  invalid$DV <- 1
  expect_error(
    fit_covariate_model(invalid, "DV", "SubjectID", "x"), "response.*must vary"
  )
  invalid$DV <- NA_real_
  expect_error(
    fit_covariate_model(invalid, "DV", "SubjectID", "x"), "three complete-case"
  )
  for (column in list(rep(1, nrow(d)), 2 * d$x)) {
    invalid <- d
    invalid$redundant <- column
    expect_error(
      fit_covariate_model(invalid, "DV", "SubjectID", c("x", "redundant")),
      "rank deficient"
    )
  }
  invalid <- d
  invalid$group <- factor(c("a", rep("b", 79)), levels = c("a", "b", "unused"))
  invalid$x[1] <- NA
  expect_error(
    fit_covariate_model(invalid, "DV", "SubjectID", c("x", "group")),
    "two factor levels"
  )
  saturated <- data.frame(
    SubjectID = c(1, 1, 2), DV = c(1, 2, 4), x = c(0, 1, 0), z = c(0, 0, 1)
  )
  expect_error(
    fit_covariate_model(saturated, "DV", "SubjectID", c("x", "z")),
    "More complete-case rows"
  )
})
