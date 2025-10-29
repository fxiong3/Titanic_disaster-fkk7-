# install_packages.R
# Install only small, focused packages
options(repos = "https://cloud.r-project.org", Ncpus = parallel::detectCores())

pkgs  <- c("readr", "fastDummies", "dplyr") 
need  <- setdiff(pkgs, rownames(installed.packages()))
if (length(need)) install.packages(need)

# hard fail if anything didn't install
missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing)) stop(paste("Packages failed to install:", paste(missing, collapse = " ")))
