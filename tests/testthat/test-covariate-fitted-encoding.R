local_edition(3)

test_that("saved encoding matches fixed additive no-intercept values", {
  old_options <- options(contrasts = c("contr.treatment", "contr.poly"))
  on.exit(options(old_options), add = TRUE)
  training <- data.frame(
    x = c(10, 20, 30),
    group = factor(c("A", "B", "C")),
    sex = factor(c("F", "M", "F")), row.names = c("r3", "r1", "r2")
  )
  recipe <- fit_encoding(training, c("x", "group", "sex"))
  expected <- cbind(
    x = c(10, 20, 30), groupA = c(1, 0, 0),
    groupB = c(0, 1, 0), groupC = c(0, 0, 1), sexM = c(0, 1, 0)
  )
  rownames(expected) <- rownames(training)
  expect_identical(apply_encoding(training, recipe), expected)
  legacy <- prepare_model_matrix(training, c("x", "group", "sex"))
  expect_equal(as.vector(legacy), as.vector(expected))
  expect_identical(dimnames(legacy), dimnames(expected))
  expect_identical(recipe$version, 1L)
  expect_identical(names(recipe$variables), c("x", "group", "sex"))
  expect_identical(recipe$variables$x$coding, NULL)
  expect_identical(recipe$columns, colnames(expected))
  expect_null(attr(expected, "contrasts"))
})

test_that("actual contrast coding survives option changes and serialization", {
  old_options <- options(contrasts = c("contr.treatment", "contr.poly"))
  on.exit(options(old_options), add = TRUE)
  training <- data.frame(
    anchor = factor(c("A", "B", "A")),
    grade = factor(c("L", "M", "H"), levels = c("L", "M", "H")),
    ordered = ordered(c("L", "M", "H"), levels = c("L", "M", "H"))
  )
  contrasts(training$grade) <- stats::contr.sum(3)
  recipe <- fit_encoding(training, names(training))
  expected <- cbind(
    anchorA = c(1, 0, 1), anchorB = c(0, 1, 0),
    grade1 = c(1, 0, -1), grade2 = c(0, 1, -1),
    ordered.L = c(-1, 0, 1) / sqrt(2), ordered.Q = c(1, -2, 1) / sqrt(6)
  )
  rownames(expected) <- rownames(training)
  expect_equal(apply_encoding(training, recipe), expected, tolerance = 1e-14)
  options(contrasts = c("contr.sum", "contr.helmert"))
  expect_equal(apply_encoding(training, recipe), expected, tolerance = 1e-14)
  file <- tempfile(fileext = ".rds")
  on.exit(unlink(file), add = TRUE)
  saveRDS(recipe, file)
  expect_identical(readRDS(file), recipe)
  expect_equal(apply_encoding(training, readRDS(file)), expected, tolerance = 1e-14)
})

test_that("contrast functions are evaluated only when fitting", {
  old_options <- options(contrasts = c("contr.treatment", "contr.poly"))
  on.exit(options(old_options), add = TRUE)
  training <- data.frame(a = factor(c("A", "B")), b = factor(c("C", "D")))
  calls <- 0L
  contrast_function <- function(n, ...) {
    calls <<- calls + 1L
    stats::contr.sum(n, ...)
  }
  function_name <- ".pharmastatsr_encoding_test_contrast"
  assign(function_name, contrast_function, envir = .GlobalEnv)
  on.exit(
    {
      if (exists(function_name, envir = .GlobalEnv, inherits = FALSE)) {
        rm(list = function_name, envir = .GlobalEnv)
      }
    },
    add = TRUE
  )
  attr(training$b, "contrasts") <- function_name
  recipe <- fit_encoding(training, c("a", "b"))
  expect_gt(calls, 0L)
  expected <- cbind(aA = c(1, 0), aB = c(0, 1), b1 = c(1, -1))
  rownames(expected) <- rownames(training)
  rm(list = function_name, envir = .GlobalEnv)
  calls <- 0L
  expect_identical(apply_encoding(training, recipe), expected)
  expect_identical(calls, 0L)
  expect_true(all(vapply(unlist(recipe, recursive = TRUE), function(x) {
    !is.function(x) && !is.environment(x)
  }, logical(1))))
})

test_that("first factor matrix contrasts retain model.matrix coding", {
  old_options <- options(contrasts = c("contr.treatment", "contr.poly"))
  on.exit(options(old_options), add = TRUE)
  training <- data.frame(group = factor(c("A", "B", "C")))
  contrasts(training$group) <- stats::contr.sum(3)
  recipe <- fit_encoding(training, "group")
  expected <- cbind(groupA = c(1, 0, 0), groupB = c(0, 1, 0), groupC = c(0, 0, 1))
  rownames(expected) <- rownames(training)
  expect_identical(apply_encoding(training, recipe), expected)
  legacy <- prepare_model_matrix(training, "group")
  expect_identical(as.vector(legacy), as.vector(expected))
  expect_identical(colnames(legacy), colnames(expected))
})

