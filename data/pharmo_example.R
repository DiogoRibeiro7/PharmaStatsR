set.seed(123)
subjects <- 100L
times <- 0:4
n <- subjects * length(times)

pharmo_example <- data.frame(
  SubjectID = rep(seq_len(subjects), each = length(times)),
  Time = rep(times, times = subjects)
)

pharmo_example$WT <- rep(round(stats::rnorm(subjects, mean = 70, sd = 7), 1), each = length(times))
pharmo_example$AGE <- rep(base::sample(18:80, subjects, replace = TRUE), each = length(times))
pharmo_example$CRCL <- rep(round(stats::rnorm(subjects, mean = 90, sd = 15), 1), each = length(times))

pharmo_example$DV <- round(
  2 + 0.1 * (pharmo_example$WT - 70) -
    0.03 * (pharmo_example$AGE - 50) +
    0.02 * (pharmo_example$CRCL - 90) +
    stats::rnorm(n, 0, 1),
  2
)

# Keep only the exported dataset object.
rm(subjects, times, n)
