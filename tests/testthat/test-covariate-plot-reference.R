local_edition(3)

plot_reference_data <- function() {
  d <- data.frame(SubjectID = rep(1:4, each = 3), Time = rep(c(-1, 0, 1), 4))
  d$DV <- 2 + 1.5 * d$Time + rep(c(-3, -1, 1, 3), each = 3) + rep(c(1, -2, 1), 4)
  d
}

test_that("observed and residual coordinates agree with balanced REML formulas", {
  d <- plot_reference_data()
  # Within-subject SS=24, df=7; between-subject MS=20.
  # sigma^2=24/7, tau^2=116/21, BLUP shrinkage=29/35.
  prediction <- 2 + 1.5 * d$Time + rep(c(-3, -1, 1, 3), each = 3) * 29 / 35
  raw <- rep(c(-3, -1, 1, 3), each = 3) * 6 / 35 + rep(c(1, -2, 1), 4)
  normalized <- raw / sqrt(24 / 7)
  for (rows in list(seq_len(nrow(d)), c(12, 1, 8, 3, 5, 10, 2, 9, 4, 7, 11, 6))) {
    input <- d[rows, ]
    model <- fit_covariate_model(input, "DV", "SubjectID", "Time")
    original <- model
    points <- ggplot2::ggplot_build(plot_obs_vs_pred(model, input))$data
    expect_equal(points[[1]]$x, prediction[rows], tolerance = 1e-5)
    expect_equal(points[[1]]$y, input$DV)
    expect_equal(points[[2]]$slope, 1)
    expect_equal(points[[2]]$intercept, 0)
    p <- plot_residuals(model)
    expect_equal(p$data$Time, rep(input$Time, 2))
    expect_equal(p$data$Residual, c(raw[rows], normalized[rows]), tolerance = 1e-5)
    built <- ggplot2::ggplot_build(p)
    panels <- built$layout$layout
    for (type in c("Raw", "Normalized")) {
      panel <- panels$PANEL[panels$Type == type]
      values <- built$data[[1]][built$data[[1]]$PANEL == panel, ]
      expected <- if (type == "Raw") raw else normalized
      expect_equal(values$x, input$Time)
      expect_equal(values$y, expected[rows], tolerance = 1e-5)
    }
    expect_identical(model, original)
  }
})

test_that("caller column names cannot override plotted predictions", {
  d <- data.frame(Time = 1:4, DV = c(1, 2, 4, 5), preds = 1001:1004, pred = -1001:-1004)
  model <- stats::lm(DV ~ Time, data = d)
  original <- d
  p <- plot_obs_vs_pred(model, d)
  retained <- setdiff(names(d), "preds")
  expect_identical(p$data[retained], d[retained])
  # Mean response=3, mean time=2.5; cross-product=7 and time SS=5.
  expect_equal(ggplot2::ggplot_build(p)$data[[1]]$x, c(0.9, 2.3, 3.7, 5.1))
  expect_identical(d, original)
  d$preds <- -d$preds
  expect_equal(ggplot2::ggplot_build(plot_obs_vs_pred(model, d))$data[[1]]$x, c(0.9, 2.3, 3.7, 5.1))
})

test_that("na.exclude residuals and unknown subjects retain missing positions", {
  d <- plot_reference_data()
  extra <- d[1:2, ]
  extra$DV <- NA_real_
  input <- rbind(extra[1, ], d, extra[2, ])
  model <- fit_covariate_model(input, "DV", "SubjectID", "Time")
  p <- plot_residuals(model)
  raw <- rep(c(-3, -1, 1, 3), each = 3) * 6 / 35 + rep(c(1, -2, 1), 4)
  expect_equal(p$data$Time, rep(input$Time, 2))
  expect_equal(p$data$Residual, c(NA, raw, NA, NA, raw / sqrt(24 / 7), NA), tolerance = 1e-5)
  new <- d[c(12, 1, 7), ]
  new$SubjectID[2] <- 999
  new$DV[3] <- NA_real_
  points <- ggplot2::ggplot_build(plot_obs_vs_pred(model, new))$data[[1]]
  expect_equal(points$x, c(3.5 + 3 * 29 / 35, NA, 0.5 + 29 / 35), tolerance = 1e-5)
  expect_equal(points$y, new$DV)
  omitted <- nlme::lme(DV ~ Time, random = ~ 1 | SubjectID, data = input, na.action = stats::na.omit)
  expect_error(plot_residuals(omitted), "Response residuals.*one value per data row")
})

