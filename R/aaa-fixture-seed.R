# Keep generated example data stable without changing the caller's RNG state.
.pharma_fixture_seed <- function(seed, generate) {
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) {
    old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  }
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv,
                      inherits = FALSE)) {
      rm(".Random.seed", envir = .GlobalEnv)
    }
  })

  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion",
           sample.kind = "Rejection")
  generate()
}
