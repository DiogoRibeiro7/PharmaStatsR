local_edition(3)

test_that("mixed designs match fixed indicator and polynomial references", {
  previous <- options(contrasts = c("contr.treatment", "contr.poly"), na.action = "na.pass")
  on.exit(options(previous))
  d <- data.frame(
    x = c(1, 2, 3, 4, NA_real_, NaN),
    group = factor(c("A", "B", "C", "A", NA, "B"), levels = c("A", "B", "C")),
    stage = ordered(c("low", "mid", "high", "high", "low", NA), levels = c("low", "mid", "high")),
    flag = c(FALSE, TRUE, FALSE, NA, TRUE, FALSE), ignored = Inf,
    row.names = paste0("row-", 6:1)
  )
  original <- d
  expected <- cbind(
    x = d$x, groupA = c(1, 0, 0, 1, NA, 0), groupB = c(0, 1, 0, 0, NA, 1),
    groupC = c(0, 0, 1, 0, NA, 0),
    stage.L = c(-1, 0, 1, 1, -1, NA) / sqrt(2),
    stage.Q = c(1, -2, 1, 1, 1, NA) / sqrt(6),
    flagTRUE = c(0, 1, 0, NA, 1, 0)
  )
  rownames(expected) <- rownames(d)
  for (action in c("na.omit", "na.exclude", "na.fail")) {
    options(na.action = action)
    design <- prepare_model_matrix(d, c("x", "group", "stage", "flag"))
    expect_equal(as.vector(design), as.vector(expected), tolerance = 1e-14)
    expect_identical(dimnames(design), dimnames(expected))
    expect_identical(attr(design, "assign"), c(1L, 2L, 2L, 2L, 3L, 3L, 4L))
    expect_identical(attr(design, "contrasts"), list(group = "contr.treatment", stage = "contr.poly", flag = "contr.treatment"))
    # Coefficients cancel the normalizers: stage contributes L numerator + Q numerator.
    beta <- c(2, 10, 20, 30, sqrt(2), sqrt(6), 5)
    expect_equal(unname(drop(design %*% beta)), c(12, 27, 38, NA, NA, NA), tolerance = 1e-13)
    expect_identical(unname(design[, "x"]), d$x)
  }
  expect_identical(d, original)
  rows <- c(3, 1, 6, 2, 5, 4)
  shuffled <- prepare_model_matrix(d[rows, ], c("x", "group", "stage", "flag"))
  expect_equal(as.vector(shuffled), as.vector(expected[rows, ]), tolerance = 1e-14)
  expect_identical(rownames(shuffled), rownames(d)[rows])
})

test_that("selected order determines full indicators and later treatment or sum coding", {
  previous <- options(contrasts = c("contr.treatment", "contr.poly"))
  on.exit(options(previous))
  d <- data.frame(a = factor(c("A", "B", "C")), b = factor(c("U", "V", "U")), x = 1:3)
  design <- prepare_model_matrix(d, c("b", "a", "x"))
  expected <- cbind(bU = c(1, 0, 1), bV = c(0, 1, 0), aB = c(0, 1, 0), aC = c(0, 0, 1), x = 1:3)
  expect_equal(unname(design), unname(expected), ignore_attr = TRUE)
  expect_identical(colnames(design), colnames(expected))
  expect_identical(attr(design, "assign"), c(1L, 1L, 2L, 2L, 3L))
  options(contrasts = c("contr.sum", "contr.poly"))
  design <- prepare_model_matrix(d, c("b", "a", "x"))
  expected <- cbind(bU = c(1, 0, 1), bV = c(0, 1, 0), a1 = c(1, 0, -1), a2 = c(0, 1, -1), x = 1:3)
  expect_equal(as.vector(design), as.vector(expected))
  expect_identical(colnames(design), colnames(expected))
  # A custom finite matrix overrides global coding for the later factor.
  custom <- matrix(c(2, -1, 0, 0, 1, -2), 3, dimnames = list(c("A", "B", "C"), c("u", "v")))
  attr(d$a, "contrasts") <- custom
  design <- prepare_model_matrix(d, c("b", "a", "x"))
  expected <- cbind(bU = c(1, 0, 1), bV = c(0, 1, 0), au = c(2, -1, 0), av = c(0, 1, -2), x = 1:3)
  expect_equal(as.vector(design), as.vector(expected))
  expect_identical(colnames(design), colnames(expected))
  expect_identical(attr(design, "contrasts")$a, custom)
  recipe <- fit_encoding(d, c("b", "a", "x"))
  file <- tempfile(fileext = ".rds")
  on.exit(unlink(file), add = TRUE)
  saveRDS(recipe, file)
  options(contrasts = c("contr.helmert", "contr.poly"))
  applied <- apply_encoding(d[3:1, ], readRDS(file))
  expect_equal(as.vector(applied), as.vector(expected[3:1, ]))
  expect_identical(colnames(applied), colnames(expected))
})

