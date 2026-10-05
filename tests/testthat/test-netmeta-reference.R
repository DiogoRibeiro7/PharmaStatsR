# Independent weighted-contrast derivation: docs/network-meta-analysis.md.
# Every row is a different two-arm study; TE is treat1 minus treat2.
netmeta_reference_data <- function() {
  data.frame(
    study = paste0("study-", seq_len(5)),
    treat1 = c("A", "A", "A", "A", "B"),
    treat2 = c("B", "B", "C", "C", "C"),
    TE = c(1, 2, 3, 4, 2),
    seTE = c(0.5, 1, 1, 0.5, 0.5),
    stringsAsFactors = FALSE
  )
}

# Fit through the public wrapper, never through a second netmeta() call.
fit_netmeta_reference <- function(data, reference = "A") {
  stopifnot(
    is.data.frame(data), is.character(reference),
    length(reference) == 1L, !is.na(reference)
  )
  pharma_network_meta_analysis(
    data$TE, data$seTE, data$treat1, data$treat2,
    studlab = data$study, sm = "MD", common = TRUE, random = FALSE,
    reference.group = reference, baseline.reference = TRUE, sep.trts = ":"
  )
}

expect_netmeta_reference <- function(actual, reference = "A") {
  treatments <- c("A", "B", "C")
  comparisons <- c("A:B", "A:C", "B:C")
  # With A fixed at zero, (B-A, C-A) = (-18/13, -47/13).
  effects <- matrix(c(
    0, 18, 47,
    -18, 0, 29,
    -47, -29, 0
  ), nrow = 3, byrow = TRUE) / 13
  variances <- matrix(c(
    0, 9, 9,
    9, 0, 10,
    9, 10, 0
  ), nrow = 3, byrow = TRUE) / 65
  # D (X' W X)^(-1) D' for A:B, A:C, B:C, including covariance signs.
  covariance <- matrix(c(
    9, 4, -5,
    4, 9, 5,
    -5, 5, 10
  ), nrow = 3, byrow = TRUE) / 65

  expect_s3_class(actual, "netmeta")
  expect_identical(actual$reference.group, reference)
  expect_true(actual$common)
  expect_false(actual$random)
  expect_identical(actual$sm, "MD")
  expect_equal(actual$k, 5)
  expect_equal(actual$m, 5)
  expect_equal(actual$n, 3)
  expect_setequal(as.character(actual$studlab), paste0("study-", seq_len(5)))
  expect_false(any(actual$multiarm))
  expect_setequal(rownames(actual$TE.common), treatments)
  expect_setequal(colnames(actual$TE.common), treatments)
  expect_setequal(rownames(actual$Cov.common), comparisons)
  expect_setequal(colnames(actual$Cov.common), comparisons)
  expect_equal(
    unname(actual$TE.common[treatments, treatments]), effects,
    tolerance = 1e-10
  )
  expect_equal(
    unname(actual$seTE.common[treatments, treatments]), sqrt(variances),
    tolerance = 1e-10
  )
  expect_equal(
    unname(actual$Cov.common[comparisons, comparisons]), covariance,
    tolerance = 1e-10
  )
}

test_that("common-effect network estimates match independent matrix targets", {
  skip_if_not_installed("netmeta")
  actual <- fit_netmeta_reference(netmeta_reference_data())
  expect_netmeta_reference(actual)

  # Recover the covariance of B-A and C-A from the two opposite contrasts.
  expect_equal(
    unname(actual$Cov.common[c("A:B", "A:C"), c("A:B", "A:C")]),
    matrix(c(9, 4, 4, 9), nrow = 2) / 65, tolerance = 1e-10
  )
  expect_equal(
    unname(actual$TE.common[c("B", "C"), "A"]),
    c(-18, -47) / 13, tolerance = 1e-10
  )
})

test_that("named data columns preserve the independent network reference", {
  skip_if_not_installed("netmeta")
  data <- netmeta_reference_data()
  actual <- pharma_network_meta_analysis(
    TE, seTE, treat1, treat2, data = data, studlab = data$study,
    sm = "MD", common = TRUE, random = FALSE,
    reference.group = "A", baseline.reference = TRUE, sep.trts = ":"
  )
  expect_netmeta_reference(actual)
})

test_that("reference treatment changes retain the signed pairwise targets", {
  skip_if_not_installed("netmeta")
  data <- netmeta_reference_data()
  for (reference in c("B", "C")) {
    actual <- fit_netmeta_reference(data, reference)
    expect_netmeta_reference(actual, reference)
  }
  # The reference-B column is A-B, B-B, C-B, not its negative.
  actual <- fit_netmeta_reference(data, "B")
  expect_equal(
    unname(actual$TE.common[c("A", "B", "C"), "B"]),
    c(18, 0, -29) / 13, tolerance = 1e-10
  )
})

test_that("row permutations and reversed contrasts retain network targets", {
  skip_if_not_installed("netmeta")
  data <- netmeta_reference_data()
  expect_netmeta_reference(fit_netmeta_reference(data[c(5, 2, 4, 1, 3), ]))

  # Reverse selected comparisons together with the sign of their effects.
  reversed <- data
  swap <- c(1L, 4L, 5L)
  reversed$treat1[swap] <- data$treat2[swap]
  reversed$treat2[swap] <- data$treat1[swap]
  reversed$TE[swap] <- -data$TE[swap]
  expect_netmeta_reference(fit_netmeta_reference(reversed))
})

test_that("a disconnected network cannot supply common-effect contrasts", {
  skip_if_not_installed("netmeta")
  # Separate A-B and C-D components, all with valid independent study rows.
  expect_error(
    pharma_network_meta_analysis(
      TE = c(1, 2, 3, 4), seTE = c(0.5, 1, 1, 0.5),
      treat1 = c("A", "A", "C", "C"),
      treat2 = c("B", "B", "D", "D"),
      studlab = paste0("disconnected-", seq_len(4)),
      sm = "MD", common = TRUE, random = FALSE, reference.group = "A"
    ),
    "sub-networks"
  )
})
