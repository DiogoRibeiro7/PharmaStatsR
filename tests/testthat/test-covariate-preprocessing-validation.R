local_edition(3)

test_that("preprocessing rejects ambiguous variable and column names", {
  d <- data.frame(x = 1:3, y = 4:6)
  methods <- list(center_scale, impute_mean, impute_median, impute_ml)
  for (preprocess in methods) {
    for (vars in list(c("x", "x"), c("x", NA_character_), 1, matrix("x"))) {
      expect_error(preprocess(d, vars), "unique column names")
    }
    expect_error(preprocess(d, "missing"), "Variables not found")
    duplicate <- d
    names(duplicate) <- c("x", "x")
    expect_error(preprocess(duplicate, "x"), "unique column names")
    for (name in c("", NA_character_)) {
      unnamed <- d
      names(unnamed)[2] <- name
      expect_error(
        preprocess(unnamed, "x"), "nonmissing, nonempty column names"
      )
    }
  }
})

test_that("numeric preprocessing rejects infinities and unsupported types", {
  for (preprocess in list(center_scale, impute_mean, impute_median)) {
    for (column in list(c(1, Inf, NA), c(1, -Inf, NA))) {
      expect_error(preprocess(data.frame(x = column), "x"), "infinite values")
    }
    for (column in list(
      c("1", NA, "3"), factor(c("a", NA, "b")), c(TRUE, NA, FALSE),
      c(1 + 1i, NA_complex_, 3 + 1i), I(matrix(1:6, nrow = 3))
    )) {
      d <- data.frame(x = 1:3)
      d$x <- column
      expect_error(preprocess(d, "x"), "must be numeric")
    }
  }
  expect_error(
    impute_ml(data.frame(x = c(1, Inf, NA), y = 1:3), "x"), "infinite values"
  )
})

test_that("an empty variable selection preserves the data", {
  d <- data.frame(x = 1:3)
  for (vars in list(character(0), NULL)) {
    expect_identical(center_scale(d, vars)$data, d)
    expect_equal(nrow(center_scale(d, vars)$params), 0)
    for (impute in list(impute_mean, impute_median, impute_ml)) {
      expect_identical(impute(d, vars), d)
    }
  }
})
