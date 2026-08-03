####################################################################
# 02_factor_analysis.R
#
# Question this answers: do the 33 survey measures actually collapse
# into a small number of distinct shopper motivations, or is the survey
# measuring one general "I care about groceries" tendency?
#
# Method: exploratory factor analysis, minimum residual extraction with
# an oblique rotation. The rotation is oblique rather than orthogonal
# because these motivations are expected to correlate. A shopper who
# cares about produce quality plausibly also cares about meat quality.
#
# The factor solution informs which items belong to which dimension.
# It does not produce the scores used later. See docs/methodology.md
# for why the two steps are kept separate.
#
# Produces: fa_input, fa_fit, loadings_table
####################################################################

# ── 1. Build the analysis matrix ─────────────────────────────────
fa_input_raw <- survey %>%
  filter(wave == REFERENCE_WAVE) %>%
  select(all_of(FA_ITEMS))

# ── 2. Impute missing answers with the item median ───────────────
# Item non response runs at roughly one percent. Median imputation is
# used rather than dropping rows, because dropping any respondent with
# a single blank would cost a meaningful share of the sample. The
# medians are stored so the same values can be applied to the second
# wave later.
item_medians <- sapply(fa_input_raw, median, na.rm = TRUE)

fa_input <- fa_input_raw %>%
  mutate(across(everything(),
                ~ if_else(is.na(.x), item_medians[cur_column()], .x)))

# Drop anything with no variance. A constant column carries no
# information and breaks the correlation matrix.
has_variance <- sapply(fa_input, function(x) length(unique(x)) > 1)
if (any(!has_variance)) {
  cat("Dropping zero variance items:",
      paste(names(has_variance)[!has_variance], collapse = ", "), "\n")
}
fa_input <- fa_input[, has_variance, drop = FALSE]

cat("Factor analysis on", nrow(fa_input), "respondents and",
    ncol(fa_input), "items.\n\n")

# ── 3. How many factors? ─────────────────────────────────────────
# Parallel analysis compares the eigenvalues from the real correlation
# matrix against eigenvalues from random data of the same size. Factors
# that beat the random baseline are worth keeping. This is a guide, not
# a verdict: the final count also has to produce factors a merchandising
# team can act on.
parallel_result <- fa.parallel(fa_input, fa = "fa", plot = FALSE,
                               show.legend = FALSE)
cat("Parallel analysis suggests", parallel_result$nfact, "factors.\n")
cat("Using", N_FACTORS, "factors (set in 00_config.R).\n\n")

# ── 4. Fit ───────────────────────────────────────────────────────
fa_fit <- fa(
  r        = fa_input,
  nfactors = N_FACTORS,
  rotate   = "oblimin",
  fm       = "minres",
  scores   = "regression"
)

cat("=== ROTATED FACTOR LOADINGS (values below 0.30 hidden) ===\n")
print(fa_fit$loadings, cutoff = 0.30, sort = TRUE)

cat("\nVariance explained by the retained factors:",
    percent(sum(fa_fit$Vaccounted["Proportion Var", ]), accuracy = 0.1), "\n")

# ── 5. Save the loadings for review ──────────────────────────────
loadings_table <- unclass(fa_fit$loadings) %>%
  as.data.frame() %>%
  tibble::rownames_to_column("item") %>%
  mutate(
    assigned_dimension = map_chr(item, function(i) {
      hit <- names(DIMENSION_ITEMS)[map_lgl(DIMENSION_ITEMS, ~ i %in% .x)]
      if (length(hit) == 0) "derived measure" else hit
    }),
    strongest_factor = apply(across(starts_with("MR")), 1,
                             function(r) names(r)[which.max(abs(r))])
  ) %>%
  arrange(assigned_dimension, item)

write_csv(loadings_table, file.path(PATH_OUTPUT, "factor_loadings.csv"))
cat("\nSaved:", file.path(PATH_OUTPUT, "factor_loadings.csv"), "\n\n")
