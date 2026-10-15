local_edition(3)

screening_methods <- function() {
  list(
    function(data, response, covariates) {
      screen_covariates_stepwise(data, response, "SubjectID", covariates)
    },
    screen_covariates_bayesian
  )
}

make_screening_data <- function() {
  set.seed(42)
  d <- data.frame(SubjectID = 1:100, x1 = rnorm(100), x2 = rnorm(100))
  d$DV <- 5 * d$x1 + rnorm(100, sd = 0.2)
  d
}

test_that("screening treats column names literally and returns exact names", {
  d <- make_screening_data()
  original <- d
  unusual <- c(
    "body mass", "x+y", "x:y", "I(x)", "`x`", ".", "(Intercept)",
    ".screen_response", "stop('column names are not code')"
  )
  for (screen in screening_methods()) {
    expected <- screen(d, "DV", c("x1", "x2"))
    expect_true("x1" %in% expected)
    for (name in unusual) {
      renamed <- d
      names(renamed)[names(renamed) == "DV"] <- "drug response + dose"
      names(renamed)[names(renamed) == "x1"] <- name
      selected <- screen(renamed, "drug response + dose", c(name, "x2"))
      expect_identical(selected, ifelse(expected == "x1", name, expected))
    }
    expect_identical(screen(d, "DV", c(signal = "x1")), "x1")
  }
  expect_identical(d, original)
})

test_that("categorical covariates are selected as whole terms", {
  set.seed(123)
  binary <- rep(c(FALSE, TRUE), 50)
  d <- data.frame(SubjectID = 1:100, DV = 5 * binary + rnorm(100, sd = 0.2))
  for (column in list(
    binary, ifelse(binary, "treated", "control"),
    factor(binary, levels = c(FALSE, TRUE, "unused"))
  )) {
    d[["treatment group"]] <- column
    for (screen in screening_methods()) {
      expect_identical(screen(d, "DV", "treatment group"), "treatment group")
    }
  }
})

test_that("all screening models use the same complete-case cohort", {
  d <- make_screening_data()
  d$DV[1] <- NA
  d$x1[2] <- NaN
  d$x2[3] <- NA
  d$x1[3] <- Inf # Removed because another candidate is missing.
  d$SubjectID[4] <- NA # IDs do not participate in row-level screening.
  d$unused <- NA_real_
  retained <- d[-(1:3), ]
  for (screen in screening_methods()) {
    expect_identical(
      screen(d, "DV", c("x1", "x2")),
      screen(retained, "DV", c("x1", "x2"))
    )
  }

  # Verify that the BIC null and both candidate fits use this same cohort.
  fitted_rows <- list()
  real_lm <- stats::lm
  local_mocked_bindings(
    lm = function(formula, data, ...) {
      fitted_rows[[length(fitted_rows) + 1L]] <<- rownames(data)
      real_lm(formula, data = data, ...)
    },
    .package = "stats"
  )
  screen_covariates_bayesian(d, "DV", c("x1", "x2"))
  expect_length(fitted_rows, 3L)
  for (rows in fitted_rows) {
    expect_identical(rows, rownames(retained))
  }
})

test_that("screening rejects ambiguous names and response leakage", {
  d <- make_screening_data()
  for (screen in screening_methods()) {
    expect_error(screen(1, "DV", "x1"), "must be a data.frame")
    responses <- list(NULL, NA_character_, 1, c("DV", "x1"), matrix("DV"))
    for (response in responses) {
      expect_error(screen(d, response, "x1"), "`response` column not found")
    }
    for (candidates in list(1, c("x1", NA), c("x1", "x1"), matrix("x1"))) {
      expect_error(screen(d, "DV", candidates), "unique column names")
    }
    expect_error(screen(d, "DV", "missing"), "Covariates not found")
    expect_error(screen(d, "DV", c("DV", "x1")), "cannot also be a candidate")
    duplicate <- d
    names(duplicate)[3] <- "x1"
    expect_error(screen(duplicate, "DV", "x1"), "unique column names")
    for (name in c("", NA_character_)) {
      unnamed <- d
      names(unnamed)[3] <- name
      expect_error(screen(unnamed, "DV", "x1"), "nonmissing, nonempty")
    }
  }
})

test_that("screening rejects unsupported response and candidate types", {
  d <- make_screening_data()
  for (screen in screening_methods()) {
    for (column in list(
      rep("a", 100), rep(TRUE, 100), factor(rep(c("a", "b"), 50)),
      rep(1 + 1i, 100), matrix(seq_len(200), nrow = 100)
    )) {
      invalid <- d
      invalid$DV <- column
      expect_error(screen(invalid, "DV", "x1"), "real numeric vector")
    }
    for (column in list(
      rep(1 + 1i, 100), matrix(seq_len(200), nrow = 100),
      as.list(seq_len(100))
    )) {
      invalid <- d
      invalid$x1 <- column
      expect_error(
        screen(invalid, "DV", "x1"), "numeric, logical, character, or factor"
      )
    }
  }
})

test_that("screening rejects unusable retained observations", {
  d <- make_screening_data()
  for (screen in screening_methods()) {
    for (column in c("DV", "x1")) {
      for (value in c(Inf, -Inf)) {
        invalid <- d
        invalid[[column]][1] <- value
        expect_error(screen(invalid, "DV", "x1"), "finite on complete-case")
      }
      constant <- d
      constant[[column]] <- 1
      expect_error(screen(constant, "DV", "x1"), "constant on complete-case")
    }
    for (rows in 0:2) {
      expect_error(
        screen(d[seq_len(rows), ], "DV", "x1"), "three complete-case rows"
      )
    }
    missing <- d
    missing$x1 <- NA_real_
    expect_error(screen(missing, "DV", "x1"), "three complete-case rows")
    # A factor can lose all variation after the common row filter.
    collapsed <- d
    collapsed$x1 <- factor(c("a", rep("b", 99)), levels = c("a", "b", "c"))
    collapsed$x2[1] <- NA
    expect_error(
      screen(collapsed, "DV", c("x1", "x2")), "constant on complete-case"
    )
  }
})

test_that("empty selections remain empty and stepwise IDs are checked", {
  d <- make_screening_data()
  for (screen in screening_methods()) {
    for (candidates in list(character(0), NULL)) {
      expect_identical(screen(d, "DV", candidates), character(0))
    }
  }
  for (id in list(NULL, NA_character_, 1, c("SubjectID", "x1"), matrix("x1"))) {
    expect_error(
      screen_covariates_stepwise(d, "DV", id, "x1"), "`id` column not found"
    )
  }
})
