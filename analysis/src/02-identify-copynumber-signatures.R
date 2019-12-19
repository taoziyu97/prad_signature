
# Load packages -----------------------------------------------------------

library(sigminer)
library(tidyverse)
library(NMF)

# Set this per R session
options(sigminer.sex = "male", sigminer.copynumber.max = 20L)

# Generate CopyNumber object ----------------------------------------------
# Note: we used two name system for FACETS and Sequenza data

CNV.facets = read_copynumber("data/CNV_from_dbGAP_PLUS_TCGA_WES_CVAL150.tsv",
                             genome_build = "hg38",
                             complement = FALSE, verbose = TRUE)
# find 141-10 only have segments in chr1
CNV.facets = subset(CNV.facets, subset = !sample %in% "141-10")

save(CNV.facets, file = "output/CNV.facets.RData")

CNV.seqz = read_copynumber("data/CNV_from_sequenza.tsv",
                             genome_build = "hg38",
                             complement = FALSE, verbose = TRUE)

# remove WCMC160-SRR3146971 with only one CNV
CNV.seqz = subset(CNV.seqz, subset = !sample %in% "WCMC160-SRR3146971")
save(CNV.seqz, file = "output/CNV.seqz.RData")


# Derive copy number features ---------------------------------------------

ncores = 12


##
## W method
##

# Use classfication method devised by me ("W")
CNV.seqz.derive.W <- sig_derive(CNV.seqz, method = "W", cores = ncores, feature_setting = CN.features)
save(CNV.seqz.derive.W, file = "output/CNV.seqz.derive.W.RData")

CNV.facets.derive.W <- sig_derive(CNV.facets, method = "W", cores = ncores, feature_setting = CN.features)
save(CNV.facets.derive.W, file = "output/CNV.facets.derive.W.RData")

##
## M method
##

# Use classfication method from Macintyre et al ("M")
system.time(
  CNV.seqz.derive.M <- sig_derive(CNV.seqz, method = "M", cores = ncores, nrep = 3)
)
# 5126.994s
save(CNV.seqz.derive.M, file = "output/CNV.seqz.derive.M.RData")

system.time(
  CNV.facets.derive.M <- sig_derive(CNV.facets, method = "M", cores = ncores, nrep = 3)
)
save(CNV.facets.derive.M, file = "output/CNV.facets.derive.M.RData")

# Use components from sequenza as reference
CNV.facets.derive.M.ref.seqz <- sig_derive(CNV.facets, method = "M",
                                           reference_components = CNV.seqz.derive.M$components,
                                           cores = ncores)

save(CNV.facets.derive.M.ref.seqz, file = "output/CNV.facets.derive.M.ref.seqz.RData")



# Estimate number of copy number signatures -------------------------------
ncores = 20

EST.seqz.W = sig_estimate(CNV.seqz.derive.W$nmf_matrix[, 1:50],
                          range = 2:12, nrun = 50, cores = ncores, use_random = TRUE,
                          save_plots = FALSE,
                          verbose = TRUE)
save(EST.seqz.W, file = "output/EST.seqz.W.RData")

#
EST.seqz.W.all = sig_estimate(CNV.seqz.derive.W$nmf_matrix,
                          range = 2:12, nrun = 50, cores = ncores, use_random = TRUE,
                          save_plots = FALSE,
                          verbose = TRUE)
save(EST.seqz.W.all, file = "output/EST.seqz.W.all.RData")

#
EST.facets.W = sig_estimate(CNV.facets.derive.W$nmf_matrix[, 1:50],
                          range = 2:12, nrun = 50, cores = ncores, use_random = TRUE,
                          save_plots = FALSE, pConstant = 1e-9,
                          verbose = TRUE)
save(EST.facets.W, file = "output/EST.facets.W.RData")

#
EST.facets.W.all = sig_estimate(CNV.facets.derive.W$nmf_matrix,
                            range = 2:12, nrun = 50, cores = ncores, use_random = TRUE,
                            save_plots = FALSE, pConstant = 1e-9,
                            verbose = TRUE)
save(EST.facets.W.all, file = "output/EST.facets.W.all.RData")

#
EST.seqz.M = sig_estimate(CNV.seqz.derive.M$nmf_matrix,
                          range = 2:12, nrun = 50, cores = ncores, use_random = TRUE,
                          save_plots = FALSE,
                          verbose = TRUE)
save(EST.seqz.M, file = "output/EST.seqz.M.RData")

#
EST.facets.M = sig_estimate(CNV.facets.derive.M$nmf_matrix,
                            range = 2:12, nrun = 50, cores = ncores, use_random = TRUE,
                            save_plots = FALSE,
                            verbose = TRUE)
save(EST.facets.M, file = "output/EST.facets.M.RData")

#
EST.facets.M.ref.seqz = sig_estimate(CNV.facets.derive.M.ref.seqz$nmf_matrix,
                                     range = 2:12, nrun = 50, cores = ncores, use_random = TRUE,
                                     save_plots = FALSE,
                                     verbose = TRUE)
save(EST.facets.M.ref.seqz, file = "output/EST.facets.M.ref.seqz.RData")


# Check the best signature number -----------------------------------------

load("output/EST.seqz.W.all.RData")
load("output/EST.facets.W.all.RData")
load("output/EST.seqz.M.RData")
load("output/EST.facets.M.RData")

show_sig_number_survey(EST.seqz.W)
show_sig_number_survey(EST.facets.W)

show_sig_number_survey(EST.seqz.W.all)
EST.seqz.W.all$survey_plot
show_sig_number_survey(EST.facets.W.all)
EST.facets.W.all$survey_plot

show_sig_number_survey(EST.seqz.M)
show_sig_number_survey(EST.facets.M)

show_sig_number_survey(EST.facets.M.ref.seqz)
# Extract copy number signatures ------------------------------------------

