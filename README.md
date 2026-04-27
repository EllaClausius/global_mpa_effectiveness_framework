# global_mpa_effectiveness_framework
Data and code for: Defining and measuring global marine protected area effectiveness 



A comprehensive description of the derived data included in this analysis can be found in the corresponding manuscript. Code for processing and reproducing the analysis in the corresponding manuscript are described under Code/Software below.

---
## System Requirements 
Software Dependencies
* R (>= 4.3.0)
* R Packages:
   * tidyverse (2.0.0)
   * lubriate (1.9.4)
   * janitor (2.2.1)
   * sf (1.0-21)
   * terra (1.8-54)
   * biooracler (0.0.0.9000)
   * future (1.58.0)
   * purrr (1.0.4) 
   * vip (0.4.1) 
   * tune (1.3.0)
   * ggplot2 (3.5.2)
   * parsnip (1.3.2)
   * workflows (1.2.0)
   * rsample (1.3.0)
   * recipes (1.3.1)
   * dials (1.4.0)
   * randomForest (4.7-1.2)
   * ranger (0.17.0)
   * patchwork (1.3.1)
   * furrr (0.3.1)
   * progressr (0.15.1)
   * SpataialML (0.1.7)

Tested Platforms 
* Windows 10 (24H2)
* Ubuntu (24.04 LTS) 

Hardware Requirements
* No special hardware required
* Minimum: 8GB RAM, 2.5 GHz dual-core-processor
* Recommended: 16GB RAM for large datasets

## Installation Guide
### Instructions

Install from GitHub using devtools:

install.packages("devtools")  # if not already installed
devtools::install_github("EllaClausius/global_mpa_effectiveness_framework")

Or clone this repository and install locally:

git clone https://github.com/EllaClausius/global_mpa_effectiveness_framework.git
setwd("global_mpa_effectiveness_framework")
devtools::install()
Typical Install Time

1–2 minutes on a standard desktop computer with internet access.

## Performance Considerations
One script in the package, XXXX, performs model fitting and training across multiple ecological indicators. This script is computationally intensive and has been designed to support parallel execution across multiple CPU cores to reduce runtime.

Key Notes:

On large datasets (e.g., >500 sites or high spatial resolution), the script may take 30 minutes to several hours to run serially.

It is recommended to use the parallel package or future.apply to distribute processing across 4 or more cores, depending on available system resources.

An example parallel setup is provided in the script documentation.

## Description of the data and file structure 

### GENERAL INFORMATION 
1. Title of Dataset: Global MPA effectiveness framework derived data 
2. Author Information: Clausius, Ella 
3. Date of data collection: 2004-2026
4. Geographic location of data collection: Global

### DATA & FILE OVERVIEW 

File List: 
File 1 Name: 
File 1 Description: 

File 2 Name: 
File 2 Description: 

File 3 Name: 
File 3 Description: 


## Methodological Information

In summary: 

* Shallow reef ecological indicators data: collected via underwater visual census using a 50m transect. Detailed methods are available on the Reef Life Survey methods page: https://reeflifesurvey.com/methods/ and described in *Reef Life Survey: Establishing the Ecological Basis for Conservation of Shallow Marine Life* (Edgar et al., 2020, Biological Conservation).

* Mean SST: Mean sea surface temperature (SST) over the two years preceeding each reef survey, obtained from the National Oceanographic and Atmospheric Administration (NOAA) Coral Reef Watch Programme (https://coralreefwatch.noaa.gov/) 

* Environmental Variables: broad-scale, remotely sensed environmental covariates were obtained from Bio-Oracle (https://www.bio-oracle.org/index.php), representing surface mean values at each site (2000–2020), extracted from rasters with a native resolution of 5-arcmins.

* Human Gravity: calculated using the gravity of human impact model described in *Gravity of Human Impacts Mediates Coral Reef Conservation Gains* (Cinner et al., 2018, PNAS: https://www.pnas.org/doi/10.1073/pnas.1708001115).

* Gross Domestic Product (GDP) per capita: latest available Gross Domestic Product per capita (GDP, in $USD) of the country where the site is located was extracted from the UNdata database (https://data.un.org/Data.aspx?d=SNAAMA&f=grID:101;currID:USD;pcFlag:1;crID:184).

* Human  Development Index (HDI): The 2022 Human Development Index (HDI) score extracted for each reef site from the United Nations Development Data Centre (https://hdr.undp.org/data-center/human-development-index#/indicies/HDI), with regional mean values used when HDI values were unavailable. 

* MPA size, age, level of fishing protection: derived from the ProtectedSeas database (https://navigatormap.org/) or published MPA documentation.

* Compliance: Level of compliance with restrictions on fishing activities, categorised as low, medium or high by divers with experience at each MPA site, defined as “enforcement” in *Global conservation outcomes depend on marine protected areas with five key features* (Edgar et al., 2014, Nature: https://www.nature.com/articles/nature13022). 

---

### DATA-SPECIFIC INFORMATION FOR: dfgdrg .Rdata 
1. Number of variables:  
2. Number of cases/rows:
3. Variable list:
   * rls_site_code: unique Reef Life Survey shallow reef site identifier
   * latitude: latitude in decimal degrees of reef site
   * longitude: longitude in decimal degrees of reef site 
   * depth: mean depth in meters of survey transect
   * sst_mean: Mean sea surface temperature (SST) at the site over the two years preceding the date of survey
   * si_mean: silicate (mmol / m3)
   * par_mean_mean: photosynthetically available radiation (Em2/day).
   * chl_mean:  chlorophyll-a (mmol / m3)
   * no3_mean: nitrate (mmol / m3)
   * po4_mean: phosphate (mmol / m3)
   * kdpar_mean_mean: diffuse attenuation at the surface in meters.
   * dfe_mean: iron (mmol / m3)
   * phyc_mean: phytoplankton (mmol / m3)
   * total_gravity: a measure of how large and far away a human population is to a given reef site, as detailed in Cinner et al., 2018.
   * gdp_per_capita: latest available gross domestic product (GFP) per capita of the country a reef site falls within
   * hdi: latest available human development index (HDI) score for the country a reef site falls within. 
   * total_biomass_log: total reef fish biomass recorded using Underwater Visual Census methods at a given Reef Life Survey site on the last available survey (log10 transformed).



## Code & software 
Six R script files are provided to reproduce the analysis in the corresponding manuscript. All provided R files are described below.

* '00_packages_functions.R': R source code installing necessary packages and defining required functions. 

* '01_geographic_random_forest.R': R source code predicting total reef fish biomass across global shallow reef sites inside MPAs using G-computation and a geographic random forest (GRF) model of total reef fish biomass and 17 socioeconomic, anthropogenic pressure, and broad-scale enviornmental covariates. 

* '02_mpa_random_forest.R': R source code calculating MPA effect sizes for 2,155 shallow reef MPA sites, and relating effect sizes to four MPA factor (compliance with restrictions, level of protection against fishing, MPA age, MPA size) using a non-spatial RF model. 

* '03_global_mpa_effectiveness_predictions.R': R source code predicting  MPA effects across the global shallow reef-encompassing MPA network under four scenarios of MPA age and level of protection against fishing, assuming compliance is universally low or high. 

* '04_Global_MPA_effect_size_density_plot2.R': R source code plotting density of MPA effects across the global shallow reef-encompassing MPA network under the four scenarios. 

* '05_global_MPA_effectiveness_threshold_plot2.R': R source code plotting range in estimates of MPA effectiveness according to a series of biomass recovery thresholds, under the four scenarios of MPA age and level of protection against fishing. 

