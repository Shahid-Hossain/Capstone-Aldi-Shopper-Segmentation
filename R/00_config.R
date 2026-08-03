####################################################################
# 00_config.R
# Shared settings, constants and item groupings.
# Sourced by every other script. Nothing here reads or writes data.
####################################################################

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(purrr)
  library(psych)
  library(nnet)
  library(forcats)
  library(ggplot2)
  library(scales)
})

# ── Paths ────────────────────────────────────────────────────────
# All paths are relative to the repository root. Open the .Rproj file
# or setwd() to the repository root before running.
PATH_DATA    <- "data/sample_survey_data.csv"
PATH_OUTPUT  <- "outputs_synthetic"

if (!dir.exists(PATH_OUTPUT)) dir.create(PATH_OUTPUT, recursive = TRUE)

# ── Analysis settings ────────────────────────────────────────────
REFERENCE_WAVE   <- 2025   # wave that defines the scoring parameters
COMPARISON_WAVE  <- 2021   # wave scored against those parameters
N_FACTORS        <- 5      # see docs/methodology.md on choosing this
RANDOM_SEED      <- 42

set.seed(RANDOM_SEED)

# ── The five motivation dimensions ───────────────────────────────
# Each dimension is measured by a set of survey items. A respondent's
# score on a dimension is the mean of their z scored answers to those
# items. Grouping was informed by the factor analysis in 02, then
# reviewed for business interpretability.
DIMENSION_ITEMS <- list(
  Price = c(
    "q5e_everyday_low_prices",
    "q5e_frequent_promotions",
    "q5e_weekly_ads",
    "q5e_store_coupons",
    "q5e_low_receipt_total"
  ),
  Quality = c(
    "q5e_product_quality",
    "q5e_produce_quality",
    "q5e_meat_quality",
    "q5e_store_brand_quality"
  ),
  Digital = c(
    "q5e_store_app",
    "q5e_accurate_web_prices",
    "q5e_loyalty_program",
    "q5e_curbside_pickup",
    "q5e_delivery"
  ),
  Selection = c(
    "q5e_product_selection",
    "q5e_national_brand_selection",
    "q5e_store_brand_selection",
    "q5e_one_stop_shop",
    "q5e_fresh_service_depts"
  ),
  Convenience = c(
    "q5e_quick_easy_shop",
    "q5e_clean_store"
  )
)

SEGMENT_LEVELS <- names(DIMENSION_ITEMS)

# ── Items entering the factor analysis ───────────────────────────
# All 21 importance items plus the derived behavioural measures.
FA_ITEMS <- c(
  unlist(DIMENSION_ITEMS, use.names = FALSE),
  "q5a_best_value_importance",
  "q7_compare_digital", "q7_compare_ads", "q7_compare_social", "q7_compare_own",
  "q8a_sale_focused", "q8a_regular_focused",
  "newq3_prefers_edlp", "newq4_focus_key_items",
  "q14_share_lowest_price"
)
# Note: q14_share_best_quality is deliberately excluded. Among the
# categories a respondent actually buys, the two shares sum to one, so
# including both makes the correlation matrix singular and the factor
# solution unstable. One of the pair carries all the information.

# ── Behavioural item groupings ───────────────────────────────────
Q7_DIGITAL <- c("q7_store_apps", "q7_store_websites", "q7_search_engine",
                "q7_price_comparison_sites", "q7_multi_store_apps",
                "q7_coupon_apps", "q7_ai_assistant")
Q7_ADS     <- c("q7_print_ads", "q7_digital_ads")
Q7_SOCIAL  <- c("q7_social_media", "q7_word_of_mouth")
Q7_OWN     <- c("q7_own_experience", "q7_receipts")

Q8A_SALE    <- c("q8a_national_brand_sale", "q8a_store_brand_sale")
Q8A_REGULAR <- c("q8a_store_brand_regular", "q8a_national_brand_regular")

# ── Demographic banding ──────────────────────────────────────────
# The survey captures income in 25 narrow bands. Those are collapsed
# into 8 reporting bands so that each cell holds enough respondents
# for the multinomial model to estimate a stable coefficient.
INCOME_BAND_MAP <- c(
  "Less than $5,000"   = "Under $25K",
  "$5,000-$9,999"      = "Under $25K",
  "$10,000-$14,999"    = "Under $25K",
  "$15,000-$19,999"    = "Under $25K",
  "$20,000-$24,999"    = "Under $25K",
  "$25,000-$29,999"    = "$25K to $49K",
  "$30,000-$34,999"    = "$25K to $49K",
  "$35,000-$39,999"    = "$25K to $49K",
  "$40,000-$44,999"    = "$25K to $49K",
  "$45,000-$49,999"    = "$25K to $49K",
  "$50,000-$54,999"    = "$50K to $74K",
  "$55,000-$59,999"    = "$50K to $74K",
  "$60,000-$64,999"    = "$50K to $74K",
  "$65,000-$69,999"    = "$50K to $74K",
  "$70,000-$74,999"    = "$50K to $74K",
  "$75,000-$79,999"    = "$75K to $99K",
  "$80,000-$84,999"    = "$75K to $99K",
  "$85,000-$89,999"    = "$75K to $99K",
  "$90,000-$94,999"    = "$75K to $99K",
  "$95,000-$99,999"    = "$75K to $99K",
  "$100,000-$124,999"  = "$100K to $124K",
  "$125,000-$149,999"  = "$125K to $149K",
  "$150,000-$199,999"  = "$150K plus",
  "$200,000-$249,999"  = "$150K plus",
  "$250,000 or more"   = "$150K plus"
)

# Seven reporting bands, not eight. The survey's top band ($250,000 or
# more) holds too few respondents to estimate a stable coefficient
# across five outcomes, so it is folded into $150K plus. Reporting a
# coefficient from a cell of twenty five people would be reporting noise.
INCOME_LEVELS <- c("Under $25K", "$25K to $49K", "$50K to $74K",
                   "$75K to $99K", "$100K to $124K", "$125K to $149K",
                   "$150K plus")

AGE_LEVELS <- c("18-24", "25-36", "37-56", "57-65", "66+")

# ── Chart styling ────────────────────────────────────────────────
SEGMENT_COLORS <- c(
  Price       = "#E74C3C",
  Quality     = "#3498DB",
  Digital     = "#2ECC71",
  Selection   = "#F39C12",
  Convenience = "#9B59B6"
)

theme_report <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title      = element_text(face = "bold", size = base_size + 2),
      plot.subtitle   = element_text(color = "grey45", size = base_size - 2),
      panel.grid.minor = element_blank()
    )
}

# ── Small helpers ────────────────────────────────────────────────

# Survey exports store scale answers as labelled strings, for example
# "4 - Very important". Pull the leading number out and return NA when
# the answer is missing or unlabelled.
parse_scale <- function(x) {
  suppressWarnings(as.numeric(str_extract(as.character(x), "^[0-9]+")))
}

yes_no_to_binary <- function(x) {
  case_when(x == "Yes" ~ 1, x == "No" ~ 0, TRUE ~ NA_real_)
}

# TRUE when any item in the group was answered Yes.
any_yes <- function(data, items) {
  as.integer(rowSums(data[items] == 1, na.rm = TRUE) > 0)
}

cat("Config loaded.", length(SEGMENT_LEVELS), "dimensions,",
    length(FA_ITEMS), "items in the factor analysis.\n")
