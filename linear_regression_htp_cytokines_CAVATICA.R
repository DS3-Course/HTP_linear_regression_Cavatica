################################################
# Title: linear regression template
# Project: Linear regression analysis of omics data in R (CAVATICA)
# Author(s):
#   - author 1
# email(s):
#   - author1@institution.edu
# affiliation(s):
#   - Department of XXX
#   - University of XXX
################################################
# Script original author: Matthew Galbraith
# version: 0.1  Date: 05_21_2024
################################################
# Change Log:
# v0.1
# Initial version
#

### Summary:  
# Linear regression modelling for differential abundance of plasma cytokines and immune related factors as measured on by Mesoscale Discovery (MSD) multiplexed ELISA.
# See PMID 37379383.
#  

### Data type(s):
#   A. HTP sample meta data
#      Where/who did this data come from?
#      What is the source of the original data and where is it stored?
#   B. HTP MSD data
#      Where/who did this data come from? INCLUDE Data Hub
#      What is the source of the original data and where is it stored?
#

### Workflow:
#   Step 1 - Read in and inspect sample meta data + Protein/Metabolite/Cytokine data
#   Step 2 - Data exploration
#   Step 3 - Linear regression model setup and assessment
#   Step 4 - Model results
#   Step 5 - Plot individual features
#  

## Comments:
#  This analysis run in Data Studio on CAVATICA using data pushed from the INCLUDE Data Hub  
#  


# 0 General Setup -----
# RUN FIRST TIME
# renv::init()
## 0.1 Load required libraries ----
library("readxl") # used to read .xlsx files
library("openxlsx") # used for data export as Excel workbooks
library("tidyverse") # data wrangling and ggplot2
library("rstatix") # pipe- and tidy-friendly statistical tests
library("ggrepel") # required for labelling genes
library("ggforce") # required for zooming and sina
# library("plotly") # required for interactive plots/IFNA1
library("tictoc") # timer
library("skimr") # data summary
library("broom") # tidying model objects
library("janitor") # data cleaning
library("patchwork") # assembliong multiple plots
# library("tidyHeatmap")
library("conflicted")
conflict_prefer("filter", "dplyr")
conflict_prefer("select", "dplyr")
conflict_prefer("count", "dplyr")
library("here") # generates path to current project directory
# detach("package:here", unload=TRUE) # run this to reset here()
source(here("helper_functions.R")) # load helper functions
#

## 0.2 renv setup ----
# see vignette("renv")
# The general workflow when working with renv is:
#  1 Call renv::init() to initialize a new project-local environment with a private R library,
#  2 Work in the project as normal, installing and removing new R packages as they are needed in the project,
#    recommend using renv::install() as this will automatically update lockfile
#  3 Call renv::snapshot() to save the state of the project library to the lockfile (called renv.lock),
#  4 Continue working on your project, installing and updating R packages as needed.
#  5 Call renv::snapshot() again to save the state of your project library if
# your attempts to update R packages were successful, or call renv::restore() to
# revert to the previous state as encoded in the lockfile if your attempts to
# update packages introduced some new problems.
#

## 0.3 Set required parameters ----
# Input data files
htp_meta_data_file <- here("data", "HTP_Metadata_v0.5_Synapse.txt") # in future this data will be available directly in Cavatica
# htp_cytokines_data_file <- here("data", "HTP_MSD_Cytokines_Synapse.txt")
#
# Specific to CAVATICA:
# For per sample files obtained from INCLUDE Data Hub
htp_cytokines_data_files_location <- "/sbgenomics/project-files"
#
# Other parameters
# standard_colors <- c("Group1" = "#F8766D", "Group2" = "#00BFC4")
standard_colors <- c("Control" = "gray60", "T21" = "#009b4e")
out_file_prefix <- "linear_regression_htp_cytokines_CAVATICA_v0.1_"
# End required parameters ###


# 1 Read in and inspect data ----
## 1.1 Read in meta data ----
htp_meta_data <- htp_meta_data_file |> 
  read_tsv() |> 
  mutate(
    Karyotype = fct_relevel(Karyotype, c("Control", "T21")), # convert to factor and set order
    Sex = fct_relevel(Sex, "Female"), # convert to factor and set order
    Sample_source_code = as_factor(Sample_source_code) # convert to factor - default is numerical order
  )
