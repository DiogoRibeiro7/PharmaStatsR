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

## R help

Full arguments and return values: [`pharma_scipy_ttest()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_scipy_ttest.Rd). In an installed package, run `help("pharma_scipy_ttest", package = "PharmaStatsR")`.
