# Metafor evaluates 'slab' from its call and, for named columns, model data.
# Compare the wrappers with direct backend calls for both label sources.
test_that("meta fit preserves explicit and data-column study labels", {
  skip_if_not_installed("metafor")

  effects <- c(-0.4, 0.1, 0.5, 0.8)
  variances <- c(0.04, 0.09, 0.16, 0.25)
  studies <- data.frame(
    study = c("A", "B", "C", "D"),
    display = c("Plot A", "Plot B", "Plot C", "Plot D")
  )
  labels <- studies$study

  direct <- metafor::rma(yi = effects, vi = variances,
                         method = "FE", slab = labels)
  wrapped <- pharma_meta_analysis(effects, variances,
                                  method = "FE", slab = labels)
  expect_identical(wrapped$slab, labels)
  expect_equal(wrapped$yi, direct$yi)
  expect_equal(wrapped$vi, direct$vi)
  expect_equal(wrapped$b, direct$b, tolerance = 1e-12)

  direct_data <- metafor::rma(yi = effects, vi = variances,
                              method = "FE", data = studies, slab = study)
  wrapped_data <- pharma_meta_analysis(effects, variances, method = "FE",
                                       data = studies, slab = study)
  expect_identical(wrapped_data$slab, direct_data$slab)
  expect_identical(wrapped_data$slab, labels)
  expect_equal(wrapped_data$b, direct_data$b, tolerance = 1e-12)
  expect_error(pharma_meta_analysis(effects, variances, method = "FE",
                                    slab = labels[-1L]), "slab")
})

test_that("meta plots forward vector and model-data label overrides", {
  skip_if_not_installed("metafor")

  effects <- c(-0.4, 0.1, 0.5, 0.8)
  variances <- c(0.04, 0.09, 0.16, 0.25)
  studies <- data.frame(
    study = c("A", "B", "C", "D"),
    display = c("Plot A", "Plot B", "Plot C", "Plot D")
  )
  override <- paste0("Override ", studies$study)
  fit <- metafor::rma(yi = effects, vi = variances, method = "FE",
                      data = studies, slab = study)

  plot_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(plot_file, width = 8, height = 6)
  plot_device <- grDevices::dev.cur()
  on.exit({
    if (plot_device %in% grDevices::dev.list()) {
      grDevices::dev.off(plot_device)
    }
    unlink(plot_file)
  }, add = TRUE)

  direct <- withVisible(metafor::funnel(fit, yaxis = "sei", slab = override))
  wrapped <- withVisible(pharma_funnel_plot(fit, yaxis = "sei",
                                            slab = override))
  expect_false(wrapped$visible)
  expect_equal(wrapped$value, direct$value)
  expect_identical(wrapped$value$slab, override)
  expect_equal(unname(as.numeric(wrapped$value$x)), effects,
               tolerance = 1e-12)
  expect_equal(unname(as.numeric(wrapped$value$y)), sqrt(variances),
               tolerance = 1e-12)

  direct_data <- metafor::funnel(fit, yaxis = "vi", slab = display)
  wrapped_data <- pharma_funnel_plot(fit, yaxis = "vi", slab = display)
  expect_equal(wrapped_data, direct_data)
  expect_identical(wrapped_data$slab, studies$display)
  expect_equal(unname(as.numeric(wrapped_data$y)), variances,
               tolerance = 1e-12)

  direct_forest <- withVisible(metafor::forest(
    fit, slab = override, xlim = c(-2, 2), alim = c(-1, 1), at = c(-1, 0, 1)
  ))
  wrapped_forest <- withVisible(pharma_forest_plot(
    fit, slab = override, xlim = c(-2, 2), alim = c(-1, 1), at = c(-1, 0, 1)
  ))
  expect_false(wrapped_forest$visible)
  for (field in c("xlim", "alim", "at", "rows")) {
    expect_equal(wrapped_forest$value[[field]], direct_forest$value[[field]])
  }

  expect_error(pharma_funnel_plot(fit, slab = override[-1L]), "slab")
  expect_error(pharma_forest_plot(fit, slab = override[-1L]), "slab")
  expect_identical(grDevices::dev.cur(), plot_device)
  grDevices::dev.off(plot_device)
  expect_gt(file.info(plot_file)$size, 100L)
})