test_that("logical and declared empty or missing categories retain their schema", {
  previous <- options(contrasts = c("contr.treatment", "contr.poly"))
  on.exit(options(previous))
  d <- data.frame(flag = c(TRUE, NA, FALSE), group = factor(c("A", "B", NA), levels = c("A", "B", "unused")))
  expected <- cbind(flagFALSE = c(0, NA, 1), flagTRUE = c(1, NA, 0), groupB = c(0, 1, NA), groupunused = c(0, 0, NA))
  result <- prepare_model_matrix(d, names(d))
  expect_equal(as.vector(result), as.vector(expected))
  expect_identical(colnames(result), colnames(expected))
  expect_identical(attr(result, "assign"), c(1L, 1L, 2L, 2L))
  empty <- prepare_model_matrix(d[FALSE, ], names(d))
  expect_identical(dim(empty), c(0L, 4L))
  expect_identical(colnames(empty), colnames(expected))
  missing <- d
  missing$flag[] <- NA
  missing$group[] <- NA
  expect_true(all(is.na(prepare_model_matrix(missing, names(missing)))))
  singleton <- prepare_model_matrix(data.frame(flag = TRUE), "flag")
  expect_equal(as.vector(singleton), c(0, 1))
  expect_identical(colnames(singleton), c("flagFALSE", "flagTRUE"))
})

test_that("numeric and factor expansions cannot produce ambiguous output labels", {
  cases <- list(
    data.frame(group = factor(c("A", "B")), groupA = c(10, 20)),
    data.frame(a = factor(c("bc", "d")), ab = factor(c("x", "c"), levels = c("x", "c")))
  )
  custom <- data.frame(a = factor(c("A", "B", "A")), b = factor(c("C", "D", "E")))
  attr(custom$b, "contrasts") <- matrix(c(0, 1, 0, 0, 0, 1), 3, dimnames = list(c("C", "D", "E"), c("same", "same")))
  cases <- c(cases, list(custom))
  for (d in cases) {
    original <- d
    expect_error(prepare_model_matrix(d, names(d)), "ambiguous output column names")
    expect_error(fit_encoding(d, names(d)), "ambiguous output column names")
    expect_identical(d, original)
  }
})

test_that("non-finite coding is rejected for observed categories only", {
  for (bad in c(Inf, -Inf, NA_real_, NaN)) {
    d <- data.frame(a = factor(c("A", "B")), b = factor(c("C", "D")), x = c(1, NA))
    names(d)[2] <- "bad group"
    attr(d[[2]], "contrasts") <- matrix(c(0, bad), 2, dimnames = list(c("C", "D"), "invalid"))
    # x is missing on the offending row; other covariates cannot hide bad coding.
    expect_error(prepare_model_matrix(d, names(d)), "Non-finite model-matrix coding for observed covariate 'bad group'", fixed = TRUE)
    expect_error(fit_encoding(d, names(d)), "Non-finite model-matrix coding")
    # One-table preparation uses only supplied rows. Saved fitting probes D too.
    observed <- d[1, , drop = FALSE]
    result <- prepare_model_matrix(observed, names(d))
    expect_true(all(is.finite(result)))
    expect_error(fit_encoding(observed, names(d)), "Non-finite model-matrix coding")
    d[[2]][] <- NA
    result <- prepare_model_matrix(d, names(d))
    expect_true(all(is.na(result[, attr(result, "assign") == 2L])))
  }
})
