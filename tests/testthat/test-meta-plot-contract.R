# Metafor's forest plot returns layout metadata, while its funnel plot
# returns the coordinates and labels of the drawn study points.
test_that("meta plots draw and return checked layout and study coordinates", {
  skip_if_not_installed("metafor")

  effects <- c(-0.4, 0.1, 0.5, 0.8)
  variances <- c(0.04, 0.09, 0.16, 0.25)
  labels <- c("A", "B", "C", "D")
  fit <- pharma_meta_analysis(effects, variances, method = "FE",
                              slab = labels)

  plot_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(plot_file, width = 8, height = 6)
  plot_device <- grDevices::dev.cur()
  on.exit({
    if (plot_device %in% grDevices::dev.list()) {
      grDevices::dev.off(plot_device)
    }
    unlink(plot_file)
  }, add = TRUE)

  forest <- withVisible(pharma_forest_plot(
    fit, xlim = c(-2, 2), alim = c(-1, 1),
    at = c(-1, 0, 1), rows = 4:1
  ))
  expect_false(forest$visible)
  expect_type(forest$value, "list")
  expect_equal(forest$value$xlim, c(-2, 2))
  expect_equal(forest$value$alim, c(-1, 1))
  expect_equal(forest$value$at, c(-1, 0, 1))
  expect_equal(forest$value$rows, 4:1)
  expect_true(is.numeric(forest$value$ylim))
  expect_length(forest$value$ylim, 2)

  funnel <- withVisible(pharma_funnel_plot(
    fit, yaxis = "sei", slab = labels, xlim = c(-1, 1.5)
  ))
  expect_false(funnel$visible)
  expect_s3_class(funnel$value, "data.frame")
  expect_true(all(c("x", "y", "slab") %in% names(funnel$value)))
  expect_setequal(funnel$value$slab, labels)
  selected <- match(labels, funnel$value$slab)
  expect_equal(unname(funnel$value$x[selected]), effects, tolerance = 1e-12)
  expect_equal(unname(funnel$value$y[selected]), sqrt(variances),
               tolerance = 1e-12)

  # The alternative y-axis is an argument passed through to metafor.
  variance_axis <- pharma_funnel_plot(fit, yaxis = "vi", slab = labels)
  selected_variance <- match(labels, variance_axis$slab)
  expect_equal(unname(variance_axis$y[selected_variance]), variances,
               tolerance = 1e-12)

  expect_error(pharma_forest_plot(NULL), "`model` must")
  expect_error(pharma_funnel_plot(list()), "`model` must")
  expect_error(pharma_funnel_plot(fit, yaxis = "invalid"))

  expect_identical(grDevices::dev.cur(), plot_device)
  grDevices::dev.off(plot_device)
  expect_true(file.exists(plot_file))
  expect_gt(file.info(plot_file)$size, 100L)
})
