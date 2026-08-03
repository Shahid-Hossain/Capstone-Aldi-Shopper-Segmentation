# Methodology

The decisions behind the pipeline, including the ones that could reasonably have gone the other way.

---

## 1. Handling missing answers

Item non response runs at roughly one percent per item. Across 31 analysis variables, dropping any respondent with a single blank would remove a meaningful share of the sample, and it would not remove them at random: people who skip questions differ systematically from people who do not.

Missing values are therefore replaced with the item median, calculated on the reference wave. Median rather than mean because the importance items are ordinal and heavily skewed toward the top of the scale.

The tradeoff is that imputation slightly compresses variance and makes the factor solution look marginally cleaner than the raw data supports. At one percent missingness the effect is small. At ten percent it would not be acceptable and multiple imputation would be the right approach instead.

The medians are calculated once and stored, so the second wave is imputed with the first wave's values rather than its own. This keeps both waves on the same footing.

---

## 2. Choosing the number of factors

Three inputs:

**Parallel analysis.** Compares eigenvalues from the observed correlation matrix against eigenvalues from random data of identical dimensions. Factors that beat the random baseline are retained. This is the least subjective of the three.

**Interpretability.** A factor that loads on four items with no common theme is a statistical artefact, not a shopper motivation. Every retained factor has to be describable in one sentence to a merchandising team.

**Actionability.** Two factors that split cleanly in the data but imply the same commercial response are one factor for practical purposes.

The number lives in `N_FACTORS` in `R/00_config.R` so it can be changed and the consequences inspected. Anyone reusing this on different data should look at the loadings printout before trusting the grouping in `DIMENSION_ITEMS`.

---

## 3. Oblique rotation rather than orthogonal

Varimax forces factors to be uncorrelated. That is convenient and, here, wrong. A shopper who cares about produce quality almost certainly also cares about meat quality, and a shopper who wants everyday low prices probably also watches the weekly ad.

Oblimin allows factors to correlate. The resulting solution is messier to present and closer to how shoppers actually work. Forcing orthogonality would have produced artificially independent dimensions and overstated how cleanly the segments separate.

---

## 4. Factor scores compared with item composites

This is the largest methodological choice in the pipeline and the one most worth understanding.

Two ways to turn the factor solution into a respondent score:

**Regression factor scores.** Use the weights `psych::fa` estimates to compute each respondent's position on each factor. Statistically efficient. Uses all the information in the loading matrix.

**Item composites.** Z score each item, then average the z scores within a dimension. Cruder. Ignores the loading magnitudes.

This pipeline uses item composites, for three reasons.

*Wave comparability.* Factor score weights are estimated from one specific correlation matrix. Applying them to a different wave requires assuming the covariance structure is stable across four years, which is exactly the assumption the wave comparison is meant to test. Item composites need only the item means and standard deviations, which are simple to freeze and simple to explain.

*Transparency.* "The average of how much you stand out on these five questions" is a sentence a stakeholder can check. "A weighted combination derived from a minimum residual extraction with oblique rotation" is a sentence they have to take on faith.

*Reproducibility.* Factor numbering is not stable. Rerun the extraction on a slightly different sample and the factor labelled MR1 may swap with MR3. Any code that maps factor numbers to business dimensions silently breaks when that happens, and it breaks quietly, which is worse.

Factor analysis still does necessary work. It establishes that the items group into five distinct dimensions rather than one, and it determines which items belong together. It just does not produce the final scores.

**The tradeoff:** the composite approach discards the loading magnitudes, so a strongly loading item and a weakly loading one count equally within a dimension. That costs some precision. The gain in comparability and explicability was judged to be worth it. On a single wave with no comparison requirement, regression scores would be the better choice.

---

## 5. Assigning each respondent to one segment

Each respondent is assigned to whichever dimension has their highest z score. Everyone gets exactly one label.

The argument for this rule is that it is simple, it covers the whole sample, and it gives the business something it can act on immediately.

The argument against is that it forces a decision even when there is no real difference to decide on. A respondent scoring 0.42 on Quality and 0.41 on Selection is assigned to Quality on a difference that is well inside the measurement noise.

The pipeline therefore also calculates an assignment margin, the gap between each respondent's top two dimensions, and reports what share of the sample falls below a meaningful threshold. Those respondents are genuinely mixed shoppers. Knowing how many there are is the difference between a segmentation and a false sense of precision.

A latent class model would handle this properly by assigning probabilities of membership rather than hard labels. That was outside the scope here, and it would be the natural next iteration.

---

## 6. Collapsing demographic categories

The survey captures household income in 25 narrow bands. Those collapse into seven reporting bands.

Twenty five bands against five outcome segments creates 125 cells. Many hold a handful of respondents, and with a handful of respondents the model can achieve perfect separation, where a demographic cell contains only one outcome. The coefficient then runs off to infinity and reports back as an odds ratio in the millions. That is not a strong finding. It is a cell with four people in it.

The survey's top income band was folded into the band below it for the same reason. Gender categories beyond female and male are combined for modelling only and are preserved in the underlying data.

The pipeline prints a warning whenever a band holds fewer than thirty respondents, because the next person to run this on different data will not necessarily check.

---

## 7. What the model does not establish

The outcome variable is derived from the respondent's own survey answers. The predictors come from the same questionnaire. The model therefore describes who the segments are. It does not establish what causes anyone to be price driven.

A retailer could reasonably use these results to decide where to weight a media buy. It could not use them to conclude that raising a household's income would change how that household shops.

Separately, the whole exercise rests on stated importance. Nobody in this dataset was observed buying anything. Validation against transaction data is the missing step, and it is a genuine gap rather than a caveat.
