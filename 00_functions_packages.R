# ==============================================================================
# Functions & packages 
# Ella Clausius
# April 2026
# ==============================================================================
# Function to load packages 
using <- function(...) {
  libs <- unlist(list(...))
  req <- unlist(lapply(libs, require, character.only = TRUE))
  need <- libs[req == FALSE]
  if (length(need) > 0) { 
    install.packages(need)
    lapply(need, require, character.only = TRUE)
  }
}


# packages required for the analysis
using("tidyverse", 
      "sf", 
      "raster", 
      "geosphere", 
      'dplyr', 
      "readr",
      "data.table", 
      "janitor", 
      "mgcv", 
      "cowplot", 
      "lubridate", 
      "sf", 
      "terra", 
      "geosphere", 
      "fasterize", 
      "leaflet", 
      "rsample", 
      "parallel", 
      "SpatialML", 
      "future",
      "recipes", 
      "vip", 
      "tune", 
      "ggsankey",
      "parsnip", 
      "workflows", 
      "networkD3", 
      "ranger", 
      "dials", 
      "patchwork", 
      "furrr",
      "factoextra",
      "vegan", 
      "ape", 
      "cluster", 
      "ggh4x"
)

select <- dplyr::select

# Negate 
'%!in%' <- function(x,y)!('%in%'(x,y))


#devtools::install_github("bio-oracle/biooracler")
library(biooracler)


# Function to fit a random forest for each ecological indicator 
fit_rf_metric <- function(metric_name,
                          training_data,
                          prediction_data) {
  
  #------------------------------------------
  # 1. Subset the data for this metric
  #------------------------------------------
  rf_dat <- 
    training_data |> 
    select(#site_code, 
           latitude, 
           longitude, 
           depth,
           sst_mean, 
           sst_min, 
           sst_max, 
           si_mean, 
           par_mean_mean, 
           chl_mean, 
           no3_mean,
           po4_mean, 
           kdpar_mean_mean, 
           dfe_mean, 
           phyc_mean, 
           total_gravity,
           gdp_per_capita,
           hdi, 
           value = all_of(metric_name)) |> 
    drop_na(value) |> 
    ungroup() |> 
   # select(-site_code) |> 
  #   mutate(latitude = round(latitude, 1), 
  #          longitude = round(longitude, 1)) |> 
  #   group_by(latitude, longitude) |> 
  # summarise(across(c(depth:value),  ~mean(., na.rm = TRUE))) |> 
    drop_na() |> 
    as.data.frame()
  
  #------------------------------------------
  # 3. Train/Test split
  #------------------------------------------
  set.seed(456)
  rf_split <- initial_split(rf_dat, prop = 4/5)
  rf_train <- training(rf_split)
  rf_test  <- testing(rf_split)
  
  #------------------------------------------
  # 4. Recipe
  #------------------------------------------
  rf_recipe <- recipe(value ~ ., data = rf_train) |>
    step_impute_mean(all_numeric_predictors()) |>
    step_dummy(all_nominal_predictors())
  
  #------------------------------------------
  # 5. Model specification + tuning
  #------------------------------------------
  tune_spec <- rand_forest(
    trees = tune(),
    mtry = tune(),
    min_n = tune()
  ) |>
    set_mode("regression") |>
    set_engine("ranger", importance = "permutation")
  
  tune_workflow <- workflow() |>
    add_recipe(rf_recipe) |>
    add_model(tune_spec)
  
  #------------------------------------------
  # 6. Cross-validation and grid
  #------------------------------------------
  set.seed(234)
  rf_fold <- vfold_cv(rf_train, v = 10)
  
  set.seed(345)
  rf_grid <- grid_random(
    trees(range = c(100, 2500)),
    mtry(range = c(1, 12)),
    min_n(range = c(10, 30)),
    size = 20
  )
  
  regular_res <- tune_grid(
    tune_workflow,
    resamples = rf_fold,
    grid = rf_grid,
    control = control_grid(save_pred = TRUE)
  )
  
  best_rmse <- select_best(regular_res, metric = "rmse")
  final_workflow <- finalize_workflow(tune_workflow, best_rmse)
  
  #------------------------------------------
  # 7. Final fit + prediction
  #------------------------------------------
  final_res <- last_fit(final_workflow, rf_split)
  trained <- collect_predictions(final_res) |> select(-.row, -.config)
  
  final_model <- extract_fit_parsnip(final_res)
  
  preds <- 
    data.frame(
      metric = metric_name, 
      site_code = prediction_data$site_code, 
      prediction = predict(object = final_model, 
                           prediction_data)$.pred
    )
  
  # Optionally return variable importance plot/model too
  # vip(final_model)
  
  return(list(
    metric = metric_name,
    predictions = preds,
    model = final_model
  ))
}
