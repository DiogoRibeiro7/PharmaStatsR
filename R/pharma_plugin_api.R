#' Register a custom PharmaTestSuite plugin
#'
#' Allows users to add their own statistical tests or helpers to the
#' PharmaTestSuite environment. Registered plugins can be listed and
#' executed via convenience wrappers.
#'
#' @param name Character string giving the plugin name.
#' @param fun Function implementing the plugin.
#'
#' @return Invisible `TRUE` on success.
#' @examples
#' my_plugin <- function(x) mean(x)
#' pharma_register_plugin("mean_plugin", my_plugin)
#' pharma_run_plugin("mean_plugin", 1:10)
#' pharma_unregister_plugin("mean_plugin")
#' @export
pharma_register_plugin <- function(name, fun) {
  if (!is.character(name) || length(name) != 1) {
    stop("'name' must be a single character string")
  }
  if (!is.function(fun)) {
    stop("'fun' must be a function")
  }
  assign(name, fun, envir = .pharma_plugins_env)
  invisible(TRUE)
}

#' Unregister a PharmaTestSuite plugin
#'
#' Removes a previously registered plugin from the internal environment.
#'
#' @param name Character string of the plugin to remove.
#'
#' @return Invisible `TRUE` if the plugin was removed.
#' @examples
#' pharma_unregister_plugin("mean_plugin")
#' @export
pharma_unregister_plugin <- function(name) {
  if (exists(name, envir = .pharma_plugins_env, inherits = FALSE)) {
    rm(list = name, envir = .pharma_plugins_env)
  }
  invisible(TRUE)
}

#' List registered PharmaTestSuite plugins
#'
#' @return Character vector of plugin names.
#' @examples
#' pharma_list_plugins()
#' @export
pharma_list_plugins <- function() {
  ls(envir = .pharma_plugins_env)
}

#' Execute a registered plugin
#'
#' Runs the specified plugin function with the provided arguments.
#'
#' @param name Character string of the plugin to run.
#' @param ... Arguments passed to the plugin function.
#'
#' @return Result returned by the plugin function.
#' @examples
#' pharma_register_plugin("mean_plugin", mean)
#' pharma_run_plugin("mean_plugin", 1:5)
#' @export
pharma_run_plugin <- function(name, ...) {
  if (!exists(name, envir = .pharma_plugins_env, inherits = FALSE)) {
    stop("Plugin not registered: ", name)
  }
  fun <- get(name, envir = .pharma_plugins_env)
  fun(...)
}

# internal environment holding plugin functions
.pharma_plugins_env <- new.env(parent = emptyenv())

#' Register a custom statistical method
#'
#' Extend PharmaTestSuite with bespoke statistical routines that can be
#' invoked through `pharma_run_stat()`.
#'
#' @inheritParams pharma_register_plugin
#'
#' @return Invisible `TRUE` on success.
#' @examples
#' pharma_register_stat("mean_method", mean)
#' pharma_run_stat("mean_method", 1:3)
#' pharma_unregister_stat("mean_method")
#' @export
pharma_register_stat <- function(name, fun) {
  if (!is.character(name) || length(name) != 1) {
    stop("`name` must be a single character string")
  }
  if (!is.function(fun)) {
    stop("`fun` must be a function")
  }
  assign(name, fun, envir = .pharma_stat_env)
  invisible(TRUE)
}

#' Unregister a statistical method
#'
#' @inheritParams pharma_unregister_plugin
#'
#' @return Invisible `TRUE` whether or not the method existed.
#' @export
pharma_unregister_stat <- function(name) {
  if (exists(name, envir = .pharma_stat_env, inherits = FALSE)) {
    rm(list = name, envir = .pharma_stat_env)
  }
  invisible(TRUE)
}

#' List registered statistical methods
#'
#' @return Character vector of registered method names.
#' @examples
#' pharma_list_stats()
#' @export
pharma_list_stats <- function() {
  ls(envir = .pharma_stat_env)
}

#' Execute a registered statistical method
#'
#' @param name Character string of the method to execute.
#' @param ... Arguments passed to the registered method.
#'
#' @return Result returned by the method.
#' @examples
#' pharma_register_stat("mean_method", mean)
#' pharma_run_stat("mean_method", 1:10)
#' @export
pharma_run_stat <- function(name, ...) {
  if (!exists(name, envir = .pharma_stat_env, inherits = FALSE)) {
    stop("Statistical method not registered: ", name)
  }
  fun <- get(name, envir = .pharma_stat_env)
  fun(...)
}

# internal environment holding statistical methods
.pharma_stat_env <- new.env(parent = emptyenv())
