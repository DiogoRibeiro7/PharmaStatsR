# Configuration and registries

These public utilities control process-local package settings and named functions. Their full argument and return descriptions are in the [export inventory](method-inventory.md), which links each installed R help page and representative test. They do not persist settings across R sessions or validate a statistical method.

## Package configuration

`pharma_config()` reads the current `pharma` R option as a named list, using defaults when the option is unset. Named arguments update the list and store it through `options(pharma = ...)`. The setter returns the updated list **invisibly**; the no-argument getter returns it visibly. Unknown names error. `log_level` is normalized to uppercase and checked against `DEBUG`, `INFO`, `WARN`, and `ERROR`; the other documented settings are stored without equivalent value validation. The default core count is at least one, even if detection fails. See [configuration help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_config.Rd).

```r
library(PharmaStatsR)

pharma_config()$log_level
with_pharma_config(list(log_level = "DEBUG"), {
  pharma_config()$log_level
})
```

`with_pharma_config()` returns the value of its expression and restores the prior configuration on exit, including an error exit. The changes are process-wide while the expression runs, so use care when other code in the same R process also reads or changes `options("pharma")`. See [temporary configuration help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/with_pharma_config.Rd).

## Named function registries

`pharma_register_plugin()` / `pharma_register_stat()` store a callable under a name in separate in-memory registries. Reusing a name replaces its earlier function. `pharma_list_plugins()` / `pharma_list_stats()` return character vectors of names; `pharma_run_plugin()` / `pharma_run_stat()` forward `...` and return the called function's result. An unknown name errors on a run. `pharma_unregister_plugin()` / `pharma_unregister_stat()` remove the entry if present and return invisible `TRUE`, including when absent. Registration checks that the name is a single character string and the value is a function; it does not inspect the function's statistical meaning. See the [plugin](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_register_plugin.Rd) and [statistic](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_register_stat.Rd) help for the individual entry points.

```r
pharma_register_stat("example_mean", mean)
pharma_run_stat("example_mean", 1:4)
pharma_list_stats()
pharma_unregister_stat("example_mean")
```

Registry contents last only as long as the package namespace in the current R process. Caller-supplied functions are responsible for their own input checks, reproducibility, and analysis assumptions. `pharma_greeting()` simply returns a character greeting; see its [R help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_greeting.Rd).
