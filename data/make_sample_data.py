"""
Generates a fully synthetic survey dataset with the same shape as the
capstone source file. No real respondent data is used or reproduced.

Latent structure: five correlated shopper-motivation dimensions drive the
item responses, and demographics shift the latent means so the multinomial
model has something real to estimate.
"""

import numpy as np
import pandas as pd

rng = np.random.default_rng(20260802)

N_2025 = 2000
N_2021 = 1200

LIKERT_LABELS = {
    1: "1 - Not at all important",
    2: "2 - Not very important",
    3: "3 - Somewhat important",
    4: "4 - Very important",
    5: "5 - Extremely important",
}

INCOME_BANDS = [
    "Less than $5,000", "$5,000-$9,999", "$10,000-$14,999", "$15,000-$19,999",
    "$20,000-$24,999", "$25,000-$29,999", "$30,000-$34,999", "$35,000-$39,999",
    "$40,000-$44,999", "$45,000-$49,999", "$50,000-$54,999", "$55,000-$59,999",
    "$60,000-$64,999", "$65,000-$69,999", "$70,000-$74,999", "$75,000-$79,999",
    "$80,000-$84,999", "$85,000-$89,999", "$90,000-$94,999", "$95,000-$99,999",
    "$100,000-$124,999", "$125,000-$149,999", "$150,000-$199,999",
    "$200,000-$249,999", "$250,000 or more",
]
INCOME_MIDPOINT = np.array([
    2.5, 7.5, 12.5, 17.5, 22.5, 27.5, 32.5, 37.5, 42.5, 47.5,
    52.5, 57.5, 62.5, 67.5, 72.5, 77.5, 82.5, 87.5, 92.5, 97.5,
    112.5, 137.5, 175.0, 225.0, 300.0,
])
INCOME_WEIGHTS = np.array([
    1.0, 1.2, 1.8, 2.0, 2.4, 2.6, 2.8, 2.9, 3.0, 3.0,
    3.1, 3.0, 2.9, 2.8, 2.7, 2.5, 2.4, 2.2, 2.1, 2.0,
    5.5, 4.0, 3.5, 1.8, 1.4,
])
INCOME_WEIGHTS = INCOME_WEIGHTS / INCOME_WEIGHTS.sum()

AGE_BANDS = ["18-24", "25-36", "37-56", "57-65", "66+"]
AGE_WEIGHTS = [0.11, 0.24, 0.32, 0.17, 0.16]
AGE_MID = {"18-24": 21, "25-36": 30, "37-56": 46, "57-65": 61, "66+": 71}

GENDERS = ["Female", "Male", "Another gender", "Prefer not to answer"]
GENDER_WEIGHTS = [0.53, 0.44, 0.02, 0.01]

# Item -> (dimension, loading strength)
Q5E_ITEMS = {
    "q5e_everyday_low_prices":       ("price", 0.85),
    "q5e_frequent_promotions":       ("price", 0.75),
    "q5e_weekly_ads":                ("price", 0.80),
    "q5e_store_coupons":             ("price", 0.72),
    "q5e_low_receipt_total":         ("price", 0.68),
    "q5e_product_quality":           ("quality", 0.82),
    "q5e_produce_quality":           ("quality", 0.86),
    "q5e_meat_quality":              ("quality", 0.84),
    "q5e_store_brand_quality":       ("quality", 0.70),
    "q5e_product_selection":         ("selection", 0.83),
    "q5e_national_brand_selection":  ("selection", 0.76),
    "q5e_store_brand_selection":     ("selection", 0.71),
    "q5e_one_stop_shop":             ("selection", 0.74),
    "q5e_fresh_service_depts":       ("selection", 0.66),
    "q5e_store_app":                 ("digital", 0.84),
    "q5e_accurate_web_prices":       ("digital", 0.74),
    "q5e_loyalty_program":           ("digital", 0.63),
    "q5e_curbside_pickup":           ("digital", 0.86),
    "q5e_delivery":                  ("digital", 0.85),
    "q5e_quick_easy_shop":           ("convenience", 0.80),
    "q5e_clean_store":               ("convenience", 0.75),
}

Q7_ITEMS = {
    "q7_store_apps":             ("digital", 1.10, -0.30),
    "q7_store_websites":         ("digital", 1.00, -0.25),
    "q7_search_engine":          ("digital", 0.85, -0.55),
    "q7_price_comparison_sites": ("digital", 0.95, -1.10),
    "q7_multi_store_apps":       ("digital", 0.90, -1.00),
    "q7_coupon_apps":            ("digital", 0.80, -0.70),
    "q7_ai_assistant":           ("digital", 0.75, -1.60),
    "q7_print_ads":              ("price", 0.85, -0.40),
    "q7_digital_ads":            ("price", 0.80, -0.35),
    "q7_word_of_mouth":          ("convenience", 0.45, -0.60),
    "q7_social_media":           ("digital", 0.55, -0.90),
    "q7_own_experience":         ("quality", 0.40, 1.05),
    "q7_receipts":               ("price", 0.60, -0.30),
}

Q8A_ITEMS = {
    "q8a_national_brand_sale":    ("price", 0.85, 0.55),
    "q8a_store_brand_sale":       ("price", 0.80, 0.35),
    "q8a_store_brand_regular":    ("quality", 0.55, -0.35),
    "q8a_national_brand_regular": ("quality", 0.50, -0.30),
}

