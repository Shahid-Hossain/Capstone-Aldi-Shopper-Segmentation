####################################################################
# 04_multinomial_model.R
#
# Question this answers: the segments exist, but can you find them?
# A segment is only useful commercially if it maps onto something a
# retailer can target. So the model asks whether income, age, children
# in the household and gender predict which segment a shopper falls in.
#
# Method: multinomial logistic regression. The outcome has five
# unordered categories, so an ordinary logistic regression will not
# work and treating segment as a number would invent an order that is
# not there.
#
# Price is the reference category. Every coefficient therefore reads as
# "compared with a Price shopper who is otherwise identical, how much
# more or less likely is this person to be in segment X?"
#
# A caution worth stating plainly: the outcome variable was itself
# derived from the same respondents' survey answers, so this is a
# description of who the segments are, not a causal claim about what
# makes someone price sensitive.
#
# Produces: model_data, mnl_fit, model_results
####################################################################

# ── 1. Model frame ───────────────────────────────────────────────
model_data <- scored %>%
  filter(wave == REFERENCE_WAVE) %>%
  filter(!is.na(segment), !is.na(income_band),
         !is.na(age_band), !is.na(gender_cat)) %>%
  mutate(segment = relevel(fct_drop(segment), ref = "Price"))

dropped <- sum(scored$wave == REFERENCE_WAVE) - nrow(model_data)
cat("Model sample:", nrow(model_data), "respondents")
if (dropped > 0) cat(" |", dropped, "dropped for missing demographics")
cat("\n\n")

cat("Respondents per income band:\n")
print(table(model_data$income_band))
cat("\n")

small_cells <- names(which(table(model_data$income_band) < 30))
if (length(small_cells) > 0) {
  cat("Caution: fewer than 30 respondents in",
      paste(small_cells, collapse = ", "),
      "\nCoefficients for these bands carry wide standard errors.\n\n")
}

# ── 2. Fit ───────────────────────────────────────────────────────
mnl_fit <- multinom(
  segment ~ income_band + age_band + kids_flag + gender_cat,
  data  = model_data,
  Hess  = TRUE,
  trace = FALSE
)

# ── 3. Tidy the output ───────────────────────────────────────────
# multinom returns matrices rather than a tidy frame, so coefficients,
# standard errors and p values get reshaped and joined into one table.
to_long <- function(mat, value_name) {
  mat %>%
    as.data.frame() %>%
    mutate(outcome = rownames(mat)) %>%
    pivot_longer(-outcome, names_to = "predictor", values_to = value_name)
}

coef_mat <- coef(mnl_fit)
se_mat   <- summary(mnl_fit)$standard.errors
z_mat    <- coef_mat / se_mat
p_mat    <- 2 * (1 - pnorm(abs(z_mat)))

model_results <- to_long(coef_mat, "coefficient") %>%
  left_join(to_long(se_mat, "std_error"), by = c("outcome", "predictor")) %>%
  left_join(to_long(z_mat,  "z_value"),   by = c("outcome", "predictor")) %>%
  left_join(to_long(p_mat,  "p_value"),   by = c("outcome", "predictor")) %>%
  mutate(
    odds_ratio  = exp(coefficient),
    significant = p_value < 0.05,
    predictor_group = case_when(
      str_starts(predictor, "income_band") ~ "Income",
      str_starts(predictor, "age_band")    ~ "Age",
      str_starts(predictor, "kids_flag")   ~ "Children",
      str_starts(predictor, "gender_cat")  ~ "Gender",
      TRUE                                 ~ "Intercept"
    ),
    predictor_label = predictor %>%
      str_remove("^income_band") %>%
      str_remove("^age_band") %>%
      str_remove("^kids_flag") %>%
      str_remove("^gender_cat")
  ) %>%
  arrange(outcome, predictor_group, predictor)

# ── 4. Model fit ─────────────────────────────────────────────────
null_fit <- multinom(segment ~ 1, data = model_data, trace = FALSE)
mcfadden <- 1 - (deviance(mnl_fit) / 2) / (deviance(null_fit) / 2)

predicted <- predict(mnl_fit, model_data)
accuracy  <- mean(predicted == model_data$segment)
baseline  <- max(prop.table(table(model_data$segment)))

cat("=== MODEL FIT ===\n")
cat("McFadden pseudo R squared:", round(mcfadden, 3), "\n")
cat("Correctly classified:     ", percent(accuracy, accuracy = 0.1), "\n")
cat("Always guessing the largest segment would give:",
    percent(baseline, accuracy = 0.1), "\n")
cat("Demographics move the needle, but they do not determine segment",
    "membership on their own.\n\n")

cat("=== SIGNIFICANT EFFECTS (p < 0.05, intercepts excluded) ===\n")
model_results %>%
  filter(significant, predictor != "(Intercept)") %>%
  transmute(
    segment_vs_price = outcome,
    predictor        = predictor_label,
    odds_ratio       = round(odds_ratio, 2),
    p_value          = signif(p_value, 3)
  ) %>%
  arrange(segment_vs_price, desc(odds_ratio)) %>%
  as.data.frame() %>%
  print(row.names = FALSE)

write_csv(model_results, file.path(PATH_OUTPUT, "multinomial_results.csv"))
cat("\nSaved:", file.path(PATH_OUTPUT, "multinomial_results.csv"), "\n\n")
