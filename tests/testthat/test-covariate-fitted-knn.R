testthat::local_edition(3)

test_that("saved Gower neighbors agree with hand arithmetic and daisy", {
  train <- data.frame(
    y = c(10, 20), x = c(0, 10), group = factor(c("a", "b")),
    flag = c(FALSE, TRUE), grade = ordered(c("low", "high"),
      levels = c("low", "mid", "high")
    )
  )
  new <- data.frame(y = NA_real_, x = 2, group = "a", flag = FALSE, grade = "mid")
  predictors <- c("x", "group", "flag", "grade")
  model <- fit_knn_imputation(train, "y", predictors, k = 1)
  pairs <- Map(
    function(x, y) c(x, y), model$donor_predictors,
    Map(PharmaStatsR:::prepare_knn_predictor, new[predictors], model$schema)
  )
  distances <- PharmaStatsR:::gower_imputation_distances(pairs, 1:2, 3)
  # Numeric differences .2/.8, nominal and logical 0/1, ordinal .5/.5.
  expect_equal(distances, c(.7, 3.3) / 4)
  expect_equal(apply_knn_imputation(new, model)$y, 10)
  expect_equal(apply_knn_imputation(new, fit_knn_imputation(train, "y", predictors, 2))$y, 15)
  expect_equal(apply_knn_imputation(new, fit_knn_imputation(train, "y", predictors, 20))$y, 15)
  skip_if_not_installed("cluster")
  reference <- rbind(train[predictors], new[predictors])
  reference$flag <- factor(reference$flag) # symmetric, unlike daisy's logical default
  reference$grade <- ordered(reference$grade, levels = c("low", "mid", "high"))
  expect_equal(distances, unname(as.matrix(cluster::daisy(reference, metric = "gower"))[3, 1:2]))
})

test_that("ranges and donors are frozen and recipient batches are independent", {
  train <- data.frame(y = c(10, 20), x = c(0, 10), z = c(0, 10))
  new <- data.frame(y = NA_real_, x = 9, z = 0)
  model <- fit_knn_imputation(train, "y", c("x", "z"), 1)
  # Distances .45 and .55 select the first donor. Expanding only z's scale
  # with a new z=10000 row would reverse that choice.
  expect_equal(apply_knn_imputation(new, model)$y, 10)
  batch <- rbind(new, data.frame(y = 999, x = 9, z = 10000))
  expect_equal(apply_knn_imputation(batch, model)$y, c(10, 999))
  batch$y[2] <- NA_real_
  expect_equal(apply_knn_imputation(batch, model)$y[1], 10)
  expect_equal(apply_knn_imputation(batch[2:1, ], model)$y[2], 10)
  batch$x[2] <- 1e308
  expect_equal(apply_knn_imputation(batch, model)$y[1], 10)
  expect_identical(model, fit_knn_imputation(train, "y", c("x", "z"), 1))
})

test_that("new out-of-range contributions are bounded, without clipping values", {
  train <- data.frame(y = c(10, 20), x = c(0, 10), z = c(0, 10))
  model <- fit_knn_imputation(train, "y", c("x", "z"), 1)
  new <- data.frame(y = NA_real_, x = 15, z = 0)
  # Contributions (1,0) versus (.5,1) select 10. Unbounded differences
  # would tie; reversing the donors tests that the cap really decides.
  reverse <- fit_knn_imputation(train[2:1, ], "y", c("x", "z"), 1)
  expect_equal(apply_knn_imputation(new, model)$y, 10)
  expect_equal(apply_knn_imputation(new, reverse)$y, 10)
  new$x <- 1e308
  expect_equal(apply_knn_imputation(new, model)$y, 10)
  tiny <- fit_knn_imputation(data.frame(y = c(2, 8), x = c(0, 1e-300)), "y", "x", 1)
  expect_equal(apply_knn_imputation(data.frame(y = NA_real_, x = 1e308), tiny)$y, 2)
  extreme <- fit_knn_imputation(data.frame(y = c(2, 8), x = c(-1e308, 1e308)), "y", "x", 1)
  expect_equal(apply_knn_imputation(data.frame(y = NA_real_, x = 9e307), extreme)$y, 8)
  tiny_new <- data.frame(y = NA_real_, x = 9e-301)
  expect_equal(apply_knn_imputation(tiny_new, tiny)$y, 8)
})

test_that("all training rows determine ranges, while only observed targets donate", {
  train <- data.frame(y = c(10, 20, NA), x = c(0, 10, 100), z = c(0, 10, 0))
  model <- fit_knn_imputation(train, "y", c("x", "z"), 1)
  # x has range 100, including the row with missing y: .045 versus .505.
  expect_equal(model$schema$x$span, 100)
  expect_equal(apply_knn_imputation(data.frame(y = NA_real_, x = 9, z = 0), model)$y, 10)
  expect_equal(apply_knn_imputation(train, model)$y, c(10, 20, 10))
})

