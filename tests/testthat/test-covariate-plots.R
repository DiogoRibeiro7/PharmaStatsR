local_edition(3)

library(testthat)

make_plot_data <- function() {
  set.seed(123)
  data.frame(
    SubjectID = rep(1:5, each = 2),
    Time = rep(0:1, times = 5),
    DV = rnorm(10),
    WT = rnorm(10, 70, 5)
  )
}

# plot_obs_vs_pred ---------------------------------------------------------
test_that("plot_obs_vs_pred returns ggplot with two layers", {
  plot_data <- make_plot_data()
  model <- fit_covariate_model(plot_data, "DV", "SubjectID", "Time")
  obs_pred_plot <- plot_obs_vs_pred(model, plot_data)
  expect_s3_class(obs_pred_plot, "ggplot")
  expect_length(obs_pred_plot$layers, 2)
})

# plot_residuals -----------------------------------------------------------
test_that("plot_residuals returns faceted ggplot", {
  plot_data <- make_plot_data()
  model <- fit_covariate_model(plot_data, "DV", "SubjectID", "Time")
  res_plot <- plot_residuals(model)
  expect_s3_class(res_plot, "ggplot")
  expect_false(inherits(res_plot$facet, "FacetNull"))
})

# plot_vpc ----------------------------------------------------------------
test_that("plot_vpc returns ggplot object", {
  plot_data <- make_plot_data()
  model <- fit_covariate_model(plot_data, "DV", "SubjectID", "Time")
  vpc_plot <- plot_vpc(model, plot_data, bins = 2)
  expect_s3_class(vpc_plot, "ggplot")
})

test_that("plot_vpc handles duplicated quantile breaks with default bins", {
  plot_data <- make_plot_data()
  model <- fit_covariate_model(plot_data, "DV", "SubjectID", "Time")
  vpc_plot <- plot_vpc(model, plot_data)
  expect_s3_class(vpc_plot, "ggplot")
})