Q14_CATEGORIES = [
    "alcoholic_beverages", "nonalcoholic_beverages", "condiments",
    "sweet_snacks", "savory_snacks", "pantry_items", "canned_goods",
    "dairy", "fresh_produce", "fresh_bread", "grab_and_go", "fresh_meat",
    "seafood", "frozen", "health_beauty", "cleaning_products",
    "paper_products",
]
Q14_NOT_BOUGHT_RATE = {
    "alcoholic_beverages": 0.34, "seafood": 0.22, "grab_and_go": 0.19,
    "health_beauty": 0.10, "fresh_bread": 0.07,
}


def likert_from_latent(latent, loading, intercept=3.55, noise=1.0):
    raw = intercept + loading * latent + rng.normal(0, noise, size=len(latent))
    return np.clip(np.rint(raw), 1, 5).astype(int)


def yesno_from_latent(latent, loading, intercept):
    p = 1 / (1 + np.exp(-(intercept + loading * latent)))
    return np.where(rng.random(len(latent)) < p, "Yes", "No")


def build_wave(n, wave, id_start):
    income_idx = rng.choice(len(INCOME_BANDS), size=n, p=INCOME_WEIGHTS)
    income = np.array(INCOME_BANDS)[income_idx]
    income_k = INCOME_MIDPOINT[income_idx]
    income_z = (np.log(income_k) - np.log(INCOME_MIDPOINT).mean()) / 0.75

    age_band = rng.choice(AGE_BANDS, size=n, p=AGE_WEIGHTS)
    age_num = np.array([AGE_MID[a] for a in age_band])
    age_z = (age_num - 44) / 17

    gender = rng.choice(GENDERS, size=n, p=GENDER_WEIGHTS)
    is_male = (gender == "Male").astype(float)

    kids_p = 1 / (1 + np.exp(-(0.55 - 0.95 * age_z)))
    has_kids = np.where(rng.random(n) < kids_p, "Have kids < 18", "No kids < 18")
    kids_flag = (has_kids == "Have kids < 18").astype(float)

    # 2021 respondents were, on the whole, less digitally oriented.
    wave_digital_shift = 0.0 if wave == 2025 else -0.42
    wave_conv_shift = 0.0 if wave == 2025 else 0.20

    shared = rng.normal(0, 0.45, n)

    price = (-0.34 * income_z + 0.22 * kids_flag - 0.06 * age_z
             + 0.55 * shared + rng.normal(0, 0.80, n))
    quality = (0.40 * income_z - 0.10 * age_z + 0.10 * kids_flag
               + 0.45 * shared + rng.normal(0, 0.80, n))
    digital = (-0.46 * age_z - 0.10 * income_z + 0.14 * kids_flag
               + wave_digital_shift + 0.35 * shared + rng.normal(0, 0.80, n))
    selection = (0.14 * income_z + 0.30 * is_male - 0.08 * age_z
                 + 0.45 * shared + rng.normal(0, 0.80, n))
    convenience = (0.16 * age_z - 0.12 * kids_flag + wave_conv_shift
                   + 0.45 * shared + rng.normal(0, 0.80, n))

    latents = {"price": price, "quality": quality, "digital": digital,
               "selection": selection, "convenience": convenience}

    out = {
        "wave": np.full(n, wave),
        "respondent_id": np.arange(id_start, id_start + n),
        "gender": gender,
        "age_range": age_band,
        "household_income": income,
        "has_kids_under_18": has_kids,
    }

    overall = 0.5 * price + 0.3 * quality + 0.2 * convenience
    out["q5a_best_value_importance"] = [
        LIKERT_LABELS[v] for v in likert_from_latent(overall, 0.55, 4.05, 0.75)
    ]

    for col, (dim, load) in Q5E_ITEMS.items():
        out[col] = [LIKERT_LABELS[v] for v in likert_from_latent(latents[dim], load)]

    for col, (dim, load, icept) in Q7_ITEMS.items():
        out[col] = yesno_from_latent(latents[dim], load, icept)

    for col, (dim, load, icept) in Q8A_ITEMS.items():
        out[col] = yesno_from_latent(latents[dim], load, icept)

    pricing_pref = np.where(
        rng.random(n) < 1 / (1 + np.exp(-(0.10 - 0.85 * price))),
        "Every-day low product prices with fewer sales and deals offered",
        "Regular item prices with many sales and deals offered",
    )
    out["newq3_pricing_preference"] = pricing_pref

    price_focus = np.where(
        rng.random(n) < 1 / (1 + np.exp(-(-0.05 - 0.70 * price))),
        "The prices of key products I buy most",
        "The cost of my entire receipt/purchase from that store",
    )
    out["newq4_price_focus"] = price_focus

    tradeoff = 0.75 * price - 0.75 * quality
    for cat in Q14_CATEGORIES:
        p_lowest = 1 / (1 + np.exp(-(0.05 + tradeoff)))
        pick = np.where(rng.random(n) < p_lowest, "The lowest price", "Best quality")
        skip_rate = Q14_NOT_BOUGHT_RATE.get(cat, 0.04)
        pick = np.where(rng.random(n) < skip_rate, "I don't buy this category", pick)
        out[f"q14_{cat}"] = pick

    return pd.DataFrame(out)


df = pd.concat(
    [build_wave(N_2025, 2025, 100001), build_wave(N_2021, 2021, 200001)],
    ignore_index=True,
)

# A survey export is never perfectly clean; leave a realistic trace of item
# non-response so the imputation step in the pipeline has something to do.
for col in df.columns:
    if col.startswith(("q5e_", "q5a_", "q7_", "q8a_", "newq")):
        mask = rng.random(len(df)) < 0.012
        df.loc[mask, col] = np.nan

df = df.sample(frac=1, random_state=7).reset_index(drop=True)
df.to_csv("data/sample_survey_data.csv", index=False)

print("rows:", len(df), "| cols:", df.shape[1])
print(df["wave"].value_counts().to_dict())
