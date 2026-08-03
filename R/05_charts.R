####################################################################
# 05_charts.R
#
# Six charts, each answering one question a stakeholder actually asked.
#
#   1. How big is each segment?
#   2. Does the mix change with household income?
#   3. Does it change with age?
#   4. Do households with children differ?
#   5. Which demographics predict segment membership, and how strongly?
#   6. Has the mix shifted between the two waves?
#
# Every chart carries its numbers as labels. Stakeholders read these in
# slide decks, not in an interactive session, and a bar without a number
# invites people to guess.
#
# Produces: PNG files in outputs_synthetic/
####################################################################

save_chart <- function(plot, filename, width, height) {
  path <- file.path(PATH_OUTPUT, filename)
  ggsave(path, plot, width = width, height = height, dpi = 180)
  cat("Saved:", path, "\n")
}

reference_scored <- scored %>% filter(wave == REFERENCE_WAVE, !is.na(segment))

# ── Chart 1: segment sizes ───────────────────────────────────────
chart1_data <- reference_scored %>%
  count(segment) %>%
  mutate(share = n / sum(n))

chart1 <- ggplot(chart1_data,
                 aes(x = reorder(segment, -n), y = n, fill = segment)) +
  geom_col(width = 0.65, show.legend = FALSE) +
  geom_text(aes(label = paste0(comma(n), "\n(", percent(share, 0.1), ")")),
            vjust = -0.3, fontface = "bold", size = 4) +
  scale_fill_manual(values = SEGMENT_COLORS) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.18)), labels = comma) +
  labs(
    title    = paste0("Shopper motivation segments, ", REFERENCE_WAVE),
    subtitle = "Each respondent is assigned to the motivation they rate highest relative to the average shopper",
    x = NULL, y = "Respondents"
  ) +
  theme_report() +
  theme(panel.grid.major.x = element_blank())

save_chart(chart1, "chart1_segment_sizes.png", 10, 6)

# ── Chart 2: segment mix by income ───────────────────────────────
chart2 <- reference_scored %>%
  filter(!is.na(income_band)) %>%
  count(income_band, segment) %>%
  group_by(income_band) %>%
  mutate(share = n / sum(n)) %>%
  ungroup() %>%
  ggplot(aes(x = income_band, y = share, fill = segment)) +
  geom_col(position = "fill") +
  geom_text(aes(label = if_else(share > 0.07, percent(share, 1), "")),
            position = position_fill(vjust = 0.5),
            color = "white", fontface = "bold", size = 3.2) +
  scale_fill_manual(values = SEGMENT_COLORS, name = "Segment") +
  scale_y_continuous(labels = percent_format()) +
  labs(
    title    = "Segment mix by household income",
    subtitle = "Quality motivation rises with income while price motivation falls",
    x = "Household income", y = "Share of respondents"
  ) +
  theme_report() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1),
        panel.grid.major.x = element_blank())

save_chart(chart2, "chart2_income_mix.png", 13, 6)

# ── Chart 3: segment mix by age ──────────────────────────────────
chart3 <- reference_scored %>%
  filter(!is.na(age_band)) %>%
  count(age_band, segment) %>%
  group_by(age_band) %>%
  mutate(share = n / sum(n)) %>%
  ungroup() %>%
  ggplot(aes(x = age_band, y = share, fill = segment)) +
  geom_col(position = "fill") +
  geom_text(aes(label = if_else(share > 0.07, percent(share, 1), "")),
            position = position_fill(vjust = 0.5),
            color = "white", fontface = "bold", size = 3.4) +
  scale_fill_manual(values = SEGMENT_COLORS, name = "Segment") +
  scale_y_continuous(labels = percent_format()) +
  labs(
    title    = "Segment mix by age group",
    subtitle = "Digital motivation concentrates in younger shoppers",
    x = "Age band", y = "Share of respondents"
  ) +
  theme_report() +
  theme(panel.grid.major.x = element_blank())

save_chart(chart3, "chart3_age_mix.png", 10, 6)

# ── Chart 4: households with and without children ────────────────
chart4 <- reference_scored %>%
  filter(!is.na(kids_flag)) %>%
  count(kids_flag, segment) %>%
  group_by(kids_flag) %>%
  mutate(share = n / sum(n)) %>%
  ungroup() %>%
  ggplot(aes(x = segment, y = share * 100, fill = kids_flag)) +
  geom_col(position = "dodge", width = 0.65) +
  geom_text(aes(label = paste0(round(share * 100, 1), "%")),
            position = position_dodge(width = 0.65),
            vjust = -0.4, size = 3.2, fontface = "bold") +
  scale_fill_manual(values = c("No kids < 18"   = "#2980B9",
                               "Have kids < 18" = "#E67E22"),
                    name = NULL) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15)),
                     labels = function(x) paste0(x, "%")) +
  labs(
    title    = "Segment mix: households with and without children under 18",
    x = "Segment", y = "Share of group"
  ) +
  theme_report() +
  theme(panel.grid.major.x = element_blank(), legend.position = "top")