# inspect
htp_meta_data
htp_meta_data |> skimr::skim()
#
here("data/HTP_Metadata_v0.5_dictionary.txt") |> read_tsv()
#

## 1.2 Read in abundance data ----
# htp_cytokines_data <- htp_cytokines_data_file |> 
#   read_tsv()
#   # janitor::clean_names(case = "none")
#
# Specific to CAVATICA:
# For per sample files obtained from INCLUDE Data Hub, get file paths
htp_cytokines_data_files <- list.files(
  htp_cytokines_data_files_location,
  pattern = "_MSD.tsv.gz",
  full.names = TRUE
  )
# Then pass the list of file paths to read_tsv() which will combine them and store the file paths as an id
htp_cytokines_data <- read_tsv(htp_cytokines_data_files, id = "file_path") # may take a few minutes
# NOTE: suggest writing out combined file to /data so that your project is self-contained
# subsequent analyses could then read in the combined file instead of re-reading the separate files
#
# inspect
htp_cytokines_data # 25,758 rows
htp_cytokines_data |> skimr::skim()
htp_cytokines_data |> distinct(Analyte) # 54 Analytes
htp_cytokines_data |> distinct(LabID) # 477 LabIDs
#
# here("data/HTP_MSD_Cytokines_dictionary.txt") |> read_tsv()
#

## 1.3 Join meta data with data type 1 and data type 2 ----
htp_meta_cytokines_data <- htp_cytokines_data |> 
  inner_join(htp_meta_data, join_by(LabID))
# check number of rows returned !!!


# 2 Data exploration  ----
## 2.1 basic check of data distribution(s) ----
htp_meta_cytokines_data |> 
  filter(Analyte == "CRP") |> 
  ggplot(aes(Karyotype, log2(Value), color = Karyotype)) +
  geom_boxplot()
#
htp_meta_cytokines_data |> 
  filter(Analyte == "CRP") |> 
  ggplot(aes(Karyotype, log2(Value), color = Karyotype)) +
  geom_sina() +
  geom_boxplot(notch = TRUE, varwidth = FALSE, outlier.shape = NA, coef = FALSE, width = 0.3, color = "black", fill = "transparent", size = 0.75) +
  scale_color_manual(values = standard_colors) +
  theme(aspect.ratio = 1.3) +
  labs(
    title = "CRP abundance"
  )
#
htp_meta_cytokines_data |> 
  ggplot(aes(Karyotype, log2(Value), color = Karyotype)) +
  geom_sina() +
  geom_boxplot(notch = TRUE, varwidth = FALSE, outlier.shape = NA, coef = FALSE, width = 0.3, color = "black", fill = "transparent", size = 0.75) +
  scale_color_manual(values = standard_colors) +
  facet_wrap(~ Analyte, nrow = 5, scales = "free_y") +
  theme(aspect.ratio = 1.3) +
  labs(
    title = "Analyte abundance"
  )
#

## 2.2 Check for extreme outliers ----
# Features with greatest numbers of extreme outliers
htp_meta_cytokines_data |>  
  group_by(Analyte, Karyotype) |>  # important to think about appropriate grouping here
  mutate(extreme = rstatix::is_extreme(log2(Value))) |>  
  ungroup() |> 
  filter(extreme == TRUE) |>  
  count(Analyte, name = "n_extreme") |>  
  arrange(-n_extreme)
# Plot with outliers highlighted
htp_meta_cytokines_data |> 
  filter(Analyte %in% c("Eotaxin-3", "IP-10")) |> 
  group_by(Analyte, Karyotype) |>  # important to think about appropriate grouping here
  mutate(extreme = rstatix::is_extreme(log2(Value))) |>  
  ungroup() |>  
  ggplot(aes(Karyotype, log2(Value))) +
  geom_sina(
    data = . %>% filter(extreme == FALSE),
    aes(color = Karyotype)
  ) +
  geom_sina(
    data = . %>% filter(extreme == TRUE),
    aes(color = "extreme")
  ) +
  geom_boxplot(
    data = . %>% filter(extreme == FALSE),
    notch = TRUE, varwidth = FALSE, outlier.shape = NA, coef = FALSE, width = 0.3, color = "black", fill = "transparent", size = 0.75
  ) +
  scale_color_manual(values = c(standard_colors, "extreme" = "red")) +
  facet_wrap(~ Analyte, scales = "free") +
  theme(aspect.ratio = 1.3) +
  labs(
    title = "Features with most 'extreme' outliers"
    )
