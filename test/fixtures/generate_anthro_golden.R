# Generates `anthro_golden.csv` — golden values asserted by
# `test/growth/anthro_cross_validation_test.exs`.
#
# Values come from the WHO's reference implementation of the Child Growth
# Standards z-scores, the R `anthro` package
# (https://github.com/WorldHealthOrganization/anthro). The z-score code and
# reference tables are sourced straight from a checkout of that repository
# instead of installing the package, because the published package depends on
# `survey`, which is only needed for prevalence estimates, not z-scores.
#
# Usage:
#   ANTHRO_REPO=/path/to/anthro Rscript test/fixtures/generate_anthro_golden.R
#
# Fixture design (see the test module for how each row is asserted):
#
# * Ages cover one row-set per month of age, k = 0..59, at day
#   `ceiling(k * 30.4375)`. That is the smallest day the app resolves to
#   month k (it computes `floor(day / 30.4375)`), so the app's month-indexed
#   reference row and R's day-indexed row sit at most one day apart on the
#   underlying WHO curves. Months >= 60 are outside the reference
#   implementation's domain (it returns NA), so they are not covered.
# * Indicators: weight, height, bmi, head_circumference.
# * Each row targets a z-score of +1.5 (unadjusted branch) or -4 / +4 (WHO
#   adjustment for values beyond ±3 SD). The measure value is derived by
#   inverting the LMS curve at the reference day, using R's own tables.
# * `expected_z` is the output of R's `anthro_zscores()`, rounded to 2
#   decimals by the reference implementation itself.
# * `lms_l`, `lms_m`, `lms_s` are the WHO day-table values R used, so the
#   test can assert formula equivalence independently of the app's own
#   (month-indexed) tables.

anthro_repo <- Sys.getenv("ANTHRO_REPO", "/opt/personal/anthro/_main")

source_files <- c(
  "R/anthro-package.R",
  "R/utils.R",
  "R/assertions.R",
  "R/z-score-helper.R",
  "R/z-score-length-for-age.R",
  "R/z-score-weight-for-age.R",
  "R/z-score-weight-for-lenhei.R",
  "R/z-score-bmi-for-age.R",
  "R/z-score-head-circumference-for-age.R",
  "R/z-score-arm-circumference-for-age.R",
  "R/z-score-triceps-skinfold-for-age.R",
  "R/z-score-subscapular-skinfold-for-age.R",
  "R/z-score.R"
)
for (f in source_files) {
  source(file.path(anthro_repo, f))
}
load(file.path(anthro_repo, "R", "sysdata.rda"))

days_in_month <- 30.4375
z_targets <- c(1.5, -4, 4)

indicators <- data.frame(
  indicator = c("weight", "height", "bmi", "head_circumference"),
  rcolumn = c("zwei", "zlen", "zbmi", "zhc"),
  standards = c(
    "growthstandards_weianthro",
    "growthstandards_lenanthro",
    "growthstandards_bmianthro",
    "growthstandards_hcanthro"
  ),
  stringsAsFactors = FALSE
)

genders <- data.frame(
  app = c("male", "female"),
  r = c(1L, 2L),
  stringsAsFactors = FALSE
)

# One age per month of age; ceiling guarantees floor(d / 30.4375) == k
ages <- data.frame(month = 0:59)
ages$day <- ceiling(ages$month * days_in_month)
stopifnot(all(floor(ages$day / days_in_month) == ages$month))

lookup <- function(standards, gender_int, day) {
  row <- standards[standards$age == day & standards$sex == gender_int, ]
  stopifnot(nrow(row) == 1)
  row
}

inverse_lms <- function(l, m, s, z) m * (1 + l * s * z)^(1 / l)

rows <- list()
i <- 0
for (gender_row in seq_len(nrow(genders))) {
  gender_app <- genders$app[gender_row]
  gender_r <- genders$r[gender_row]

  for (age_row in seq_len(nrow(ages))) {
    day <- ages$day[age_row]
    month <- ages$month[age_row]

    for (ind_row in seq_len(nrow(indicators))) {
      indicator <- indicators$indicator[ind_row]
      standards <- get(indicators$standards[ind_row])
      std <- lookup(standards, gender_r, day)
      l <- std$l
      m <- std$m
      s <- std$s

      measure_flag <- if (day < 731) "l" else "h"

      for (z in z_targets) {
        # guard against inverting the LMS curve outside its support
        stopifnot(1 + l * s * z > 0.01)
        measure <- inverse_lms(l, m, s, z)
        stopifnot(is.finite(measure), measure > 0)

        weight <- NA_real_
        lenhei <- NA_real_
        headc <- NA_real_
        weight_kg <- NA_real_
        height_cm <- NA_real_

        if (indicator == "weight") {
          weight <- measure
        } else if (indicator == "height") {
          lenhei <- measure
        } else if (indicator == "bmi") {
          # R computes bmi internally as weight / (lenhei / 100)^2, the same
          # formula as Growth.Calculate.bmi/2, so hand it a weight/height pair
          # that reproduces the target bmi. Height uses the length median so
          # the pair stays plausible.
          height_cm <- lookup(growthstandards_lenanthro, gender_r, day)$m
          weight_kg <- measure * (height_cm / 100)^2
          lenhei <- height_cm
          weight <- weight_kg
        } else if (indicator == "head_circumference") {
          headc <- measure
        }

        out <- anthro_zscores(
          sex = gender_r,
          age = day,
          weight = weight,
          lenhei = lenhei,
          measure = measure_flag,
          headc = headc
        )
        expected_z <- out[[indicators$rcolumn[ind_row]]]
        stopifnot(length(expected_z) == 1, !is.na(expected_z))

        i <- i + 1
        rows[[i]] <- data.frame(
          gender = gender_app,
          age_in_days = day,
          age_in_months = month,
          indicator = indicator,
          lms_l = l,
          lms_m = m,
          lms_s = s,
          measure = measure,
          weight_kg = weight_kg,
          height_cm = height_cm,
          expected_z = expected_z,
          stringsAsFactors = FALSE
        )
      }
    }
  }
}

fixture <- do.call(rbind, rows)
output <- file.path("test", "fixtures", "anthro_golden.csv")
write.csv(fixture, output, row.names = FALSE, na = "")
cat("wrote", nrow(fixture), "rows to", normalizePath(output), "\n")
