# Data Dictionary

Every column in `data/sample_survey_data.csv`. The file is synthetic and matches the structure of the original survey export.

**Rows:** 3,200 respondents (2,000 in the 2025 wave, 1,200 in the 2021 wave)  
**Columns:** 64

---

## Identifiers and demographics

| Column | Holds | Values |
|---|---|---|
| `wave` | Survey wave | 2021; 2025 |
| `respondent_id` | Unique respondent identifier | 3200 distinct values |
| `gender` | Self reported gender | Another gender; Female; Male; Prefer not to answer |
| `age_range` | Age band | 5 distinct values |
| `household_income` | Household income, 25 narrow bands | 25 distinct values |
| `has_kids_under_18` | Children under 18 in the household | Have kids < 18; No kids < 18 |

---

## Importance ratings

Stored as labelled text, for example `4 - Very important`. Parsed to integers 1 through 5 by `parse_scale()` in `R/00_config.R`. Roughly one percent missing per item by design.

| Column | Item | Dimension |
|---|---|---|
| `q5a_best_value_importance` | Importance of getting the best overall value | Not assigned; enters the factor analysis only |
| `q5e_everyday_low_prices` | Everyday low prices on all items | Price |
| `q5e_frequent_promotions` | Frequent competitive sales and promotions | Price |
| `q5e_weekly_ads` | Weekly ads with competitive sales | Price |
| `q5e_store_coupons` | Offers store coupons | Price |
| `q5e_low_receipt_total` | Low total receipt amount | Price |
| `q5e_product_quality` | Great product quality | Quality |
| `q5e_produce_quality` | High quality produce | Quality |
| `q5e_meat_quality` | High quality fresh meat | Quality |
| `q5e_store_brand_quality` | High quality store brands | Quality |
| `q5e_product_selection` | Large product selection overall | Selection |
| `q5e_national_brand_selection` | Large selection of national brands | Selection |
| `q5e_store_brand_selection` | Large selection of store brands | Selection |
| `q5e_one_stop_shop` | Can get everything needed from one store | Selection |
| `q5e_fresh_service_depts` | Offers fresh service departments | Selection |
| `q5e_store_app` | Comprehensive store app | Digital |
| `q5e_accurate_web_prices` | Accurate product prices on the website | Digital |
| `q5e_loyalty_program` | Loyalty program with rewards | Digital |
| `q5e_curbside_pickup` | Offers curbside pickup | Digital |
| `q5e_delivery` | Offers delivery | Digital |
| `q5e_quick_easy_shop` | Quick and easy to shop | Convenience |
| `q5e_clean_store` | Store is clean | Convenience |

---

## Price comparison methods

Yes or No. Recoded to 1 and 0, then rolled into four behavioural flags in `R/01_prepare_data.R`.

| Column | Method | Rolls into |
|---|---|---|
| `q7_store_apps` | Prices on store apps | `q7_compare_digital` |
| `q7_store_websites` | Prices on store websites | `q7_compare_digital` |
| `q7_search_engine` | Search engine lookup | `q7_compare_digital` |
| `q7_price_comparison_sites` | Third party price comparison sites | `q7_compare_digital` |
| `q7_multi_store_apps` | Multi store grocery apps | `q7_compare_digital` |
| `q7_coupon_apps` | Couponing apps | `q7_compare_digital` |
| `q7_ai_assistant` | AI chat assistant | `q7_compare_digital` |
| `q7_print_ads` | Weekly print grocery ads | `q7_compare_ads` |
| `q7_digital_ads` | Weekly digital grocery ads | `q7_compare_ads` |
| `q7_word_of_mouth` | Word of mouth | `q7_compare_social` |
| `q7_social_media` | Social media | `q7_compare_social` |
| `q7_own_experience` | Own shopping experience | `q7_compare_own` |
| `q7_receipts` | Receipts | `q7_compare_own` |

---

## Weekly circular elements

Yes or No. Which parts of a weekly circular the respondent considers important.

| Column | Element | Rolls into |
|---|---|---|
| `q8a_national_brand_sale` | National brand products on sale | `q8a_sale_focused` |
| `q8a_store_brand_sale` | Store brand products on sale | `q8a_sale_focused` |
| `q8a_store_brand_regular` | Featured store brand products at regular prices | `q8a_regular_focused` |
| `q8a_national_brand_regular` | Featured national brand products at regular prices | `q8a_regular_focused` |

---

## Forced choice questions

| Column | Question | Recoded to |
|---|---|---|
| `newq3_pricing_preference` | Everyday low prices with fewer deals, or regular prices with many deals | `newq3_prefers_edlp` (1 = everyday low prices) |
| `newq4_price_focus` | Prices of key products, or total receipt cost | `newq4_focus_key_items` (1 = key products) |

---

## Category tradeoffs

For each of 17 grocery categories: `The lowest price`, `Best quality`, or `I don't buy this category`.

Summarised in `R/01_prepare_data.R` as the share of categories the respondent actually buys where they chose each side. Only `q14_share_lowest_price` enters the factor analysis, because the two shares sum to one and including both makes the correlation matrix singular.

Categories: `q14_alcoholic_beverages`, `q14_nonalcoholic_beverages`, `q14_condiments`, `q14_sweet_snacks`, `q14_savory_snacks`, `q14_pantry_items`, `q14_canned_goods`, `q14_dairy`, `q14_fresh_produce`, `q14_fresh_bread`, `q14_grab_and_go`, `q14_fresh_meat`, `q14_seafood`, `q14_frozen`, `q14_health_beauty`, `q14_cleaning_products`, `q14_paper_products`

---

## Columns created during the pipeline

These do not exist in the raw file. They are built in `R/01_prepare_data.R` and `R/03_segment_scoring.R`.

| Column | Created in | Holds |
|---|---|---|
| `q7_compare_digital` | `01` | 1 if any digital comparison method is used |
| `q7_compare_ads` | `01` | 1 if any weekly ad is used |
| `q7_compare_social` | `01` | 1 if social media or word of mouth is used |
| `q7_compare_own` | `01` | 1 if own experience or receipts are used |
| `q8a_sale_focused` | `01` | 1 if any sale element matters |
| `q8a_regular_focused` | `01` | 1 if any regular price element matters |
| `q14_categories_bought` | `01` | Count of categories the respondent buys, 0 to 17 |
| `q14_share_lowest_price` | `01` | Share of bought categories where lowest price was chosen |
| `q14_share_best_quality` | `01` | Share of bought categories where best quality was chosen |
| `income_band` | `01` | Income collapsed to 7 reporting bands |
| `age_band` | `01` | Age as an ordered factor |
| `kids_flag` | `01` | Children under 18, as a factor |
| `gender_cat` | `01` | Gender collapsed to 3 categories for modelling |
| `Price_z .. Convenience_z` | `03` | Mean z score across the items in each dimension |
| `segment` | `03` | The dimension with the highest z score |
| `assignment_margin` | `03` | Gap between the top two dimension scores |
