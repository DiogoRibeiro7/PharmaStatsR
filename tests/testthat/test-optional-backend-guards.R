test_that("optional integrations report actionable missing-package errors", {
  # Force the unavailable path even when the CI runner installed a backend.
  testthat::local_mocked_bindings(
    .pharma_optional_available = function(package) FALSE
  )
  d <- data.frame(y = c(1, 2, 4, 5), x = 1:4,
                  id = rep(1:2, each = 2), status = c(0, 1, 0, 2))
  log_file <- tempfile()
  expect_true(file.create(log_file))
  on.exit(unlink(log_file), add = TRUE)
  cases <- list(
    list("rstanarm", "pharma_bayesian_glm",
         function() pharma_bayesian_glm(y ~ x, d)),
    list("rstanarm", "pharma_posterior_summary",
         function() pharma_posterior_summary(list())),
    list("lme4", "pharma_lmm",
         function() pharma_lmm(y ~ x + (1 | id), d)),
    list("geepack", "pharma_gee",
         function() pharma_gee(y ~ x, id = id, data = d)),
    list("cmprsk", "pharma_competing_risks",
         function() pharma_competing_risks(
           survival::Surv(x, status) ~ y, d)),
    list("openssl", "pharma_audit_log",
         function() pharma_audit_log("entry", tempfile(), key = "secret")),
    list("openssl", "pharma_audit_verify",
         function() pharma_audit_verify(log_file, key = "secret")),
    list("future", "pharma_parallel_bootstrap",
         function() pharma_parallel_bootstrap(
           d, function(rows) mean(rows$y), R = 1, plan = "sequential"))
  )

  for (case in cases) {
    package <- case[[1L]]
    caller <- case[[2L]]
    expected <- sprintf(
      "Package '%s' is required for %s\\(\\).*install.packages\\('%s'\\)",
      package, caller, package
    )
    expect_error(case[[3L]](), expected, info = caller)
  }
})

test_that("parallel bootstrap also reports a missing future.apply backend", {
  testthat::local_mocked_bindings(
    .pharma_optional_available = function(package) package != "future.apply"
  )
  d <- data.frame(y = 1:3)
  expect_error(
    pharma_parallel_bootstrap(d, function(rows) mean(rows$y),
                              R = 1, plan = "sequential"),
    "Package 'future.apply' is required.*install.packages\\('future.apply'\\)"
  )
})