#

## 2.3 Shapiro-Wilk test ----
# very stringent but worth comparing 'best' and 'worst' features
htp_meta_cytokines_data |> 
  group_by(Analyte, Karyotype) |>  # important to think about appropriate grouping here
  mutate(extreme = rstatix::is_extreme(log2(Value))) |>  
  ungroup() |>  
  filter(extreme == FALSE) |> 
  mutate(log2_value = log2(Value)) |>  
  group_by(Analyte) |> 
  rstatix::shapiro_test(log2_value) |> 
  arrange(p)
# # Q-Q plots (OPTIONAL)
# htp_meta_cytokines_data |> 
#   filter(Analyte %in% c("IL-3", "TNF-alpha")) |> 
#   group_by(Analyte, Karyotype) |>  # important to think about appropriate grouping here
#   mutate(extreme = rstatix::is_extreme(log2(Value))) |>  
#   ungroup() |>  
#   filter(extreme == FALSE) |> 
#   mutate(log2_value = log2(Value)) |>  
#   ggpubr::ggqqplot("log2_value", facet.by = "Analyte", title = "Q-Q plot(s)")
# #


# 3 Linear regression modelling ----
## 3.1 Set up models for assessment ----
regressions_data <- htp_meta_cytokines_data |> 
  group_by(Analyte, Karyotype) |>  # important to think about appropriate grouping here
  mutate(extreme = rstatix::is_extreme(log2(Value))) |>  
  ungroup() |>  
  filter(extreme == FALSE) |> # may need to ensure sufficient sample numbers remain or will get errors when running models
  nest(-Analyte)
#
# Simple model
tic("Running linear regressions for simple model...")
regressions_simple <- regressions_data %>% 
  mutate(
    fit = map(data, ~ lm(log2(Value) ~ Karyotype, data = .x)),
    tidied = map(fit, broom::tidy), # see ?tidy.lm
    glanced = map(fit, broom::glance), # see ?glance.lm
    augmented = map(fit, broom::augment) # see ?augment.lm
  )
toc()
regressions_simple
#
# Inspect a model object
regressions_simple |> pluck("fit", 1) # row 1 = CRP
regressions_simple |> pluck("fit", 1) |> class()
regressions_simple |> pluck("fit", 1) |> summary()
regressions_simple |> pluck("fit", 1) |> broom::tidy()
#
# Multi-variate model
tic("Running linear regressions for multi model...")
regressions_multi_SexAgeSource <- regressions_data %>% 
  mutate(
    fit = map(data, ~ lm(log2(Value) ~ Karyotype + Sex + Age + Sample_source_code, data = .x)), # check factors are factors or they may get treated as numeric
    tidied = map(fit, broom::tidy), # see ?tidy.lm
    glanced = map(fit, broom::glance), # see ?glance.lm
    augmented = map(fit, broom::augment) # see ?augment.lm
  )
toc()
#

## 3.2 Compare models using Likelihood Ratio Test ----
# The likelihood ratio test looks to see if the difference between the log-likelihood (or goodness-of-fit) from two models is statistically significant.
# Must compare two related models - the more complex model must differ from the simple model only by the addition of one or more parameters.
# If significant, can be used to justify using more complex model for further analysis.
# 
lrt_res <- regressions_simple |> 
  inner_join(regressions_multi_SexAgeSource, join_by(Analyte)) |> 
  mutate(
    LRT = map2(fit.x, fit.y, ~ anova(.x,.y, test="LRT") |> broom::tidy())
  ) |> 
  select(Analyte, LRT) |> 
  unnest(LRT) |> 
  filter(!is.na(p.value)) |> 
  arrange(p.value)
lrt_res
lrt_res |> count(p.value < 0.05)
#

