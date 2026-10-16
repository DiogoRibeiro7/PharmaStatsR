testthat::local_edition(3)

balanced_lme_names_data <- function() {
  time <- rep(c(-1, 0, 1), 4)
  data.frame(
    subject = rep(1:4, each = 3), time = time,
    response = 2 + 1.5 * time + rep(c(-3, -1, 1, 3), each = 3) + rep(c(1, -2, 1), 4)
  )
}

literal_lme_names_data <- function() {
  set.seed(42)
  data <- data.frame(
    id = rep(1:20, each = 4), time = rep(0:3, 20),
    x = rnorm(80), group = factor(rep(c("A", "B"), 40))
  )
  data$y <- 2 * data$x + 0.3 * data$time + as.numeric(data$group == "B") +
    rep(rnorm(20, sd = 2), each = 4) + rnorm(80)
  data
}

test_that("repaired mixed models match balanced REML and BLUP references", {
  data <- balanced_lme_names_data()
  names(data) <- c("subject id", "visit time", "response value")
  original <- data
  model <- fit_covariate_model(data, "response value", "subject id", "visit time", repair_names = TRUE)
  # Within-subject residual SS=24, residual df=4*(3-1)-1=7.
  # Between-subject mean-square=3*20/(4-1)=20, giving tau^2=116/21.
  # BLUP shrinkage is tau^2/(tau^2+sigma^2/3)=29/35.
  expect_identical(class(model), "lme")
  expect_equal(unname(nlme::fixef(model)), c(2, 1.5), tolerance = 1e-7)
  expect_equal(model$sigma^2, 24 / 7, tolerance = 1e-5)
  expect_equal(as.numeric(nlme::VarCorr(model)[1, "Variance"]), 116 / 21, tolerance = 1e-5)
  expect_equal(as.vector(nlme::ranef(model)[, 1]), c(-3, -1, 1, 3) * 29 / 35, tolerance = 1e-5)
  population <- 2 + 1.5 * data[["visit time"]]
  conditional <- population + rep(c(-3, -1, 1, 3), each = 3) * 29 / 35
  expect_equal(unname(predict_covariate_model(model, data)), population, tolerance = 1e-7)
  expect_equal(unname(predict_covariate_model(model, data, level = 1)), conditional, tolerance = 1e-5)
  expect_identical(names(predict_covariate_model(model, data)), rownames(data))
  expect_identical(model$column_map$original, c("response value", "subject id", "visit time"))
  expect_identical(model$column_map$model, c("response.value", "subject.id", "visit.time"))
  expect_identical(data, original)
})

test_that("every model role supports literal names without evaluating expressions", {
  data <- balanced_lme_names_data()
  for (role in c("response", "subject", "time")) {
    for (name in c("body mass", "x+y", "`x`", ".", "...", "..1", "if", "stop('not code')")) {
      renamed <- data
      names(renamed)[names(renamed) == role] <- name
      roles <- c("response", "subject", "time")
      roles[roles == role] <- name
      model <- fit_covariate_model(renamed, roles[1], roles[2], roles[3], repair_names = TRUE)
      expect_equal(unname(nlme::fixef(model)), c(2, 1.5), tolerance = 1e-7)
      expect_equal(unname(predict_covariate_model(model, renamed)), 2 + 1.5 * data$time, tolerance = 1e-7)
      expect_identical(model$column_map$original, roles)
    }
  }
})

test_that("collisions preserve separate raw columns and ignore prediction distractors", {
  data <- literal_lme_names_data()
  reference <- fit_covariate_model(data, "y", "id", c("x", "time", "group"))
  names(data)[match(c("x", "time", "group"), names(data))] <- c("body mass", "body.mass", "arm + group")
  data$body.mass.1 <- seq_len(nrow(data)) # an unselected name is also reserved
  original <- data
  model <- fit_covariate_model(data, "y", "id", c("body mass", "body.mass", "arm + group"), repair_names = TRUE)
  expect_identical(model$column_map$model, c("y", "id", "body.mass", "body.mass.2", "arm...group"))
  expect_false(anyDuplicated(names(model$data)) > 0)
  for (i in seq_len(nrow(model$column_map))) {
    expect_identical(model$data[[model$column_map$model[i]]], data[[model$column_map$original[i]]])
  }
  expect_equal(unname(nlme::fixef(model)), unname(nlme::fixef(reference)))
  expect_equal(as.numeric(stats::logLik(model)), as.numeric(stats::logLik(reference)))
  new <- data[5:12, c("arm + group", "body.mass", "body mass", "id")]
  new$body.mass.2 <- 1e12 # must not override the raw body.mass values
  expect_equal(unname(predict_covariate_model(model, new)), as.numeric(stats::predict(reference, reference$data[5:12, ], level = 0)))
  expect_equal(unname(predict_covariate_model(model, new, 1)), as.numeric(stats::predict(model, model$data[5:12, ], level = 1)))
  expect_identical(data, original)
})

