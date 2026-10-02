# Regenerate the numeric response columns stored in R/data-pharma_*.R.
# Run in a separate process with: Rscript data-raw/generate-fixture-responses.R
# This script prints the vectors for review; it does not rewrite package source.

set.seed(123, kind = "Mersenne-Twister", normal.kind = "Inversion")
dose <- rep(c(0, 10, 20, 50, 100), each = 6)
subject <- rep(seq_len(6), times = 5)
subject_intercept <- rnorm(6, sd = 0.15)
dose_response <- 1 + subject_intercept[subject] +
  (4 * dose) / (20 + dose) + rnorm(length(dose), sd = 0.1)

set.seed(123, kind = "Mersenne-Twister", normal.kind = "Inversion")
latin_square_response <- rnorm(16, mean = 5, sd = 0.3)

cat("pharma_dose_response$response:\n")
dput(dose_response)
cat("pharma_latin_square$response:\n")
dput(latin_square_response)