test_that("missing pairs, constant predictors, weights and ties have fixed rules", {
  train <- data.frame(y = c(10, 20, 30), x = c(NA, 0, 10), z = c(1, NA, 3))
  new <- data.frame(y = c(NA_real_, NA), x = c(1, NA), z = c(NA_real_, NA))
  model <- fit_knn_imputation(train, "y", c("x", "z"), 10)
  expect_warning(result <- apply_knn_imputation(new, model), "1 missing value.*no comparable")
  expect_equal(result$y, c(25, NA_real_))
  weighted <- fit_knn_imputation(train, "y", c("x", "z"), 1, c(x = 1e-300, z = 1e300))
  expect_equal(apply_knn_imputation(new[1, ], weighted)$y, 20)
  train <- data.frame(y = c(10, 20), x = c(0, 10), z = c(0, 10), unused = I(list(1, 2)))
  new <- data.frame(y = NA_real_, x = 9, z = 0)
  for (weights in list(c(x = 3, z = 1), c(x = 3e300, z = 1e300), c(x = 3e-300, z = 1e-300))) {
    model <- fit_knn_imputation(train, "y", c("x", "z", "unused"), 1, c(weights, unused = 0))
    expect_equal(apply_knn_imputation(new, model)$y, 20)
    expect_false("unused" %in% model$predictors)
  }
  constant <- data.frame(y = c(10, 20), x = c(5, 5), absent = c(NA_real_, NA))
  model <- fit_knn_imputation(constant, "y", c("x", "absent"), 1)
  expect_equal(apply_knn_imputation(data.frame(y = NA_real_, x = 999, absent = 4), model)$y, 10)
  model <- fit_knn_imputation(constant[2:1, ], "y", "x", 1)
  expect_equal(apply_knn_imputation(data.frame(y = NA_real_, x = 5), model)$y, 20)
  model <- fit_knn_imputation(constant, "y", "absent", 1)
  expect_warning(result <- apply_knn_imputation(data.frame(y = NA_real_, absent = 2), model), "no comparable")
  expect_true(is.na(result$y))
})

test_that("targets exclude themselves and imputation never cascades", {
  train <- data.frame(a = c(0, 100, NA), b = c(10, NA, 30), x = c(0, 5, 10))
  new <- data.frame(a = NA_real_, b = NA_real_, x = 4)
  forward <- fit_knn_imputation(train, c("a", "b"), c("a", "b", "x"), 1)
  backward <- fit_knn_imputation(train, c("b", "a"), c("a", "b", "x"), 1)
  # Original x alone gives a=100 and b=10. Cascading a=100 into b's
  # distances would instead choose b=30 (.7 versus .6).
  expect_equal(apply_knn_imputation(new, forward), data.frame(a = 100, b = 10, x = 4))
  expect_identical(apply_knn_imputation(new, forward), apply_knn_imputation(new, backward))
  # With x missing neither target has an observed predictor, even after a
  # hypothetical previous imputation. Each target produces one warning.
  new$x <- NA_real_
  expect_warning(expect_warning(result <- apply_knn_imputation(new, forward), "Target 'a'"), "Target 'b'")
  expect_true(all(is.na(result)))
  self <- fit_knn_imputation(train, "a", c("a", "x"), 1, c(a = 1e300, x = 1))
  expect_equal(apply_knn_imputation(data.frame(a = NA_real_, x = 6), self)$a, 100)
})

