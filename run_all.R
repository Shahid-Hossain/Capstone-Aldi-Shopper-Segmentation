####################################################################
# run_all.R
#
# Runs the whole pipeline end to end. From the repository root:
#
#   Rscript run_all.R
#
# or, inside RStudio, open the project and run source("run_all.R").
#
# Each stage depends on objects created by the one before it, so the
# order matters. Running a single stage on its own works as long as
# 00_config.R and the earlier stages have already been sourced.
####################################################################

started <- Sys.time()

stages <- c(
  "R/00_config.R",
  "R/01_prepare_data.R",
  "R/02_factor_analysis.R",
  "R/03_segment_scoring.R",
  "R/04_multinomial_model.R",
  "R/05_charts.R"
)

for (stage in stages) {
  cat(strrep("=", 68), "\n")
  cat(">>", stage, "\n")
  cat(strrep("=", 68), "\n")
  source(stage, echo = FALSE)
}

cat(strrep("=", 68), "\n")
cat("Pipeline finished in",
    round(as.numeric(difftime(Sys.time(), started, units = "secs")), 1),
    "seconds.\n")
cat("Outputs are in", PATH_OUTPUT, "\n")
cat(strrep("=", 68), "\n")
