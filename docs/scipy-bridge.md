# Python SciPy t-test bridge

`pharma_scipy_ttest(x, y, equal_var = TRUE)` calls
[`scipy.stats.ttest_ind`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.ttest_ind.html)
through `reticulate`. It returns a list with the t statistic and two-sided
p-value. `equal_var = TRUE` requests the pooled-variance test; use `FALSE` for
Welch's test. This is an optional integration, with no automatic R fallback.

Install the R bridge and SciPy in the Python environment you intend to use:

```r
install.packages("reticulate")
```

```sh
/absolute/path/to/python -m pip install scipy
```

Set the same interpreter **before** reticulate initializes Python in the R
session. Inspect the selected path and module availability:

```r
Sys.setenv(RETICULATE_PYTHON = "/absolute/path/to/python")
reticulate::py_config()
reticulate::py_module_available("scipy.stats")

x <- c(1, 2, 4, 7, 8)
y <- c(3, 5, 9, 10, 12)
pharma_scipy_ttest(x, y, equal_var = FALSE)
```

If `reticulate` or `scipy.stats` is unavailable, the function names the missing
backend and gives an installation hint. The [reticulate module
check](https://rstudio.github.io/reticulate/reference/py_module_available.html)
initializes Python, so select the interpreter before calling it.

On this example, SciPy 1.17.0 yields t = −1.5852581740 for both variance
choices, with two-sided p = 0.1515678011 for pooled variance and p =
0.1529449894 for Welch. The tests compare both results with fixed values and
`stats::t.test()`; they do not establish the appropriateness of either model
for a study. Check independence, missing observations, variance assumptions,
and the analysis population before interpreting the result.

## Independent numerical reference

The [independent reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-scipy-reference.R)
use unequal sample sizes and variances:

\[
x=(1,2,4,7),\qquad y=(0,3,9,10,12).
\]

The sample summaries are

\[
n_x=4,\quad n_y=5,\quad \bar{x}=3.5,\quad \bar{y}=6.8,
\]
\[
s_x^2=7,\qquad s_y^2=25.7.
\]

For the pooled Student test,

\[
s_p^2=
\frac{(n_x-1)s_x^2+(n_y-1)s_y^2}{n_x+n_y-2}
=
\frac{619}{35},
\]

so

\[
SE_{\mathrm{Student}}
=
\sqrt{\frac{5571}{700}},
\qquad
df=7,
\]
\[
t_{\mathrm{Student}}
=
\frac{3.5-6.8}{SE_{\mathrm{Student}}}
=
-1.1697589605761274.
\]

For Welch's test,

\[
SE_{\mathrm{Welch}}^2=
\frac{7}{4}+\frac{25.7}{5}
=
\frac{689}{100},
\]

and the Welch-Satterthwaite degrees of freedom are

\[
df_{\mathrm{Welch}}
=
\frac{(s_x^2/n_x+s_y^2/n_y)^2}
{(s_x^2/n_x)^2/(n_x-1)+(s_y^2/n_y)^2/(n_y-1)}
=
6.225250467714582.
\]

This gives

\[
t_{\mathrm{Welch}}=-1.2571998743031079.
\]

The two-sided p-values are then obtained only from the t-distribution tail
\`2 * stats::pt(-abs(t), df)\`. No expected statistic or p-value is generated
with \`stats::t.test()\` or a second SciPy call.

The installed-backend test compares \`pharma_scipy_ttest()\` with these manually
constructed targets for both \`equal_var = TRUE\` and \`FALSE\`. Additional
invariance checks swap the groups, apply positive and negative affine
transformations, and exercise a case in which one group has exactly zero sample
variance while the other remains variable.

The reference covers finite numeric two-sample Student and Welch calculations.
It does not establish normality, independence, robustness to outliers,
appropriateness of equal-variance pooling, one-sided alternatives, trimmed/Yuen
tests, permutation tests, or a study-specific analysis population.


## R help

Full arguments and return values: [`pharma_scipy_ttest()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_scipy_ttest.Rd). In an installed package, run `help("pharma_scipy_ttest", package = "PharmaStatsR")`.
