# Network meta-analysis inputs

`pharma_network_meta_analysis()` delegates a contrast-based network
meta-analysis to [`netmeta::netmeta()`](https://github.com/guido-s/netmeta).
Install the optional `netmeta` package to use it:

```r
install.packages("netmeta")

comparisons <- data.frame(
  treat1 = c("A", "A", "B"),
  treat2 = c("B", "C", "C"),
  TE = c(0.2, 0.5, -0.1),
  seTE = c(0.1, 0.2, 0.1),
  study = c("s1", "s2", "s3")
)

fit <- pharma_network_meta_analysis(
  TE, seTE, treat1, treat2, data = comparisons,
  studlab = comparisons$study, sm = "MD", random = FALSE
)
summary(fit)
```

Here `TE` is the effect of the first treatment compared with the second, and
`seTE` is its **standard error**, not its variance. Each row in the example
comes from a different study. The `data` argument resolves the four named
contrast columns; pass study labels as `studlab` through `...`.

If multiple rows come from a multi-arm study, use the same `studlab` value for
those rows and supply all pairwise contrasts from that study. The backend
uses these labels to account for within-study dependence. If labels are
omitted, `netmeta` warns and assumes each contrast is from an independent
study. See the [netmeta source documentation](https://github.com/guido-s/netmeta/blob/develop/R/netmeta.R)
for the multi-arm requirements. Prepare the contrast standard errors and
orientation consistently before fitting.

`random = TRUE` is the wrapper's default. Select `FALSE` deliberately for a
common-effects network model as shown above. The CI test compares both model
choices and their standard errors with direct `netmeta::netmeta()` calls using
the same labelled contrasts. This checks delegation, not network consistency
or transitivity. Review those assumptions, heterogeneity, study
selection, and the chosen effect measure for a real synthesis. Without the
optional backend, the helper gives an installation hint; it never substitutes
another method.
