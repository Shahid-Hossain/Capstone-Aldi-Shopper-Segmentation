####################################################################
# 03_segment_scoring.R
#
# Turns 21 importance ratings into one segment label per respondent.
#
# The problem this solves: nearly everyone says everything is important.
# Raw scores put most of the sample in the top two boxes on every item,
# so the absolute rating tells you very little. What separates shoppers
# is which motivation they rate highly relative to the average shopper.
#
# So each item is z scored, the z scores are averaged within a dimension,
# and each respondent is assigned to whichever dimension they stand out
# on most. Every respondent lands in exactly one segment.
#
# The means and standard deviations come from the reference wave only,
# then get applied unchanged to the comparison wave. That is what makes
# a year over year comparison meaningful: both waves are measured on the
# same ruler, so a shift in the mix is a real shift and not an artefact
# of rescaling each wave against itself.
#
# Produces: scoring_params, scored, segment_counts
####################################################################

all_items <- unlist(DIMENSION_ITEMS, use.names = FALSE)

# ── 1. Learn the scoring parameters from the reference wave ──────
reference <- survey %>% filter(wave == REFERENCE_WAVE)

scoring_params <- tibble(
  item = all_items,
  mean = sapply(all_items, function(v) mean(reference[[v]], na.rm = TRUE)),
  sd   = sapply(all_items, function(v) sd(reference[[v]],   na.rm = TRUE))
)

if (any(scoring_params$sd == 0 | is.na(scoring_params$sd))) {
  stop("An item has zero or missing variance in the reference wave. ",
       "It cannot be z scored. Check the item list in 00_config.R.")
}

write_csv(scoring_params, file.path(PATH_OUTPUT, "scoring_parameters.csv"))

# ── 2. Score every respondent in both waves ──────────────────────
score_dimension <- function(data, items) {
  z <- map_dfc(items, function(v) {
    p <- scoring_params[scoring_params$item == v, ]
    tibble(!!v := (data[[v]] - p$mean) / p$sd)
  })
  rowMeans(z, na.rm = TRUE)
}

dimension_scores <- map_dfc(
  names(DIMENSION_ITEMS),
  function(dim) {
    tibble(!!paste0(dim, "_z") := score_dimension(survey, DIMENSION_ITEMS[[dim]]))
  }
)

# ── 3. Assign each respondent to their strongest dimension ───────
z_matrix <- as.matrix(dimension_scores)
colnames(z_matrix) <- names(DIMENSION_ITEMS)

top_segment <- apply(z_matrix, 1, function(z) {
  if (all(is.na(z))) return(NA_character_)
  names(z)[which.max(z)]
})

# How far ahead is the winning dimension? A respondent whose top two
# scores are almost tied is only weakly assigned, and that is worth
# knowing before anyone builds a campaign on the label.
assignment_margin <- apply(z_matrix, 1, function(z) {
  if (sum(!is.na(z)) < 2) return(NA_real_)
  sorted <- sort(z, decreasing = TRUE)
  sorted[1] - sorted[2]
})

scored <- survey %>%
  bind_cols(dimension_scores) %>%
  mutate(
    segment           = factor(top_segment, levels = SEGMENT_LEVELS),
    assignment_margin = assignment_margin
  )

# ── 4. Report ────────────────────────────────────────────────────
segment_counts <- scored %>%
  count(wave, segment) %>%
  group_by(wave) %>%
  mutate(share = n / sum(n)) %>%
  ungroup()

cat("=== SEGMENT SIZES BY WAVE ===\n")
segment_counts %>%
  mutate(share = percent(share, accuracy = 0.1)) %>%
  pivot_wider(names_from = wave, values_from = c(n, share)) %>%
  as.data.frame() %>%
  print(row.names = FALSE)

weak <- mean(scored$assignment_margin < 0.15, na.rm = TRUE)
cat("\nRespondents whose top two dimensions are within 0.15 z:",
    percent(weak, accuracy = 0.1),
    "\nThese are genuinely mixed shoppers rather than clean segment members.\n")

write_csv(
  scored %>% select(respondent_id, wave, ends_with("_z"),
                    segment, assignment_margin,
                    income_band, age_band, kids_flag, gender_cat),
  file.path(PATH_OUTPUT, "respondent_segments.csv")
)
cat("\nSaved:", file.path(PATH_OUTPUT, "respondent_segments.csv"), "\n\n")