test_that("categorical contracts preserve training order and symmetric matches", {
  train <- data.frame(
    y = c(10, 20), group = factor(c("a", "b")), flag = c(FALSE, TRUE),
    grade = ordered(c("low", "high"), levels = c("low", "mid", "high"))
  )
  nominal <- fit_knn_imputation(train, "y", "group", 1)
  expect_equal(apply_knn_imputation(data.frame(y = NA_real_, group = "new"), nominal)$y, 10)
  expect_equal(apply_knn_imputation(data.frame(y = NA_real_, group = factor("b", levels = c("b", "a"))), nominal)$y, 20)
  ordered_model <- fit_knn_imputation(train, "y", "grade", 1)
  new <- data.frame(y = NA_real_, grade = ordered("high", levels = c("high", "mid", "low")))
  expect_equal(apply_knn_imputation(new, ordered_model)$y, 20)
  expect_equal(apply_knn_imputation(data.frame(y = NA_real_, grade = "mid"), ordered_model)$y, 10)
  expect_error(apply_knn_imputation(data.frame(y = NA_real_, grade = "new"), ordered_model), "Unseen")
  expect_error(apply_knn_imputation(data.frame(y = NA_real_, grade = 1), ordered_model), "ordered")
  expect_error(apply_knn_imputation(data.frame(y = NA_real_, group = TRUE), nominal), "nominal")
  logical_model <- fit_knn_imputation(train, "y", "flag", 1)
  expect_equal(apply_knn_imputation(data.frame(y = NA_real_, flag = FALSE), logical_model)$y, 10)
  expect_error(apply_knn_imputation(data.frame(y = NA_real_, flag = "FALSE"), logical_model), "logical")
  bad <- train
  bad$group <- factor(c("a", NA), exclude = NULL)
  expect_error(fit_knn_imputation(bad, "y", "group"), "Explicit NA")
  expect_error(apply_knn_imputation(bad, nominal), "Explicit NA")
})

test_that("serialization, literal names, shapes and untouched columns are preserved", {
  train <- data.frame(`target value` = c(1L, 4L), `x + y` = c(0, 10), id = c("a", "b"), check.names = FALSE)
  model <- fit_knn_imputation(train, c(label = "target value"), c(label = "x + y"), 2)
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(model, path)
  expect_identical(readRDS(path), model)
  expect_false("id" %in% names(model$donor_targets))
  expect_false("id" %in% names(model$donor_predictors))
  new <- train[c(2, 1), c(3, 2, 1)]
  new[["target value"]] <- c(NA_integer_, 99L)
  before <- new
  result <- apply_knn_imputation(new, readRDS(path))
  expect_equal(result[["target value"]], c(2.5, 99))
  expect_identical(result[c("id", "x + y")], new[c("id", "x + y")])
  expect_identical(names(result), names(new))
  expect_identical(rownames(result), rownames(new))
  expect_identical(new, before)
  expect_identical(apply_knn_imputation(train, model), train)
  expect_identical(apply_knn_imputation(new[FALSE, ], model), new[FALSE, ])
  new[["target value"]] <- c(NaN, NA_real_)
  expect_equal(apply_knn_imputation(new, model)[["target value"]], c(2.5, 2.5))
})

test_that("invalid fitting inputs and altered recipes fail clearly", {
  train <- data.frame(y = c(1, 3), x = c(0, 10))
  for (bad in list(NULL, character(), c("y", "y"), NA_character_, "", 1, matrix("y"))) {
    expect_error(fit_knn_imputation(train, bad, "x"), "vars")
    expect_error(fit_knn_imputation(train, "y", bad), "predictors")
  }
  for (bad in list(0, -1, 1.5, NA_real_, Inf, TRUE, "2", c(1, 2), 2^31)) {
    expect_error(fit_knn_imputation(train, "y", "x", bad), "k")
  }
  expect_error(fit_knn_imputation(train, "y", "absent"), "predictors")
  expect_error(fit_knn_imputation(train, "y", "y"), "another positive-weight")
  expect_error(fit_knn_imputation(train, "y", "x", weights = c(x = 0)), "positive-weight")
  expect_error(fit_knn_imputation(train, "y", "x", weights = c(x = -1)), "weights")
  expect_error(fit_knn_imputation(train, "y", "x", weights = c(z = 1)), "unselected")
  bad <- train
  bad$y <- NA_real_
  expect_error(fit_knn_imputation(bad, "y", "x"), "observed training")
  bad <- train
  bad$x[1] <- Inf
  expect_error(fit_knn_imputation(bad, "y", "x"), "infinite")
  model <- fit_knn_imputation(train, "y", "x")
  expect_error(apply_knn_imputation(bad, model), "infinite")
  bad$x <- c("0", "10")
  expect_error(apply_knn_imputation(bad, model), "remain numeric")
  expect_error(apply_knn_imputation(train["y"], model), "not found")
  for (field in names(model)) {
    broken <- model
    broken[[field]] <- NULL
    expect_error(apply_knn_imputation(train, broken), "Invalid saved")
  }
  broken <- model
  broken$version <- 2L
  expect_error(apply_knn_imputation(train, broken), "Invalid saved")
  broken <- model
  broken$donor_predictors$x[1] <- Inf
  expect_error(apply_knn_imputation(train, broken), "Invalid saved")
  broken <- model
  broken$schema$x$span <- -1
  expect_error(apply_knn_imputation(train, broken), "Invalid saved")
  broken <- model
  broken$weights[1] <- NA_real_
  expect_error(apply_knn_imputation(train, broken), "Invalid saved")
})
