# Network meta-analysis inputs and numerical reference

`pharma_network_meta_analysis()` delegates a contrast-based network
meta-analysis to [`netmeta::netmeta()`](https://github.com/guido-s/netmeta).
Install the optional `netmeta` package to use it:

```r
install.packages("netmeta")
library(PharmaStatsR)

comparisons <- data.frame(
  treat1 = c("A", "A", "B"),
  treat2 = c("B", "C", "C"),
  TE = c(0.2, 0.5, -0.1),
  seTE = c(0.1, 0.2, 0.1),
  study = c("s1", "s2", "s3")
)

fit <- pharma_network_meta_analysis(
  TE, seTE, treat1, treat2, data = comparisons,
  studlab = comparisons$study, sm = "MD", common = TRUE, random = FALSE
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

`random = TRUE` is the wrapper's default. Set `common = TRUE, random = FALSE`
explicitly when requesting common-effect results. The backend calculates
both models internally; these switches control which results are reported.
The independent reference below checks only the common-effect components.
The existing [backend-comparison tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-netmeta-backend.R)
continue to check delegation for both model choices and the missing-backend
installation hint. No method is substituted when `netmeta` is unavailable.

## Independent common-effect reference

The fixture in [test-netmeta-reference.R](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-netmeta-reference.R)
is hand constructed. It comprises five independent two-arm studies and three
treatments, with a connected network and no multi-arm study. The effect
measure is a mean difference, `TE = mean(treat1) - mean(treat2)`. These are
arbitrary illustrative units, not patient data or estimates of real treatments.

| Study | First treatment | Second treatment | Effect \(y_i\) | Standard error \(s_i\) | Weight \(s_i^{-2}\) |
| --- | --- | --- | --- | --- | --- |
| study-1 | A | B | 1 | 1/2 | 4 |
| study-2 | A | B | 2 | 1 | 1 |
| study-3 | A | C | 3 | 1 | 1 |
| study-4 | A | C | 4 | 1/2 | 4 |
| study-5 | B | C | 2 | 1/2 | 4 |

The observed contrasts are not perfectly consistent. Unequal standard errors
and replicated comparisons make the calculation sensitive to incorrect
weighting as well as sign mistakes. Each distinct study label identifies one
independent observation; repeated treatment comparisons are not multi-arm
records.

### Weighted contrast system

Fix A at zero and define \(b=(\theta_B-\theta_A,\theta_C-\theta_A)^T\).
For the stated first-minus-second orientation, the common-effect model is
\(y=Xb+\varepsilon\), with independent sampling errors and covariance
\(\operatorname{Var}(\varepsilon)=W^{-1}\). The explicit system is

\[
X=\begin{pmatrix}-1&0\\-1&0\\0&-1\\0&-1\\1&-1\end{pmatrix},\qquad
y=\begin{pmatrix}1\\2\\3\\4\\2\end{pmatrix},\qquad
W=\operatorname{diag}(4,1,1,4,4).
\]

The supplied sampling variances are treated as known for this reference.
Consequently, the covariance is the inverse information matrix, **not** that
matrix multiplied by an estimated residual mean square:

\[
X^TWX=\begin{pmatrix}9&-4\\-4&9\end{pmatrix},\qquad
X^TWy=\begin{pmatrix}2\\-27\end{pmatrix},
\]

\[
V=(X^TWX)^{-1}=\frac1{65}\begin{pmatrix}9&4\\4&9\end{pmatrix},\qquad
\widehat b=VX^TWy=\begin{pmatrix}-18/13\\-47/13\end{pmatrix}.
\]

For the canonical comparisons A:B, A:C, B:C, use

\[
D=\begin{pmatrix}-1&0\\0&-1\\1&-1\end{pmatrix},\qquad
D\widehat b=\frac1{13}\begin{pmatrix}18\\47\\29\end{pmatrix},
\]

\[
\operatorname{Var}(D\widehat b)=DVD^T
=\frac1{65}\begin{pmatrix}9&4&-5\\4&9&5\\-5&5&10\end{pmatrix}.
\]

This last covariance has rank two because A:C equals A:B plus B:C.
Its singularity is expected; it is not a disconnected network. The two basic
contrasts remain identifiable because \(X^TWX\) is nonsingular.

| Comparison | Estimated mean difference | Standard error |
| --- | --- | --- |
| A minus B | \(18/13\) | \(\sqrt{9/65}\approx0.3721042038\) |
| A minus C | \(47/13\) | \(\sqrt{9/65}\approx0.3721042038\) |
| B minus C | \(29/13\) | \(\sqrt{10/65}\approx0.3922322703\) |

All targets follow from the displayed system, without calling `netmeta()`.
A base-R reproduction of the calculation is:

```r
X <- rbind(c(-1, 0), c(-1, 0), c(0, -1), c(0, -1), c(1, -1))
y <- c(1, 2, 3, 4, 2)
W <- diag(c(4, 1, 1, 4, 4))
V <- solve(t(X) %*% W %*% X)
b <- V %*% t(X) %*% W %*% y
D <- rbind(c(-1, 0), c(0, -1), c(1, -1))
D %*% b
D %*% V %*% t(D)
```

The connection between the graph calculation and weighted least squares,
and the returned component definitions, are described in the
[official netmeta reference](https://search.r-project.org/CRAN/refmans/netmeta/html/netmeta.html).
The tests use fixed rational targets rather than another fitted network.

### Returned orientation and boundary checks

The entry `fit$TE.common["A", "B"]` is A minus B; reversing row and column
reverses the effect but not the standard error. With A as reference, the
B and C entries in column A are therefore `c(-18, -47) / 13`.
Changing `reference.group` to B or C does not change the pairwise matrices.
For example, column B contains A minus B, B minus B, and C minus B:
`c(18, 0, -29) / 13`. The reference selection controls presentation rather
than changing the fitted pairwise effects.

`Cov.common` is the covariance of the canonical pairwise contrasts, labelled
`A:B`, `A:C`, and `B:C` when `sep.trts = ":"`. It is not the two-by-two
covariance of the basic reference-treatment coefficients. Tests select by
these labels and check the off-diagonal signs, as well as every pairwise
effect and standard error, using tolerance `1e-10` for numerical linear algebra.

The same targets are checked with both vector and named-data-column inputs,
with B and C as reference, after permuting rows, and after reversing selected
comparisons together with the signs of their effects. Study counts and labels
must still identify five independent two-arm studies. A separate input with
only A-B and C-D studies must fail as two disconnected sub-networks rather
than supply unidentified cross-component contrasts. The existing forced
missing-`netmeta` test remains in place.

The numerical tests skip only when the optional backend is absent. The
[all-Suggests validation job](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/.github/workflows/R-validation-matrix.yaml)
verifies that every Suggested package is installed and runs package tests on
the exact checked source. Its result must be reviewed before closing #131.

## Scope and assumptions

This reference covers common-effect estimation from a connected network of
independent two-arm studies with supplied positive sampling standard errors.
It checks numerical contrasts and uncertainty for that fixture; it does not
validate transitivity, clinical consistency, the appropriateness of a
common-effect model, multi-arm adjustments, random-effects estimation,
rankings, prediction intervals, or inference after selecting studies.
The fitted consistent contrasts do not establish that the underlying studies
are consistent. Review effect comparability, effect modifiers, study selection,
and heterogeneity for a real synthesis. The method remains experimental.
See the [limitations guide](limitations.md) for wider package boundaries.

## R help

Full arguments and return values: [`pharma_network_meta_analysis()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_network_meta_analysis.Rd). In an installed package, run `help("pharma_network_meta_analysis", package = "PharmaStatsR")`.