test_that("new categories use saved levels and reject observed novelty", {
  recipe <- fit_encoding(data.frame(group = c("B", "A", "B")), "group")
  one <- data.frame(group = factor("B", levels = c("unused", "B", "A")), row.names = "held")
  expected <- matrix(c(0, 1), 1, dimnames = list("held", c("groupA", "groupB")))
  expect_identical(apply_encoding(one, recipe), expected)
  expect_identical(apply_encoding(data.frame(group = "B", row.names = "held"), recipe), expected)
  expect_error(apply_encoding(data.frame(group = c("A", "C")), recipe),
    "Unseen levels for covariate 'group': C",
    fixed = TRUE
  )
  expect_error(apply_encoding(data.frame(group = factor("C")), recipe), "Unseen levels")
  blank <- fit_encoding(data.frame(group = c("", "A")), "group")
  expect_identical(unname(apply_encoding(data.frame(group = ""), blank)), matrix(c(1, 0), 1))
})

test_that("logical coding follows model.matrix and selected order is retained", {
  training <- data.frame(x = c(NA_real_, NaN), group = c("A", "B"), flag = c(FALSE, TRUE))
  attr(training$flag, "contrasts") <- stats::contr.sum(2)
  recipe <- fit_encoding(training, c("group", "flag", "x"))
  expected <- cbind(groupA = c(1, 0), groupB = c(0, 1), flagTRUE = c(0, 1), x = c(NA_real_, NaN))
  rownames(expected) <- rownames(training)
  expect_identical(apply_encoding(training, recipe), expected)
  legacy <- prepare_model_matrix(training, c("group", "flag", "x"))
  expect_identical(as.vector(legacy), as.vector(expected))
  expect_identical(dimnames(legacy), dimnames(expected))
  attr(training$flag, "contrasts") <- NULL
  expect_identical(apply_encoding(training[c("x", "flag", "group")], recipe), expected)
})

test_that("missing and empty rows keep the complete schema", {
  training <- data.frame(x = c(1, 2), group = factor(c("A", "B")), flag = c(FALSE, TRUE))
  recipe <- fit_encoding(training, names(training))
  new <- data.frame(
    x = c(NA, NaN), group = c(NA_character_, "B"), flag = c(NA, TRUE),
    row.names = c("missing", "observed")
  )
  expected <- cbind(
    x = c(NA_real_, NaN), groupA = c(NA_real_, 0),
    groupB = c(NA_real_, 1), flagTRUE = c(NA_real_, 1)
  )
  rownames(expected) <- rownames(new)
  expect_identical(apply_encoding(new, recipe), expected)
  empty <- apply_encoding(new[FALSE, , drop = FALSE], recipe)
  expect_identical(dim(empty), c(0L, 4L))
  expect_identical(colnames(empty), recipe$columns)
  expect_identical(
    apply_encoding(new, fit_encoding(training, NULL)),
    matrix(numeric(0), 2, 0, dimnames = list(rownames(new), NULL))
  )
  expect_identical(fit_encoding(training, NULL), fit_encoding(training, character(0)))
  old_options <- options(na.action = "na.fail")
  on.exit(options(old_options), add = TRUE)
  expect_identical(apply_encoding(new, recipe), expected)
})

test_that("declared levels and logical schemas need no observed training rows", {
  training <- data.frame(
    x = numeric(0),
    group = factor(character(0), levels = c("A", "B", "C")), flag = logical(0)
  )
  recipe <- fit_encoding(training, names(training))
  expected <- matrix(c(9, 0, 0, 1, 1), 1,
    dimnames = list("1", c("x", "groupA", "groupB", "groupC", "flagTRUE"))
  )
  expect_identical(apply_encoding(data.frame(x = 9, group = "C", flag = TRUE), recipe), expected)
  logical_recipe <- fit_encoding(data.frame(flag = TRUE), "flag")
  expect_identical(
    unname(apply_encoding(data.frame(flag = c(FALSE, TRUE)), logical_recipe)),
    diag(2)
  )
  expect_error(fit_encoding(data.frame(group = character(0)), "group"), "two factor levels")
  expect_error(fit_encoding(data.frame(group = NA_character_), "group"), "two factor levels")
  expect_error(fit_encoding(data.frame(group = "A"), "group"), "two factor levels")
  expect_error(
    fit_encoding(data.frame(group = factor(c("A", NA), exclude = NULL)), "group"),
    "Explicit NA factor levels"
  )
})

