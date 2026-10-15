# Illustrative example data

PharmaStatsR provides seven illustrative data frames: six namespace exports for
the original statistical examples and the additional `pharmo_example` dataset
loaded with `data()`. They contain **no patient records or measured
pharmaceutical outcomes**. Do not interpret fitted effects from these fixtures
as evidence about a drug or a real population.

## Six exported statistical fixtures

Four contain hand-entered values, while two have seeded generated responses.
Their response, dose, and follow-up values are unitless illustrations; the
binary labels have no specified clinical event definition.

| Data frame | Columns and stored types | Source and intended use |
| --- | --- | --- |
| [`pharma_sample`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_sample.Rd) (20 rows) | `subject`: integer 1–20; `treatment`: character A/B; `dose`: numeric 1/2; `response`: numeric; `outcome`: numeric 0/1. | Hand-entered values for simple two-group comparisons and row-level examples. Ten rows per group. A always has dose 1; B always has dose 2. The outcome is an arbitrary label. |
| [`pharma_repeated`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_repeated.Rd) (20 rows) | `subject`: integer 1–10; `condition`: character A/B; `response`: numeric. | Hand-entered paired values, one A and one B per subject, in subject order. Convert IDs and condition to factors for repeated ANOVA. |
| [`pharma_crossover`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_crossover.Rd) (20 rows) | `subject`: factor 1–10; `period`: factor 1/2; `treatment`: factor A/B; `response`: numeric; `outcome`: numeric 0/1. | Hand-entered two-period AB/BA illustration, with five subjects in each sequence and one row per subject-period. The outcome is an arbitrary label. |
| [`pharma_latin_square`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_latin_square.Rd) (16 rows) | `row`, `column`: factors 1–4; `treatment`: factor A–D; `response`: numeric. | Complete 4 × 4 Latin square, each treatment once per row and column. Seeded independent normal responses with mean 5 and SD 0.3 illustrate the additive ANOVA; no treatment effect was generated. |
| [`pharma_dose_response`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_dose_response.Rd) (30 rows) | `subject`: integer 1–6; `dose`: numeric 0/10/20/50/100; `response`: numeric. | One row per subject-dose pair. Seeded Emax response for nonlinear and repeated-subject fits: mean \(1 + 4d/(20+d)\), subject normal intercept SD 0.15, observation normal noise SD 0.1. |
| [`pharma_survival`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_survival.Rd) (30 rows) | `subject`: integer 1–30; `time`: positive numeric; `status`: numeric 0/1; `treatment`: character A/B. | Hand-entered time-to-event illustration, 15 rows per group. Status 1 is an unspecified example event; 0 means right censored. No time unit or real event meaning is supplied. |

The values live in `R/data-pharma_*.R`. The Latin square and dose-response responses were generated with seed 123 and the Mersenne-Twister/Inversion RNG settings, then stored as numeric values in those source files. Run `Rscript data-raw/generate-fixture-responses.R` in a separate process to reproduce them. Sourcing the package and loading an installed package do not draw random numbers for these fixtures. No fixture contains missing values; identifiers are complete and the designs above are checked in [fixture tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-simulated-data.R).

## Covariate workflow dataset

Load the seventh dataset explicitly:

```r
data("pharmo_example", package = "PharmaStatsR")
str(pharmo_example)
```

[`pharmo_example`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharmo_example.Rd)
has 500 complete rows: 100 subjects at five observation times, 0 through 4.
`SubjectID`, `Time`, and `AGE` are integers; `WT`, `CRCL`, and `DV` are numeric.
Weight, age, and creatinine clearance are constant within subject. Their
illustrative units are kg, years, and mL/min; no physical unit is specified for
`Time` or `DV`.

The [generation script](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/data/pharmo_example.R)
uses seed 123. Weight is sampled around 70 kg, age from 18–80 years, and
creatinine clearance around 90 mL/min. `DV` is a rounded linear function of
those covariates plus independent normal noise; it has no generated time trend,
subject random effect, or pharmacokinetic compartment model. The source script
sets the RNG seed and generates the values; `R CMD build` stores the result as
`pharmo_example.rda` in the source package. Sourcing the script directly changes
the caller's RNG state.

The dataset supports the [covariate quick start](quickstart.md#prepare-covariates-and-fit-a-random-intercept-model)
and [migration tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-covariate-migration.R).
It is not dosing data for the nonlinear SAEM example and does not establish
parameter recovery for a fitted random-intercept model.

## Choose a design that matches the question

For a group comparison or model diagnostic, fit `response ~ treatment` on `pharma_sample`. Since `treatment` and `dose` identify exactly the same split, a model with both terms is rank deficient; it cannot estimate their separate effects. Use `pharma_dose_response` for a single dose curve, and a genuinely crossed two-predictor dataset for a [response surface](response-surface.md).

For paired ANOVA, use `transform(pharma_repeated, subject = factor(subject), condition = factor(condition))` as in the [paired example](repeated-anova.md). For the two-period design, use the [crossover example](crossover.md); it cannot estimate carryover or establish bioequivalence. The [Latin square example](latin-square.md) has no replicate cells to estimate interactions. The [survival example](kaplan-meier.md) shows censoring syntax, not a clinical outcome or validated treatment comparison.