test_that("missing-row alignment and factor coding match a direct nlme model", {
  data <- literal_lme_names_data()
  data$y[1] <- NA_real_
  data$id[2] <- NA_integer_
  data$x[3] <- NA_real_
  data$y[3] <- Inf
  data$group[4] <- NA
  reference <- nlme::lme(y ~ x + time + group, random = ~ 1 | id, data = data, na.action = stats::na.exclude)
  names(data) <- c("subject id", "visit time", "body mass", "arm group", "response value")
  model <- fit_covariate_model(data, "response value", "subject id", c("body mass", "visit time", "arm group"), repair_names = TRUE)
  expect_equal(unname(nlme::fixef(model)), unname(nlme::fixef(reference)))
  expect_equal(as.numeric(stats::logLik(model)), as.numeric(stats::logLik(reference)))
  expect_equal(as.numeric(stats::residuals(model)), as.numeric(stats::residuals(reference)))
  expect_length(stats::residuals(model), nrow(data))
  expect_true(all(is.na(stats::residuals(model)[1:4])))
  new <- data[5:12, ]
  predicted <- predict_covariate_model(model, new)
  new[["arm group"]] <- factor(new[["arm group"]], levels = c("B", "A", "unused"))
  old_options <- options(contrasts = c("contr.sum", "contr.poly"))
  on.exit(options(old_options), add = TRUE)
  expect_identical(predict_covariate_model(model, new), predicted)
  expect_equal(unname(predicted), as.numeric(stats::predict(reference, reference$data[5:12, ], level = 0)))
})

test_that("population and subject predictions preserve rows and unknown-subject semantics", {
  data <- balanced_lme_names_data()
  model <- fit_covariate_model(data, "response", "subject", "time")
  new <- data.frame(time = c(0, -1, 1), subject = c(4, 999, 1), row.names = c("third", "first", "second"))
  expect_identical(predict_covariate_model(model, new), predict_covariate_model(model, new["time"]))
  expect_equal(unname(predict_covariate_model(model, new)), c(2, 0.5, 3.5), tolerance = 1e-7)
  values <- predict_covariate_model(model, new, 1)
  expect_equal(unname(values), c(2 + 3 * 29 / 35, NA_real_, 3.5 - 3 * 29 / 35), tolerance = 1e-5)
  expect_identical(names(values), rownames(new))
  expect_identical(predict_covariate_model(model, new[1, , drop = FALSE], 1), values[1])
  expect_identical(predict_covariate_model(model, new[FALSE, ], 1), stats::setNames(numeric(0), character(0)))
  expect_error(predict_covariate_model(model, new["time"], 1), "not found")
  new$subject[1] <- NA_integer_
  expect_error(predict_covariate_model(model, new, 1), "subject.*observed and finite")
  expect_true(all(is.finite(predict_covariate_model(model, new))))
  intercept <- fit_covariate_model(data, "response", "subject", character())
  expect_equal(unname(predict_covariate_model(intercept, data.frame(unused = 1:3))), rep(2, 3), tolerance = 1e-7)
})

test_that("saved repaired and older unmapped results predict without refitting", {
  data <- balanced_lme_names_data()
  ordinary <- fit_covariate_model(data, "response", "subject", "time")
  expect_false("column_map" %in% names(ordinary))
  expect_identical(ordinary$data, data)
  repaired <- fit_covariate_model(data, "response", "subject", "time", repair_names = TRUE)
  expect_equal(nlme::fixef(repaired), nlme::fixef(ordinary))
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  local_mocked_bindings(lme = function(...) stop("Unexpected refit"), .package = "nlme")
  for (model in list(ordinary, repaired)) {
    original <- model
    saveRDS(model, path)
    expect_identical(predict_covariate_model(readRDS(path), data, 1), predict_covariate_model(model, data, 1))
    expect_identical(model, original)
  }
})

test_that("prediction rejects incomplete, incompatible, or corrupted inputs", {
  data <- literal_lme_names_data()
  model <- fit_covariate_model(data, "y", "id", c("x", "time", "group"), repair_names = TRUE)
  for (value in list(NA, 1, "yes", logical(), c(TRUE, FALSE), matrix(TRUE))) {
    expect_error(fit_covariate_model(data, "y", "id", "x", repair_names = value), "repair_names.*TRUE or FALSE")
  }
  for (level in list(NA_real_, Inf, -1, 2, c(0, 1), matrix(0), "0", FALSE)) {
    expect_error(predict_covariate_model(model, data, level), "level.*0.*1")
  }
  for (value in list(NA_real_, NaN, Inf, -Inf)) {
    changed <- data[1:2, ]
    changed$x[1] <- value
    expect_error(predict_covariate_model(model, changed), "x.*observed and finite")
  }
  changed <- data[1:2, ]
  changed$x <- c("1", "2")
  expect_error(predict_covariate_model(model, changed), "x.*incompatible type")
  changed$group <- "new"
  changed$x <- 1:2
  expect_error(predict_covariate_model(model, changed), "new level|not allowed")
  names(changed)[2] <- "x"
  expect_error(predict_covariate_model(model, changed), "unique column names")
  expect_error(predict_covariate_model(NULL, data), "Invalid covariate model")
  for (field in c("original", "model", "role")) {
    changed <- model
    changed$column_map[[field]][1] <- changed$column_map[[field]][2]
    expect_error(predict_covariate_model(changed, data), "Invalid covariate model")
  }
  changed <- model
  changed$data <- NULL
  expect_error(predict_covariate_model(changed, data), "Invalid covariate model")
  balanced <- balanced_lme_names_data()
  simple <- fit_covariate_model(balanced, "response", "subject", "time")
  expect_error(predict_covariate_model(simple, data.frame(time = .Machine$double.xmax)), "predictions must be finite")
  data$group <- data$group == "B"
  logical_model <- fit_covariate_model(data, "y", "id", c("x", "time", "group"))
  expect_equal(unname(predict_covariate_model(logical_model, data)), as.numeric(stats::predict(logical_model, data, level = 0)))
  data$group <- as.integer(data$group)
  expect_error(predict_covariate_model(logical_model, data), "group.*incompatible type")
})