test_that("binned summaries and all layers agree with explicit percentile arithmetic", {
  training <- data.frame(Time = 1:8, DV = 2 + 3 * (1:8))
  model <- stats::lm(DV ~ Time, data = training)
  d <- data.frame(Time = 1:8, DV = c(0, 10, 20, 30, 50, 60, 70, 80), pred = 999)
  expected <- data.frame(bin = c(2.5, 6.5), obs_p5 = c(1.5, 51.5), obs_med = c(15, 65), obs_p95 = c(28.5, 78.5), pred_med = c(9.5, 21.5))
  # Type-7 edges are 1, 4.5, 8. Four ordered values interpolate at
  # positions 1.15, 2.5 and 3.85 for the 5th, 50th and 95th percentiles.
  for (rows in list(1:8, c(8, 2, 6, 1, 5, 3, 7, 4))) {
    input <- d[rows, ]
    p <- plot_vpc(model, input, bins = 2)
    expect_equal(p$data, expected)
    layers <- ggplot2::ggplot_build(p)$data
    expect_equal(layers[[1]]$x, expected$bin)
    expect_equal(layers[[1]]$ymin, expected$obs_p5)
    expect_equal(layers[[1]]$ymax, expected$obs_p95)
    expect_equal(layers[[2]]$y, expected$obs_med)
    expect_equal(layers[[3]]$y, expected$pred_med)
    expect_equal(layers[[2]]$x, expected$bin)
    expect_equal(layers[[3]]$x, expected$bin)
    expect_identical(input, d[rows, ])
  }
  training$DV <- 7 - 2 * training$DV
  d$DV <- 7 - 2 * d$DV
  transformed <- plot_vpc(stats::lm(DV ~ Time, data = training), d, bins = 2)$data
  expect_equal(transformed$obs_p5, 7 - 2 * expected$obs_p95)
  expect_equal(transformed$obs_p95, 7 - 2 * expected$obs_p5)
  expect_equal(transformed$obs_med, 7 - 2 * expected$obs_med)
  expect_equal(transformed$pred_med, 7 - 2 * expected$pred_med)
})

test_that("duplicate edges, right-closed bins and mean times have fixed references", {
  training <- data.frame(Time = 0:3, DV = 2 + 3 * (0:3))
  model <- stats::lm(DV ~ Time, data = training)
  d <- data.frame(Time = c(0, 0, 0, 0, 1, 1, 2, 3), DV = c(0, 10, 20, 30, 40, 50, 60, 70))
  # Requested quartiles: 0, 0, .5, 1.25, 3 -> three intervals.
  expect_equal(plot_vpc(model, d, bins = 4)$data, data.frame(
    bin = c(0, 1, 2.5), obs_p5 = c(1.5, 40.5, 60.5), obs_med = c(15, 45, 65),
    obs_p95 = c(28.5, 49.5, 69.5), pred_med = c(2, 5, 9.5)
  ))
  d <- data.frame(Time = c(0, 1, 1, 2), DV = c(0, 10, 20, 30))
  # The boundary at 1 belongs to the first bin; x is 2/3, not 1/2.
  expect_equal(plot_vpc(model, d, bins = 2)$data, data.frame(
    bin = c(2 / 3, 2), obs_p5 = c(1, 30), obs_med = c(10, 30),
    obs_p95 = c(19, 30), pred_med = c(5, 8)
  ))
})