## 3.3 Compare models using AIC ----
# Akaike Information Criteria (AIC): lower values are 'better'.
# Incorporates log-likelihood statistics and Maximum Likelihood Estimation and penalizes complicated models with more covariates.
# i.e. a model with more covariates must 'overcome' the additional complexity to be considered 'better'.
# Often will need some compromise to choose single preferred model specification across all features.
simple_glance <- regressions_simple %>% unnest(glanced) |> select(Analyte, AIC, everything())
multi_SexAgeSource_glance <- regressions_multi_SexAgeSource %>% unnest(glanced) |> select(Analyte, AIC, everything())
#
simple_glance %>% select(Analyte, AIC1 = AIC) %>% 
  inner_join(multi_SexAgeSource_glance %>% select(Analyte, AIC2 = AIC)) %>% 
  mutate(AIC_diff = AIC1 - AIC2) %>% 
  arrange(-AIC_diff) %>% 
  mutate(Analyte = fct_inorder(Analyte)) %>% 
  ggplot(aes(Analyte, AIC_diff)) +
  geom_hline(yintercept = 0) +
  geom_hline(yintercept = 10, linetype = 2) +
  geom_hline(yintercept = -10, linetype = 2) +
  geom_point() +
  # theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 8)) + 
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank()) + # turn off with too many
  labs(title = "simple  vs. multi_SexAgeSource model") +
  geom_text_repel(data = . %>%  slice_max(abs(AIC_diff), n = 6), aes(label = Analyte), size = 3)
#


# 4 Model results ----
## 4.1 Extract model results for simple model ----
lm_results_simple <- regressions_simple |>
  unnest(tidied) |> 
  filter(str_detect(term, "Karyotype")) |> 
  transmute(
    Analyte, 
    FoldChange = 2^estimate, # check for transformation and adjust accordingly
    log2FoldChange = estimate, # check for transformation and adjust accordingly
    pval = p.value,
    BHadj_pval = p.adjust(pval, method = "BH"),
    Model = "lm(log2(Value) ~ Karyotype)" # Update accordingly
    ) |> 
  arrange(pval)
# Volcano plot
v1 <- lm_results_simple %>% 
  volcano_plot_lab_lm(
    title = "Cytokines: T21 vs. Control",
    subtitle = paste0("lm: log2(Conc.) ~ Karyotype\n","[Down: ", (.) %>% filter(BHadj_pval < 0.1 & FoldChange < 1) %>% nrow(), "; Up: ", (.) %>% filter(BHadj_pval < 0.1 & FoldChange > 1) %>% nrow(), "]")
  )
v1
ggsave(filename = here("plots", paste0(out_file_prefix, "volcano_simple", ".png")), width = 5, height = 5, units = "in")
ggsave(filename = here("plots", paste0(out_file_prefix, "volcano_simple", ".pdf")), device = cairo_pdf, width = 5, height = 5, units = "in")
# ggrastr::rasterize(., layers='Point', dpi = 600, dev = "ragg_png")
#
# Export results as tab-delimited text
lm_results_simple |> 
  write_tsv(file = here("results", paste0(out_file_prefix, "lm_results_simple", ".txt")))
# Export results as Excel (input must be named list)
list(
  "lm_results_simple" = lm_results_simple
) |> 
  export_excel(filename = "lm_results_simple")
#
#

## 4.2 Extract model results for multi model ----
lm_results_multi_SexAgeSource <- regressions_multi_SexAgeSource |>
  unnest(tidied) |> 
  filter(str_detect(term, "Karyotype")) |> 
  transmute(
    Analyte, 
    FoldChange = 2^estimate, # check for transformation and adjust accordingly
    log2FoldChange = estimate, # check for transformation and adjust accordingly
    pval = p.value,
    BHadj_pval = p.adjust(pval, method = "BH"),
    Model = "lm(log2(Value) ~ Karyotype + Sex + Age + Sample_source_code)" # Update accordingly
  ) |> 
  arrange(pval)
# Volcano plot
v2 <- lm_results_multi_SexAgeSource %>% 
  volcano_plot_lab_lm(
    title = "Cytokines: T21 vs. Control",
    subtitle = paste0("lm: log2(Conc.) ~ Karyotype+Sex+Age+Source\n","[Down: ", (.) %>% filter(BHadj_pval < 0.1 & FoldChange < 1) %>% nrow(), "; Up: ", (.) %>% filter(BHadj_pval < 0.1 & FoldChange > 1) %>% nrow(), "]")
  )