save_chart(chart4, "chart4_children_mix.png", 11, 6)

# ── Chart 5: multinomial coefficients ────────────────────────────
# A heatmap rather than a coefficient table, because the audience needs
# to see the pattern across four segments at once. Green means more
# likely than a Price shopper, red means less likely. Values are capped
# at plus or minus 1.5 so that one extreme cell does not flatten the
# colour scale for everything else.
heatmap_data <- model_results %>%
  filter(predictor != "(Intercept)",
         predictor_group %in% c("Income", "Age", "Children")) %>%
  mutate(
    stars = case_when(
      p_value < 0.001 ~ "***",
      p_value < 0.01  ~ "**",
      p_value < 0.05  ~ "*",
      TRUE            ~ ""
    ),
    cell_label   = paste0(sprintf("%.2f", coefficient), stars),
    coef_capped  = pmin(pmax(coefficient, -1.5), 1.5)
  )

row_order <- c(
  rev(INCOME_LEVELS[-1]),
  rev(AGE_LEVELS[-1]),
  "Have kids < 18"
)
row_order <- row_order[row_order %in% heatmap_data$predictor_label]

heatmap_data <- heatmap_data %>%
  mutate(predictor_label = factor(predictor_label, levels = row_order),
         outcome = factor(outcome, levels = setdiff(SEGMENT_LEVELS, "Price")))

chart5 <- ggplot(heatmap_data,
                 aes(x = outcome, y = predictor_label, fill = coef_capped)) +
  geom_tile(color = "white", linewidth = 0.7) +
  geom_text(aes(label = cell_label,
                color = abs(coef_capped) > 0.8),
            size = 3.2, fontface = "bold", show.legend = FALSE) +
  scale_color_manual(values = c("TRUE" = "white", "FALSE" = "grey10")) +
  scale_fill_gradientn(
    colours = c("#C0392B", "#E8A89C", "#F5F5DC", "#A9D18E", "#1E7E34"),
    values  = rescale(c(-1.5, -0.4, 0, 0.4, 1.5)),
    limits  = c(-1.5, 1.5),
    oob     = squish,
    name    = "Coefficient\nvs Price"
  ) +
  labs(
    title    = "Who belongs to each segment, compared with price shoppers",
    subtitle = paste("Green means more likely than a Price shopper, red means less likely.",
                     "\nReference groups: Price segment, under $25K, ages 18 to 24, no children.",
                     "\n* p<0.05   ** p<0.01   *** p<0.001"),
    x = "Segment", y = NULL
  ) +
  theme_report() +
  theme(axis.text.x = element_text(face = "bold", size = 11),
        panel.grid = element_blank())

save_chart(chart5, "chart5_model_heatmap.png", 11, 8)

# ── Chart 6: wave comparison ─────────────────────────────────────
chart6_data <- scored %>%
  filter(!is.na(segment)) %>%
  count(wave, segment) %>%
  group_by(wave) %>%
  mutate(share = n / sum(n)) %>%
  ungroup() %>%
  mutate(wave = factor(wave, levels = c(COMPARISON_WAVE, REFERENCE_WAVE)))

chart6 <- ggplot(chart6_data, aes(x = segment, y = share * 100, fill = wave)) +
  geom_col(position = "dodge", width = 0.65) +
  geom_text(aes(label = paste0(round(share * 100, 1), "%\n(n=", comma(n), ")")),
            position = position_dodge(width = 0.65),
            vjust = -0.3, size = 3, fontface = "bold") +
  scale_fill_manual(values = setNames(c("#5D6D7E", "#2471A3"),
                                      c(COMPARISON_WAVE, REFERENCE_WAVE)),
                    name = "Wave") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.22)),
                     labels = function(x) paste0(x, "%")) +
  labs(
    title    = paste0("Segment mix, ", COMPARISON_WAVE, " compared with ", REFERENCE_WAVE),
    subtitle = paste0("Both waves scored with the same ", REFERENCE_WAVE,
                      " item parameters, so the shift is a real change in the mix"),
    x = "Segment", y = "Share of respondents"
  ) +
  theme_report() +
  theme(panel.grid.major.x = element_blank(), legend.position = "top")

save_chart(chart6, "chart6_wave_comparison.png", 12, 6)

cat("\nAll six charts written to", PATH_OUTPUT, "\n\n")