test_that("missing values use separate observed and predicted bin populations", {
  training <- data.frame(x = 1:8, DV = 2 + 3 * (1:8))
  model <- stats::lm(DV ~ x, data = training)
  d <- data.frame(Time = c(1:8, NA), x = c(1, 2, NA, 4:8, 999), DV = c(0, NA, 20, 30, rep(NA, 4), 999))
  expect_equal(plot_vpc(model, d, bins = 2)$data, data.frame(
    bin = c(2.5, 6.5), obs_p5 = c(2, NA), obs_med = c(20, NA),
    obs_p95 = c(29, NA), pred_med = c(8, 21.5)
  ))
})

test_that("malformed predictions cannot be recycled or interpreted as coordinates", {
  d <- data.frame(Time = 1:4, DV = 1:4)
  value <- NULL
  local_mocked_bindings(predict = function(...) value, .package = "stats")
  for (bad in list(1, numeric(), 1:2, 1:5, matrix(1:4), list(1, 2, 3, 4), letters[1:4], rep(TRUE, 4), rep(1 + 1i, 4), c(1, 2, 3, Inf))) {
    value <- bad
    expect_error(plot_obs_vs_pred(NULL, d), "Predictions.*real numeric vector.*one value per data row")
    expect_error(plot_vpc(NULL, d, bins = 2), "Predictions.*real numeric vector.*one value per data row")
  }
  value <- c(1, NA, NaN, 4)
  expect_equal(plot_obs_vs_pred(NULL, d)$data$preds, value)
})

test_that("malformed residuals fail before plotting", {
  model <- list(data = data.frame(Time = 1:4))
  value <- NULL
  target <- "response"
  local_mocked_bindings(residuals = function(object, type, ...) {
    if (type == target) value else 1:4
  }, .package = "stats")
  for (type in c("response", "normalized")) {
    target <- type
    for (bad in list(1, numeric(), matrix(1:4), letters[1:4], rep(1 + 1i, 4), c(1, 2, 3, -Inf))) {
      value <- bad
      expect_error(plot_residuals(model), "residuals.*one value per data row")
    }
  }
})

test_that("diagnostic input and bin errors are explicit before prediction", {
  local_mocked_bindings(predict = function(...) stop("unexpected prediction"), .package = "stats")
  d <- data.frame(Time = 1:4, DV = 1:4)
  for (bad in list(0, -1, 1.5, NA_real_, Inf, "2", TRUE, c(1, 2), matrix(2), numeric(), .Machine$integer.max)) {
    expect_error(plot_vpc(NULL, d, bins = bad), "bins.*positive integer")
  }
  for (values in list(rep(NA_real_, 4), rep(1, 4), numeric())) {
    input <- data.frame(Time = values, DV = rep(1, length(values)))
    expect_error(plot_vpc(NULL, input), "at least 2 unique values")
  }
  for (values in list(letters[1:4], factor(1:4), rep(TRUE, 4), c(1, 2, 3, Inf), I(matrix(1:4)))) {
    input <- d
    input$DV <- values
    expect_error(plot_obs_vs_pred(NULL, input), "DV must be a real numeric vector")
    expect_error(plot_vpc(NULL, input), "DV must be a real numeric vector")
    input <- d
    input$Time <- values
    expect_error(plot_vpc(NULL, input), "Time must be a real numeric vector")
    expect_error(plot_residuals(list(data = input)), "Time must be a real numeric vector")
  }
  duplicate <- d
  names(duplicate) <- c("DV", "DV")
  expect_error(plot_obs_vs_pred(NULL, duplicate), "unique column names")
  expect_error(plot_vpc(NULL, duplicate), "unique column names")
  expect_error(plot_residuals(list(data = data.frame(x = 1))), "model\\$data must contain 'Time'")
})
