####################################################################
# 01_prepare_data.R
#
# Reads the raw survey export and turns it into a modelling table.
#
# Three things happen here:
#   1. Scale answers stored as text ("4 - Very important") become numbers.
#   2. Yes and No answers become 1 and 0, then roll up into behavioural flags.
#   3. Free ranging demographics collapse into the reporting bands.
#
# Produces: survey  (one row per respondent, both waves)
####################################################################

raw <- read_csv(PATH_DATA, show_col_types = FALSE)

cat("Loaded", nrow(raw), "respondents |",
    paste(sprintf("%s: %s", names(table(raw$wave)), table(raw$wave)),
          collapse = " | "), "\n")

# ── 1. Importance scales to numbers ──────────────────────────────
scale_cols <- c(unlist(DIMENSION_ITEMS, use.names = FALSE),
                "q5a_best_value_importance")

survey <- raw %>%
  mutate(across(all_of(scale_cols), parse_scale))

# ── 2. Yes and No answers to flags ───────────────────────────────
binary_cols <- c(Q7_DIGITAL, Q7_ADS, Q7_SOCIAL, Q7_OWN,
                 Q8A_SALE, Q8A_REGULAR)

survey <- survey %>%
  mutate(across(all_of(binary_cols), yes_no_to_binary))

# Roll the individual methods up into four behavioural flags. A shopper
# who uses any digital method to compare prices is a digital comparer,
# regardless of how many methods they use.
survey <- survey %>%
  mutate(
    q7_compare_digital  = any_yes(., Q7_DIGITAL),
    q7_compare_ads      = any_yes(., Q7_ADS),
    q7_compare_social   = any_yes(., Q7_SOCIAL),
    q7_compare_own      = any_yes(., Q7_OWN),
    q8a_sale_focused    = any_yes(., Q8A_SALE),
    q8a_regular_focused = any_yes(., Q8A_REGULAR)
  )

# ── 3. Two forced choice questions to flags ──────────────────────
survey <- survey %>%
  mutate(
    newq3_prefers_edlp = case_when(
      str_detect(newq3_pricing_preference, "^Every-day low") ~ 1,
      str_detect(newq3_pricing_preference, "^Regular item")  ~ 0,
      TRUE ~ NA_real_
    ),
    newq4_focus_key_items = case_when(
      str_detect(newq4_price_focus, "^The prices of key") ~ 1,
      str_detect(newq4_price_focus, "^The cost of my")    ~ 0,
      TRUE ~ NA_real_
    )
  )

# ── 4. Category tradeoff shares ──────────────────────────────────
# For 17 grocery categories the respondent chooses lowest price or best
# quality, or says they do not buy the category. The useful measure is
# the share of categories they actually buy where they chose each side,
# because respondents differ in how many categories they buy at all.
q14_cols <- names(survey)[str_starts(names(survey), "q14_")]

q14_answered   <- rowSums(survey[q14_cols] != "I don't buy this category", na.rm = TRUE)
q14_low_price  <- rowSums(survey[q14_cols] == "The lowest price", na.rm = TRUE)
q14_quality    <- rowSums(survey[q14_cols] == "Best quality", na.rm = TRUE)

survey <- survey %>%
  mutate(
    q14_categories_bought  = q14_answered,
    q14_share_lowest_price = if_else(q14_answered > 0, q14_low_price / q14_answered, NA_real_),
    q14_share_best_quality = if_else(q14_answered > 0, q14_quality   / q14_answered, NA_real_)
  )

# ── 5. Demographic bands ─────────────────────────────────────────
survey <- survey %>%
  mutate(
    income_band = factor(unname(INCOME_BAND_MAP[household_income]),
                         levels = INCOME_LEVELS),
    age_band    = factor(age_range, levels = AGE_LEVELS),
    kids_flag   = factor(has_kids_under_18,
                         levels = c("No kids < 18", "Have kids < 18")),
    # Roughly three percent of respondents answer something other than
    # female or male. Split across four outcome segments that leaves
    # cells of a handful of people, which produces coefficients in the
    # millions rather than anything interpretable. The categories are
    # kept in the data and combined only for modelling.
    gender_cat  = factor(
      if_else(gender %in% c("Female", "Male"), gender, "Other or not stated"),
      levels = c("Female", "Male", "Other or not stated")
    )
  )

# ── Quality checks ───────────────────────────────────────────────
missing_income <- sum(is.na(survey$income_band))
if (missing_income > 0) {
  cat("Note:", missing_income,
      "respondents have an income value outside the band map.\n")
}

cat("Prepared", nrow(survey), "rows and",
    length(FA_ITEMS), "analysis variables.\n")
cat("Median categories bought per respondent:",
    median(survey$q14_categories_bought), "of", length(q14_cols), "\n\n")