test_that("literal names are preserved without evaluating them", {
  training <- data.frame(x = c(1, 2), y = c("A", "B"), check.names = FALSE)
  for (name in c("dose (mg)", "a+b", "tick`name", ".", "stop('not code')")) {
    names(training) <- c(name, "group")
    recipe <- fit_encoding(training, names(training))
    encoded <- apply_encoding(training, recipe)
    legacy <- prepare_model_matrix(training, names(training))
    expect_identical(as.vector(encoded), as.vector(legacy))
    expect_identical(dimnames(encoded), dimnames(legacy))
  }
  for (name in c("...", "..1", "..123")) {
    names(training) <- c(name, "group")
    expect_error(fit_encoding(training, names(training)), "unsupported model column names")
  }
  collision <- data.frame(a = factor(c("bc", "d")), abc = c(1, 2))
  expect_error(fit_encoding(collision, names(collision)), "ambiguous output column names")
})

test_that("held-out rows cannot change coding of existing rows", {
  training <- data.frame(x = c(1, 2), group = c("A", "B"))
  recipe <- fit_encoding(training, names(training))
  held <- data.frame(x = 100, group = "B", row.names = "held")
  extended <- rbind(held, data.frame(x = -999, group = "A", row.names = "other"))
  expect_identical(apply_encoding(held, recipe), apply_encoding(extended, recipe)[1, , drop = FALSE])
  expect_identical(recipe, fit_encoding(training, names(training)))
  expect_identical(training$x, c(1, 2))
})

test_that("imputation, scaling, and encoding compose from training only", {
  training <- data.frame(x = c(1, NA, 3, 8), group = c("A", "B", "A", "B"))
  imputation <- fit_imputation(training, "x")
  completed <- apply_imputation(training, imputation)
  scaling <- center_scale(completed, "x")
  recipe <- fit_encoding(scaling$data, c("x", "group"))
  held <- data.frame(x = c(NA, 100), group = c("B", "A"))
  processed <- apply_center_scale(apply_imputation(held, imputation), scaling$params)
  expected <- cbind(x = c(0, 96 / sqrt(26 / 3)), groupA = c(0, 1), groupB = c(1, 0))
  rownames(expected) <- rownames(held)
  expect_equal(apply_encoding(processed, recipe), expected)
})

test_that("invalid inputs and changes of variable type fail clearly", {
  training <- data.frame(x = c(1, 2), group = c("A", "B"), flag = c(FALSE, TRUE))
  recipe <- fit_encoding(training, names(training))
  expect_error(fit_encoding(as.matrix(training), "x"), "data.frame")
  expect_error(fit_encoding(training, c("x", "x")), "unique")
  expect_error(fit_encoding(training, "absent"), "not found")
  expect_error(apply_encoding(training["group"], recipe), "not found")
  for (bad in list(c(Inf, 1), c(-Inf, 1), c("1", "2"), factor(c("1", "2")), c(TRUE, FALSE))) {
    changed <- training
    changed$x <- bad
    expect_error(apply_encoding(changed, recipe), "real numeric")
  }
  for (bad in list(c(1, 2), c(TRUE, FALSE))) {
    changed <- training
    changed$group <- bad
    expect_error(apply_encoding(changed, recipe), "remain categorical")
  }
  changed <- training
  changed$flag <- c("FALSE", "TRUE")
  expect_error(apply_encoding(changed, recipe), "remain logical")
  changed <- training
  changed$x <- c(1, Inf)
  expect_error(fit_encoding(changed, names(changed)), "infinite values")
  changed$x <- I(matrix(1:4, 2))
  expect_error(fit_encoding(changed, names(changed)), "vector")
  expect_error(apply_encoding(changed, recipe), "vector")
  names(changed) <- c("x", "x", "flag")
  expect_error(apply_encoding(changed, recipe), "unique")
})

test_that("malformed saved recipes are rejected before application", {
  training <- data.frame(x = c(1, 2), group = c("A", "B"), flag = c(FALSE, TRUE))
  recipe <- fit_encoding(training, names(training))
  bad <- list(
    NULL, data.frame(x = 1), list(version = 1L),
    within(recipe, version <- 2L), within(recipe, columns <- rev(columns))
  )
  changed <- recipe
  changed$variables$group$coding[1, 1] <- Inf
  bad <- c(bad, list(changed))
  changed <- recipe
  changed$variables$group$coding <- changed$variables$group$coding[1, , drop = FALSE]
  bad <- c(bad, list(changed))
  changed <- recipe
  changed$variables$group$kind <- "unknown"
  bad <- c(bad, list(changed))
  changed <- recipe
  rownames(changed$variables$group$coding) <- c("A", "A")
  bad <- c(bad, list(changed))
  changed <- recipe
  rownames(changed$variables$flag$coding) <- c("no", "yes")
  bad <- c(bad, list(changed))
  changed <- recipe
  names(changed$variables) <- c("x", "x", "flag")
  bad <- c(bad, list(changed))
  changed <- recipe
  changed$variables$x$coding <- diag(2)
  bad <- c(bad, list(changed))
  for (value in bad) {
    expect_error(apply_encoding(training, value), "Invalid encoding recipe")
  }
})
