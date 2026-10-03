test_that("block bootstrap accepts character IDs and samples whole clusters", {
  d <- data.frame(
    cluster = c("A", "A", "B", "B", "B"),
    value = 1:5,
    unused = c(NA, 2, 3, 4, 5)
  )
  set.seed(21)
  res <- pharma_block_bootstrap(
    d, as.character(d$cluster), function(rows) rows,
    R = 40, progress = FALSE, resample_id = "draw_id"
  )
  expect_length(res, 40)
  for (rows in res) {
    expect_identical(class(rows), "data.frame")
    expect_true(nrow(rows) %in% 4:6)
    expect_identical(sort(unique(rows$draw_id)), 1:2)
    groups <- split(rows, rows$draw_id)
    expect_true(all(vapply(groups, function(g) length(unique(g$cluster)) == 1L,
                           logical(1))))
    expect_true(all(vapply(groups, function(g) {
      identical(g$value, d$value[d$cluster == g$cluster[1]])
    }, logical(1))))
  }
  expect_true(any(vapply(res, function(rows) {
    length(unique(rows$cluster)) < length(unique(rows$draw_id))
  }, logical(1))))
})

test_that("cluster draws agree with independently sampled cluster indices", {
  d <- data.frame(cluster = c("A", "A", "B", "B", "B", "C"),
                  value = 1:6)
  clusters <- split(d$value, d$cluster)
  set.seed(93)
  selected <- replicate(8, sample.int(3L, 3L, replace = TRUE),
                        simplify = FALSE)
  expected <- lapply(selected, function(ids) {
    list(values = unlist(clusters[ids], use.names = FALSE),
         copies = rep(seq_along(ids), lengths(clusters)[ids]))
  })
  set.seed(93)
  actual <- pharma_block_bootstrap(
    d, "cluster", function(rows) {
      list(values = rows$value, copies = rows$copy)
    }, R = 8, progress = FALSE, resample_id = "copy"
  )

  expect_identical(actual, expected)
  set.seed(93)
  expect_identical(pharma_block_bootstrap(
    d, "cluster", function(rows) rows$value,
    R = 8, progress = FALSE
  ), lapply(expected, `[[`, "values"))
})

test_that("unused factor levels are not sampled as empty clusters", {
  d <- data.frame(cluster = factor(c("A", "A", "B", "B", "B"),
                                   levels = c("A", "B", "never")),
                  value = 1:5)
  set.seed(22)
  sizes <- pharma_block_bootstrap(
    d, "cluster", nrow, R = 30, progress = FALSE
  )
  expect_true(all(unlist(sizes) %in% 4:6))
})

test_that("block bootstrap keeps positional statistic arguments", {
  d <- data.frame(group = rep(c("A", "B"), each = 2), value = 1:4)
  stat <- function(rows, multiplier) nrow(rows) * multiplier
  res <- pharma_block_bootstrap(d, "group", stat, R = 2,
                                progress = FALSE, 3)
  expect_equal(res, list(12, 12))
})

test_that("block bootstrap retains one result per replicate for NULL statistics", {
  d <- data.frame(cluster = c("A", "A", "B"), value = 1:3)
  actual <- pharma_block_bootstrap(
    d, "cluster", function(rows) NULL, R = 3, progress = FALSE
  )
  expect_identical(actual, rep(list(NULL), 3))
})

test_that("block bootstrap validates its cluster and design arguments", {
  d <- data.frame(group = c("A", "A", "B"), value = 1:3)
  stat <- function(rows) nrow(rows)
  for (bad in list(0, -1, 1.5, NA_real_, Inf, "3", c(1, 2))) {
    expect_error(pharma_block_bootstrap(d, "group", stat, R = bad), "`R`")
  }
  expect_error(pharma_block_bootstrap(d, "group", stat, progress = NA),
               "`progress`")
  expect_error(pharma_block_bootstrap(d, c("A", NA, "B"), stat),
               "`cluster`")
  expect_error(pharma_block_bootstrap(d, rep("A", 3), stat),
               "two observed clusters")
  expect_error(pharma_block_bootstrap(d, "group", stat,
                                      resample_id = "group"), "`resample_id`")
  expect_error(pharma_block_bootstrap(d, "group", stat,
                                      resample_id = NA_character_),
               "`resample_id`")
})