v2
ggsave(filename = here("plots", paste0(out_file_prefix, "volcano_multi", ".png")), width = 5, height = 5, units = "in")
ggsave(filename = here("plots", paste0(out_file_prefix, "volcano_multi", ".pdf")), device = cairo_pdf, width = 5, height = 5, units = "in")
# ggrastr::rasterize(., layers='Point', dpi = 600, dev = "ragg_png")
#
# Export results as tab-delimited text
lm_results_multi_SexAgeSource |> 
  write_tsv(file = here("results", paste0(out_file_prefix, "lm_results_multi_SexAgeSource", ".txt")))
# Export results as Excel (input must be named list)
list(
  "lm_results_multi_SexAgeSource" = lm_results_multi_SexAgeSource
  ) |> 
  export_excel(filename = "lm_results_multi_SexAgeSource")
#

## 4.3 Arrange multiple plots using patchwork ----
v1 + v2 + plot_layout(guides = "collect", nrow = 1) # different y scales
#
v1 + expand_limits(y = c(NA, 25)) + # same y scale
v2 + expand_limits(y = c(NA, 25)) +
  plot_layout(guides = "collect", nrow = 1)
ggsave(filename = here("plots", paste0(out_file_prefix, "volcano_combined", ".pdf")), device = cairo_pdf, width = 12, height = 5, units = "in")
#


# 5 Plot individual features ----
## 5.1 Get interesting/significant features ----
top_signif_by_FC <- bind_rows(
  lm_results_multi_SexAgeSource |> 
    filter(BHadj_pval<0.1) |> 
    arrange(-log2FoldChange) |> 
    slice_max(order_by = log2FoldChange, n = 5), # Upregulated
  lm_results_multi_SexAgeSource |> 
    filter(BHadj_pval<0.1) |> 
    arrange(log2FoldChange) |> 
    slice_min(order_by = log2FoldChange, n = 5) # Downregulated
)
#
## 5.2 Sina plots ----
# sina plots use horizontal jitter of data points to show density
# 
regressions_data |> 
  unnest(data) |> # extreme outliers already removed
  filter(Analyte %in% top_signif_by_FC$Analyte) |> # filter to features of interest
  mutate(Analyte = fct_relevel(Analyte, top_signif_by_FC$Analyte)) |> # control plotting order
  ggplot(aes(Karyotype, log2(Value), color = Karyotype)) +
  geom_sina() + 
  geom_boxplot(notch = TRUE, varwidth = FALSE, outlier.shape = NA, coef = FALSE, width = 0.3, color = "black", fill = "transparent", size = 0.75) +
  facet_wrap(~ Analyte, scales = "free_y", nrow = 2) + # facet per feature; each feature on it's own scale
  scale_color_manual(values = standard_colors) + # use standardized colors
  theme(aspect.ratio = 1.3) + # set fixed aspect ratio
  labs(
    title = "Top significant cytokines by fold-change: T21 vs. Control",
    subtitle = "Unadjusted data; extreme outliers removed"
  )
ggsave(filename = here("plots", paste0(out_file_prefix, "sina_top_signif_by_FC", ".png")), width = 15, height = 5, units = "in")
ggsave(filename = here("plots", paste0(out_file_prefix, "sina_top_signif_by_FC", ".pdf")), device = cairo_pdf, width = 15, height = 5, units = "in")
#
# ggrastr::rasterize(., layers='Point', dpi = 600, dev = "ragg_png")


# 6 Copy Project/Results to output-files ----
# In order to be accessible from the *Files* tab of your Cavatica Project, R
# Projects and/or files need to be copied to `/sbgenomics/output-files/`
# NOTE: Files copied to `/sbgenomics/output-files/` will not be accessible until after the Data Studio instance is terminated
#
## 6.1 Copy to `output files` using R ----
dir.create("/sbgenomics/output-files/R_analyses")
# by default the following will overwrite any existing files with same names
file.copy(
  from = here(),
  to = "/sbgenomics/output-files/R_analyses/",
  recursive = TRUE
)
#


################################################
# save workspace ----
save.image(file = here("rdata", paste0(out_file_prefix, ".RData")), compress = TRUE, safe = TRUE) # saves entire workspace (can be slow)
# To reload previously saved workspace:
# load(here("rdata", paste0(out_file_prefix, ".RData")))

# session_info ----
date()
sessionInfo()
################################################
