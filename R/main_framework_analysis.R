# ==============================================================================
# Analysis for: Defining and measuring global marine protected area effectiveness   
# Ella Clausius
# April 2026
# ==============================================================================

# ------------------------------------------------------------------------------
# SETUP
# ------------------------------------------------------------------------------

# Load all required packages and custom helper functions used throughout analysis
source("R/00_functions_packages.R")

# Read dataset containing activity restriction scores for each MPA zone
# Each column represents an activity; values indicate restriction level (0–2)
mpa_activity_restrictions <- 
  read_csv("data/protected_seas_activity_restrictions.csv")


# ------------------------------------------------------------------------------
# LOAD ECOLOGICAL PATHWAY DATA
# ------------------------------------------------------------------------------

# Read in pathway relationships describing how human pressures propagate
# through ecological components (source → target with weighted strength)
path_dat <-
  read_csv("data/path_scores.csv", 
           show_col_types = FALSE)


# ==============================================================================
# MPA ZONES BY ACTIVITY RESTRICTION
# ==============================================================================

# Goal: quantify which activities are most commonly restricted across MPAs,
# and group them into broader ecological impact categories

mpa_activity_restrictions |> 
  
  # Convert wide dataset (activities as columns) to long format
  pivot_longer(cols = recreational_fishing:overflight_or_drones,
               names_to = "activity",
               values_to = "score") |> 
  
  # Convert restriction scores to binary indicator
  mutate(restricted = case_when(
    score == 0 ~ 0,                  # no restriction
    score %in% c(1, 2) ~ 1,          # restricted
    TRUE ~ NA_real_
  )) |> 
  
  # Keep only restricted activities
  filter(restricted == 1) |> 
  
  # Remove duplicate activity–site combinations
  unique() |> 
  
  # Count number of MPAs restricting each activity
  group_by(activity) |> 
  summarise(n = n()) |> 
  
  # Assign each activity to an ecological impact category
  mutate(category = case_when(
    activity %in% c("aquaculture", 
                    "discharge", 
                    "non_fishing_industr_extraction") ~ "Pollution", 
    
    activity %in% c("anchoring",
                    "diving",
                    "construction", 
                    "dragging") ~ "Habitat destruction", 
    
    activity %in% c("drilling", 
                    "dredging_dumping",
                    "entry", 
                    "industr_or_mineral_exploration", 
                    "landing", 
                    "mooring", 
                    "overflight_or_drones", 
                    "removal_of_historic_artifacts", 
                    "speed", 
                    "stopping") ~ "Multiple (non-fishing-related)", 
    
    TRUE ~ "Fishing-related"
  )) |> 
  
  # Plot frequency of restricted activities
  ggplot(aes(x = reorder(activity, -n),
             y = n, 
             fill = factor(category, 
                           levels = c("Fishing-related",
                                      "Habitat destruction", 
                                      "Pollution", 
                                      "Multiple (non-fishing-related)"))
  )) +
  geom_bar(stat = "identity") +
  labs(fill = "Primary type of impact addressed:") +
  scale_fill_manual(values = rev(c(
    "#dcecc4", 
    "#7bccc4", 
    "#1d4380", 
    "#3f8cc2"))) +
  theme(axis.ticks = element_blank(),
        axis.text = element_text(face = "plain", color = "black", 
                                 size = 8),
        axis.title = element_text(face = "plain", size = rel(1.33)),
        axis.title.x = element_text(margin = ggplot2::margin(0.5, 0, 0, 0, 
                                                             unit = "cm")),
        axis.text.x = element_text(angle = 45, 
                                   vjust = 0.95, 
                                   hjust = 1, 
                                   size = rel(1.66)), 
        
        axis.title.y = element_text(margin = ggplot2::margin(0, 0.5, 0, 0, 
                                                             unit = "cm"), 
                                    angle = 90),
        plot.title = element_text(face = "plain", size = rel(1.67), hjust = 0),
        axis.line = element_line(colour = "black"), 
        plot.title.position = "plot",
        plot.background = element_rect(fill = "#ffffff", color = NA),
        panel.background = element_rect(fill = "#ffffff", color = NA),
        panel.grid.major =  element_line(color = "#ffffff"),
        strip.background = element_blank(),
        strip.text = element_text(size = rel(1.5), face = "plain", hjust = 0), 
        legend.position = "bottom", 
        plot.margin = ggplot2::margin(1,1,1,30), 
        legend.title.position = "left", 
        legend.text = element_text(size = rel(1))
  ) +
  xlab(element_blank()) +
  ylab("Total MPA zones")


# ==============================================================================
# HIERARCHICAL CLUSTERING ANALYSIS
# ==============================================================================

# Goal: identify groups of MPAs with similar restriction profiles

# Compute Manhattan distance across restriction variables
dist_mat <- dist(mpa_activity_restrictions[-1], 
                 method = "manhattan")

# Perform hierarchical clustering using average linkage
hclust_avg <- hclust(dist_mat, 
                     method = 'average')

# Plot dendrogram to visualise clustering structure
plot(hclust_avg)

# ------------------------------------------------------------------------------
# Determine optimal number of clusters
# ------------------------------------------------------------------------------

k_range <- 2:10

# Compute mean silhouette width for each k
sil_width <- sapply(k_range, function(k) {
  cl <- cutree(hclust_avg, k)
  mean(cluster::silhouette(cl, 
                           dist_mat)[, 3])
})

# Plot silhouette results
plot(
  k_range,
  sil_width,
  type = "b",
  pch = 19,
  xlab = "Number of clusters (k)",
  ylab = "Mean silhouette width"
)

# Elbow method using merge height differences
merge_diffs <- diff(rev(hclust_avg$height))

plot(
  merge_diffs,
  type = "h",
  xlab = "Merge step (from root)",
  ylab = "Increase in merge height",
  main = "Elbow plot of merge heights"
)

# Assign clusters (k = 2)
cut_avg <- cutree(hclust_avg, 
                  k = 2)

clusters <- mutate(mpa_activity_restrictions,
                   cluster = cut_avg) 

# ------------------------------------------------------------------------------
# Visualise restriction profiles by cluster
# ------------------------------------------------------------------------------

clusters |> 
  mutate(cluster = as.factor(cluster)) |> 
  
  pivot_longer(cols = recreational_fishing:overflight_or_drones, 
               names_to = "restriction", 
               values_to = "value") |> 
  
  # Rename for plotting readability
  mutate(restriction = case_when(
    restriction == "anchoring" ~ "Anchoring (ANCH)", 
    restriction == "aquaculture" ~ "Aquaculture (AQUA)", 
    restriction == "artisanal_fishing" ~ "Artisanal fishing (ARTF)", 
    restriction == "bottom_trawling" ~ "Bottom trawling (BTR)", 
    restriction == "cast_nets" ~ "Cast nets (CAST)", 
    restriction == "commercial_fishing" ~ "Commercial fishing (COMF)", 
    restriction == "construction" ~ "Construction (CONST)", 
    restriction == "discharge" ~ "Discharge (DISCH)",
    restriction == "diving" ~ "Diving (DIVE)", 
    restriction == "dredging_dumping" ~ "Dreding and dumping (DREDD)",
    restriction == "entry" ~ "Entry (ENTRY)", 
    restriction == "fish_aggregating_devices" ~ "Fish aggregation devices (FAD)", 
    restriction == "gillnets_entangling_nets" ~ "Gillnets (GN)",
    restriction == "hand_capture" ~ "Hand capture (HAND)", 
    restriction == "industr_or_mineral_exploration" ~ "Industrial or mineral exploration (IMEX)", 
    restriction == "landing" ~ "Landing (LAND)", 
    restriction == "hook_and_line" ~ "Hook & line fishing (HL)", 
    restriction == "longlining" ~ "Longlining (LL)", 
    restriction == "mooring" ~ "Mooring (MOOR)", 
    restriction == "non_fishing_industr_extraction" ~ "Non-fishing industrial extraction (NFEX)", 
    restriction == "other_nets" ~ "Other nets (ONET)", 
    restriction == "overflight_or_drones" ~ "Overflight or drones (OVER)", 
    restriction == "pelagic_trawling" ~ "Pelagic trawling (PTR)", 
    restriction == "purse_seine_rndhaul_surrd_nets" ~ "Purse & seine nets (PS)", 
    restriction == "recreational_fishing" ~ "Recreational fishing (RECF)", 
    restriction == "removal_of_historic_artifacts" ~ "Removal of historic artifacts (HIST)", 
    restriction == "dip_scoop_nets" ~ "Dip & scoop nets (DIPN)", 
    restriction == "traps_and_pots" ~ "Traps & pots (TP)", 
    restriction == "spear_fishing" ~ "Spear fishing (SPEAR)", 
    restriction == "subsistence_fishing" ~ "Subsistence fishing (SUBF)", 
    restriction == "trolling" ~ "Trolling (TROLL)", 
    restriction == "speed" ~ "Speed (SPEED)", 
    restriction == "stopping" ~ "Stopping (STOP)", 
    restriction == "underwater_extraction_diving" ~ "Underwater extraction (diving) (UWEX)", 
    TRUE ~ restriction)) |> 
  
  group_by(cluster, restriction) |>
  summarise(mean = mean(value)) |> 
  
  ggplot() + 
  ggtitle("b)") +
  geom_tile(aes(y = restriction, 
                x = factor(cluster, 
                           levels = c(1, 2), 
                           labels = c("Cluster 1", 
                                      "Cluster 2")), 
                fill = mean)) +
  scale_fill_continuous(low = "#f7fcf0",
                        high = "#3d8bc1") + 
  labs(fill = "Mean restriction level")+ 
  ylab("Activity restriction") + 
  theme(axis.ticks = element_blank(),
        title = element_text(colour = "#1e427f"),
        axis.text = element_text(face = "plain", 
                                 color = "#1e427f", 
                                 size = 15),
        axis.title = element_text(face = "plain", 
                                  size = rel(1.66)),
        axis.title.y = element_text(margin = ggplot2::margin(0, 0.5, 0, 0, 
                                                             unit = "cm"), 
                                    angle = 90, 
                                    colour = "#1e427f"),
        plot.title = element_text(face = "plain", 
                                  size = rel(1.67), 
                                  hjust = 0),
        axis.line = element_line(colour = "#1e427f"), 
        plot.title.position = "plot",
        plot.background = element_rect(fill = "#ffffff", 
                                       color = NA),
        panel.background = element_rect(fill = "#ffffff", 
                                        color = NA),
        panel.grid.major =  element_line(color = "#ffffff"),
        strip.background = element_blank(),
        strip.text = element_text(size = rel(1.5), 
                                  face = "plain", 
                                  hjust = 0), 
        axis.title.x = element_blank(), 
        plot.margin = ggplot2::margin(1, 1, 1, 1),  
        legend.title.position = "top",
        legend.text = element_text(size = rel(1), 
                                   colour = "#1e427f"), 
        legend.title = element_text(size = rel(1.2),
                                    colour = "#1e427f"), 
        legend.direction = "horizontal",
        legend.position = "bottom"
  ) 


# ==============================================================================
# PRINCIPAL COORDINATES ANALYSIS (PCoA)
# ==============================================================================

# Goal: visualise multivariate differences among MPAs based on restrictions

# Compute Gower distance (appropriate for ordinal/mixed data)
d <- daisy(
  mpa_activity_restrictions[2:ncol(mpa_activity_restrictions)],
  metric = "gower",
  type = list(ordratio = 
                colnames(mpa_activity_restrictions[2:ncol(mpa_activity_restrictions)]))
)

# Run PCoA
pcoa <- pcoa(d)

# Extract variance explained
var_explained <- pcoa$values$Relative_eig
var_explained_pct <- var_explained * 100

# Extract first two axes and attach cluster labels
pcoa_df  <- 
  as.data.frame(pcoa$vectors[, 1:2]) |>
  
  rename(PCoA1 = Axis.1, PCoA2 = Axis.2) %>%
  
  # add clusters to split data
  cbind(., clusters |> select(site_id, cluster)) |> 
  
  mutate(cluster = as.factor(cluster))

# Fit environmental vectors (restriction variables)
ef <- envfit(
  pcoa$vectors[, 1:2],
  clusters,
  permutations = 999
)

# Prepare vectors for plotting
arrows_df <- 
  as.data.frame(ef$vectors$arrows * sqrt(ef$vectors$r)) %>%
  rownames_to_column("restriction") |> 
  select(PCoA1 = Axis.1, 
         PCoA2 = Axis.2, 
         restriction) |> 
  filter(restriction != "cluster") |> 
  mutate(restriction = case_when(
    restriction == "anchoring" ~ "ACNH", 
    restriction == "aquaculture" ~ "AQUA", 
    restriction == "artisanal_fishing" ~ "ARTF", 
    restriction == "bottom_trawling" ~ "BTR", 
    restriction == "cast_nets" ~ "CAST", 
    restriction == "commercial_fishing" ~ "COMF", 
    restriction == "construction" ~ "CONST", 
    restriction == "discharge" ~ "DISCH",
    restriction == "diving" ~ "DIVE", 
    restriction == "dredging_dumping" ~ "DREDD",
    restriction == "entry" ~ "ENTRY", 
    restriction == "fish_aggregating_devices" ~ "FAD", 
    restriction == "gillnets_entangling_nets" ~ "GN",
    restriction == "hand_capture" ~ "HAND", 
    restriction == "industr_or_mineral_exploration" ~ "IMEX", 
    restriction == "landing" ~ "LAND", 
    restriction == "hook_and_line" ~ "HL", 
    restriction == "longlining" ~ "LL", 
    restriction == "mooring" ~ "MOOR", 
    restriction == "non_fishing_industr_extraction" ~ "NFEX", 
    restriction == "other_nets" ~ "ONET", 
    restriction == "overflight_or_drones" ~ "OVER", 
    restriction == "pelagic_trawling" ~ "PTR", 
    restriction == "purse_seine_rndhaul_surrd_nets" ~ "PS", 
    restriction == "recreational_fishing" ~ "RECF", 
    restriction == "removal_of_historic_artifacts" ~ "HIST", 
    restriction == "dip_scoop_nets" ~ "DIPN", 
    restriction == "traps_and_pots" ~ "TP", 
    restriction == "tribal" ~ "TRIB",
    restriction == "subsistence_fishing" ~ "SUBF", 
    restriction == "trolling" ~ "TROLL", 
    restriction == "underwater_extraction_diving" ~ "UWEX", 
    TRUE ~ restriction)) 

# Plot PCoA
ggplot() + 
  geom_hline(yintercept = 0, 
             linetype = "dashed", 
             colour = "#0f2d4e") + 
  geom_vline(xintercept = 0, 
             linetype = "dashed", 
             colour = "#0f2d4e") +
  geom_point(data = pcoa_df, 
             aes(x = PCoA1, 
                 y = PCoA2, 
                 colour = cluster,
                 fill = cluster, 
                 group = cluster),
             alpha = 0.5
  ) + 
  stat_ellipse(data = pcoa_df, 
               aes(x = PCoA1, 
                   y = PCoA2, 
                   colour = cluster,
                   fill = cluster, 
                   group = cluster), 
               alpha = 0.2,
               type = "norm",
               geom = "polygon", 
               linewidth = 0.8)  +
  geom_segment(data = arrows_df, 
               aes(x = 0, 
                   y = 0, 
                   xend = PCoA1, 
                   yend = PCoA2),
               arrow = arrow(length = unit(0.2, "cm")), 
               color = "#0f2d4e") +
  geom_text(data = arrows_df, 
            aes(x = PCoA1, 
                y = PCoA2, 
                label = restriction),
            hjust = .1, 
            vjust = .1, 
            size = 3.5, 
            colour = "#0f2d4e") +
  ggtitle("a)") + 
  labs(colour = "Cluster", 
       fill = "Cluster") + 
  coord_fixed() + 
  ylab("PCoA2 - Percent variance explained 10.2%") + 
  xlab("PCoA1 - Percent variance explained 82.2%") + 
  scale_colour_manual(values = c("#3d8bc1", "#97dd9e")) +
  scale_fill_manual(values = c("#3d8bc1", "#97dd9e")) +
  theme(axis.ticks = element_blank(),
        title = element_text(colour = "#1e427f"), 
        axis.text = element_text(face = "plain", color = "#1e427f", 
                                 size = 10),
        axis.title = element_text(face = "plain", size = rel(1.33)),
        axis.title.x = element_text(margin = ggplot2::margin(0.5, 0, 0, 0, 
                                                             unit = "cm"), 
                                    size = rel(1.1), 
                                    colour = "#1e427f"),
        axis.title.y = element_text(margin = ggplot2::margin(0, 0.5, 0, 0, 
                                                             unit = "cm"), 
                                    angle = 90,
                                    size = rel(1.1), 
                                    colour = "#1e427f"),
        plot.title = element_text(face = "plain", size = rel(1.67), hjust = 0),
        axis.line = element_line(colour = "#1e427f"), 
        plot.title.position = "plot",
        plot.background = element_rect(fill = "#ffffff", color = NA),
        panel.background = element_rect(fill = "#ffffff", color = NA),
        plot.margin = ggplot2::margin(1,20,1,1), 
        panel.border = element_rect(
          colour = "#0f2d4e",
          fill = NA,
          linewidth = 0.5
        ), 
        panel.grid.major =  element_line(color = "#ffffff"),
        strip.background = element_blank(),
        strip.text = element_text(size = rel(1.33), face = "plain", hjust = 0, 
                                  colour = "#1e427f"), 
        legend.position = "bottom", 
        legend.direction = "vertical") 


# ==============================================================================
# PATH SCORES FOR EACH MPA ZONE
# ==============================================================================

# Goal: translate activity restrictions into ecological outcomes using pathways

ps_paths_combined <- NULL 


ps_path_scores <- 
  mpa_activity_restrictions |> 
  select(site_id,
         Anchoring = anchoring,
         Aquaculture = aquaculture,
         `Artisanal fishing` = artisanal_fishing,
         `Bottom trawling` = bottom_trawling,
         `Cast nets` = cast_nets,
         `Commercial fishing` = commercial_fishing,
         Construction = construction,
         Discharge = discharge,
         Diving = diving,
         `Dredging and dumping` = dredging_dumping,
         Entry = entry,
         `Fish aggregation devices` = fish_aggregating_devices,
         Gillnets = gillnets_entangling_nets,
         `Hand capture` = hand_capture,
         `Industrial or mineral exploration` = industr_or_mineral_exploration,
         Landing = landing,
         `Line fishing` = hook_and_line,
         Longlining = longlining,
         Mooring = mooring,
         `Non-fishing industrial extraction` = non_fishing_industr_extraction,
         `Other nets` = other_nets,
         `Overflight or drones` = overflight_or_drones,
         `Pelagic trawling` = pelagic_trawling,
         `Purse nets` = purse_seine_rndhaul_surrd_nets,
         `Recreational fishing` = recreational_fishing,
         `Removal of historic artifacts` = removal_of_historic_artifacts,
         `Scoop nets` = dip_scoop_nets,
         `Spear fishing` = spear_fishing,
         Speed = speed,
         Stopping = stopping,
         `Subsistence fishing` = subsistence_fishing,
         `Traps and pots` = traps_and_pots,
         Trolling = trolling,
         `Underwater extraction (diving)` = underwater_extraction_diving) |>
  pivot_longer(cols = Anchoring:`Underwater extraction (diving)`,
               names_to = "activity",
               values_to = "score") |>
  mutate(score = case_when(score == 0 ~ 0,
                           score %in% c(1, 2) ~ 1,
                           TRUE ~ NA_real_)) 
  
# Loop through each site
for (i in 1:length(unique(ps_path_scores$site_id))) { 
  
  this_site <- unique(ps_path_scores$site_id)[[i]]
  
  # Extract restricted activities
  ps_dat <-
    ps_path_scores |> 
    filter(site_id == this_site) |> 
    filter(score != 0) 
  
  # Map to ecological pathways
  ps_path <- 
    path_dat |> 
    filter(source_node %in% ps_dat$activity) |>
    filter(weight != 0) |> 
    group_by(target_node) |> 
    mutate(total_input = sum(weight), 
           site_id = this_site) |> 
    select(site_id, target_node, total_weight = total_input) |> 
    unique()
  
  ps_paths_combined[[i]] <- ps_path
}

# Combine all sites
ps_scores_all <-
  do.call("rbind", ps_paths_combined)

# Plot ecological impact scores
ps_scores_all |>
  group_by(site_id) |> 
  mutate(total_in = sum(total_weight), 
         prop_total = total_weight/total_in*100) |>
  
  left_join(clusters |> 
              select(site_id, cluster) |> 
              unique()) |> 
  
  group_by(target_node, cluster) |> 
  
  summarise(mean = mean(prop_total)) %>%
  
  # add summary for all sites 
  rbind(., ps_scores_all |> 
          select(site_id, target_node, total_weight) |> 
          unique() |> 
          group_by(site_id) |> 
          mutate(total_in = sum(total_weight), 
                 prop_total = total_weight/total_in*100) |> 
          group_by(target_node) |> 
          summarise(mean = mean(prop_total)) |> 
          mutate(cluster = 0)) |> 
  
  mutate(mean = round(mean, 0)) |> 
  
  ggplot() +
  geom_point(aes(x = factor(cluster, 
                            levels = c(0, 1, 2),
                            labels = c("All", "Cluster 1", "Cluster 2")), 
                 y = factor(target_node, 
                            levels = rev(c("Water column algae & invertebrates", 
                                           "Benthic habitat-formers", 
                                           "Mobile epifauna & infauna", 
                                           "Small fishes", 
                                           "Large fishes (20cm+)", 
                                           "Seabirds, reptiles & mammals"))), 
                 size = mean, 
                 colour = factor(target_node, 
                                 levels = rev(c("Water column algae & invertebrates", 
                                                "Benthic habitat-formers", 
                                                "Mobile epifauna & infauna", 
                                                "Small fishes", 
                                                "Large fishes (20cm+)", 
                                                "Seabirds, reptiles & mammals")))
  )) + 
  geom_text(aes(x = factor(cluster, 
                           levels = c(0, 1, 2),
                           labels = c("All", "Cluster 1", "Cluster 2")), 
                y = factor(target_node, 
                           levels = rev(c("Water column algae & invertebrates", 
                                          "Benthic habitat-formers", 
                                          "Mobile epifauna & infauna", 
                                          "Small fishes", 
                                          "Large fishes (20cm+)", 
                                          "Seabirds, reptiles & mammals"))), 
                label = mean), 
            colour = "#084081", 
            size = 4
  ) + 
  scale_colour_manual(values = c("#f0f9e8", 
                                 "#ccebc5", 
                                 "#a8ddb5", 
                                 "#7bccc4", 
                                 "#43a2ca", 
                                 "#0868ac"))  +
  scale_size_continuous(range = c(4, 16)) + 
  theme(axis.ticks = element_blank(),
        axis.text = element_text(face = "plain", color = "black", 
                                 size = 8),
        axis.title = element_text(face = "plain", size = rel(1.33)),
        axis.title.x = element_text(margin = ggplot2::margin(0.5, 0, 0, 0, 
                                                             unit = "cm")),
        axis.text.x = element_text(vjust = 0.95, hjust = 1, 
                                   size = rel(1.66)), 
        
        axis.title.y = element_text(margin = ggplot2::margin(0, 0.5, 0, 0, 
                                                             unit = "cm"), 
                                    angle = 90),
        plot.title = element_text(face = "plain", size = rel(1.67), hjust = 0),
        axis.line = element_line(colour = "black"), 
        plot.title.position = "plot",
        plot.background = element_rect(fill = "#ffffff", color = NA),
        panel.background = element_rect(fill = "#ffffff", color = NA),
        panel.grid.major =  element_line(color = "#ffffff"),
        strip.background = element_blank(),
        strip.text = element_text(size = rel(1.33), face = "plain", hjust = 0), 
        legend.position = "none", 
        legend.title.position = "left") + 
  ylab("Ecosystem group") + 
  xlab(element_blank())



# ==============================================================================
# Run RF for each shallow reef metric 
# ==============================================================================

metrics <- c(
  "large_fish_bio", 
  "large_fish_abund", 
  "large_fish_richness", 
  "small_fish_bio", 
  "small_fish_abund", 
  "small_fish_richness", 
  "invert_richness",
  "invert_abundance",
  "live_coral",
  "kelp_cover"
)

# ------------------------------------------------------------------------------
# LOAD ECOLOGICAL INDICATOR DATA 
# ------------------------------------------------------------------------------

rf_training_dat <- 
  read_csv("data/rf_training_data.csv", 
           show_col_types = FALSE)

rf_prediction_dat <- 
  read_csv("data/rf_effect_size_prediction_data.csv", 
           show_col_types = FALSE)


# Map of training (fished) and MPA sites ---------------------------------------
world_coordinates <- 
  map_data("world")

# Shallow reef sites 
sites <-
  rf_prediction_dat |> 
  select(site_code, latitude, longitude) |> 
  mutate(site = "MPA") %>%
  bind_rows(., rf_training_dat |> 
              select(site_code, latitude, longitude) |> 
              mutate(site = "Non-MPA")) 

ggplot() + 
  geom_map(
    data = world_coordinates,
    map = world_coordinates,
    aes(x = long, 
        y = lat,
        map_id = region), 
    fill = "#e0e0e0", 
    alpha = 0.9) +
  geom_point(data = sites[sites$site == "Non-MPA",], 
             aes(x = longitude, y = latitude, 
                 colour = factor(site, 
                                 levels = c("Non-MPA"))), 
             size = 1, 
             alpha = 0.5) + 
  geom_point(data = sites[sites$site == "MPA", ], 
             aes(x = longitude, y = latitude, 
                 colour = factor(site, 
                                 levels = c("MPA"))), 
             size = 1, 
             alpha = 0.5) + 
  scale_colour_manual(values = c("#a8ddb5",
                                 "#084081"
  ))  +
  labs(colour = "Reef sites:") + 
  ylab(element_blank()) +
  xlab(element_blank()) + 
  theme(axis.ticks = element_blank(),
        axis.text = element_blank(),
        axis.title = element_blank(),
        axis.title.x = element_blank(),
        axis.text.x = element_blank(), 
        
        axis.title.y = element_blank(),
        plot.title = element_text(face = "plain", size = rel(1.67), hjust = 0),
        axis.line = element_blank(), 
        plot.title.position = "plot",
        plot.background = element_rect(fill = "#ffffff", color = NA),
        panel.background = element_rect(fill = "#ffffff", color = NA),
        panel.grid.major =  element_line(color = "#ffffff"),
        strip.background = element_blank(),
        strip.text = element_text(size = rel(1.33), face = "plain", hjust = 0), 
        legend.position = "bottom",
        legend.text = element_text(size = 10), 
        legend.direction = "horizontal") + 
  coord_fixed()



# ------------------------------------------------------------------------------
# RUN RANDOM FOREST FOR EACH METRIC 
# ------------------------------------------------------------------------------

# set up multicore plan ONCE
future::plan(multicore, 
             workers = parallel::detectCores() - 1)

# parallel map
results <- 
  furrr::future_map(metrics, 
                    fit_rf_metric, 
                    training_data = rf_training_dat, 
                    prediction_data =  rf_prediction_dat) 

# Combine predictions 
all_predictions <- 
  bind_rows(lapply(results, `[[`, "predictions"))


# Extract models
models <- 
  setNames(lapply(results, `[[`, "model"), metrics)

model_fits <- 
  data.frame(
    metric = metrics, 
    model_fit = c(round(models$large_fish_bio$fit$r.squared*100, 0),
                  round(models$large_fish_abund$fit$r.squared*100, 0), 
                  round(models$large_fish_richness$fit$r.squared*100, 0), 
                  round(models$small_fish_bio$fit$r.squared*100, 0), 
                  round(models$small_fish_abund$fit$r.squared*100, 0), 
                  round(models$small_fish_richness$fit$r.squared*100, 0), 
                  round(models$invert_richness$fit$r.squared*100, 0), 
                  round(models$invert_abundance$fit$r.squared*100, 0), 
                  round(models$live_coral$fit$r.squared*100, 0), 
                  round(models$kelp_cover$fit$r.squared*100, 0)))

knitr::kable(model_fits, 
             col.names = c("Metric", 
                           "Model Fit R^2 (%)"))

effect_sizes <- 
  all_predictions |> 
  left_join(rf_prediction_dat |> 
              select(site_code, 
                     latitude,
                     longitude, 
                     compliance, 
                     protected_seas_id,
                     level_fishing_protection, 
                     large_fish_bio:live_coral) |>
              pivot_longer(cols = large_fish_bio:live_coral,
                           names_to = "metric",
                           values_to = "raw_value")) |> 
  group_by(protected_seas_id, site_code, level_fishing_protection, 
           compliance, metric) |> 
  summarise(observed = mean(raw_value, na.rm = T),
            predicted = mean(prediction, na.rm = T)) |> 
  mutate(
    effect_size = case_when(
      metric %in% c("large_fish_bio", 
                    "large_fish_abund", 
                    "small_fish_bio", 
                    "small_fish_abund", 
                    "invert_abundance") ~ (observed - predicted), 
      TRUE ~ log10((observed+0.1)/ (predicted + 0.1))
    )) |> 
  left_join(clusters |> select(protected_seas_id = site_id, 
                               cluster)) |> 
  drop_na(cluster)
  
#calculate mean node size 
ps_scores_all |> 
  select(site_id,
         target_node, 
         total_weight) |> 
  unique() |> 
  filter(site_id %in% effect_sizes$protected_seas_id) |> 
  group_by(site_id) |> 
  mutate(total_in = sum(total_weight), 
         prop_total = total_weight/total_in*100) |> 
  left_join(clusters |> 
              select(site_id, cluster) |> 
              unique()) |> 
  group_by(target_node, cluster) |> 
  summarise(mean = mean(prop_total)) |> 
  
  mutate(mean = round(mean, 0))


effect_size_plot_dat <- 
  effect_sizes |> 
  filter((level_fishing_protection == 5 & compliance == "High") | 
           (level_fishing_protection != 5)) |>
  mutate(compliance = case_when(level_fishing_protection == 5 ~ "High", 
                                TRUE ~ "Low")) |> 
  drop_na(effect_size) |> 
  group_by(cluster, compliance, metric, protected_seas_id) |> 
  summarise(effect_size = mean(effect_size)) |> 
  group_by(cluster, compliance, metric) |> 
  mutate(n = n(),
         mean = mean(effect_size), 
         sd = sd(effect_size),
         se = sd/sqrt(n)) |> 
  select(cluster, compliance, metric, n, mean, se) |> 
  distinct() |> 
  mutate(upper = 10^(mean + qt(0.975,df = n - 1)*se), 
         lower = 10^(mean - qt(0.975,df = n - 1)*se), 
         mean = 10^mean) |> 
  mutate(category = case_when(
    metric %in% c("large_fish_bio", 
                  "large_fish_abund", 
                  "large_fish_richness") ~ "Large fish",
    
    metric %in% c("small_fish_bio", 
                  "small_fish_abund", 
                  "small_fish_richness") ~ "Small fish",
    
    TRUE ~ "Benthic communities"
  ))


pd <- 
  position_dodge(width = 0.6)

effect_size_plot_dat |>
  
  ggplot(aes(
    y = factor(metric,
               levels = rev(c("large_fish_bio", 
                              "large_fish_abund", 
                              "large_fish_richness",
                              "small_fish_bio", 
                              "small_fish_abund", 
                              "small_fish_richness",
                              "cf_richness", 
                              "invert_abundance", 
                              "invert_richness",
                              "live_coral", 
                              "kelp_cover")),
               labels = rev(c("Large fish biomass", 
                              "Large fish abundance", 
                              "Large fish richness",
                              "Small fish biomass",
                              "Small fish abundance", 
                              "Small fish richness",
                              "Cryptic fish richness", 
                              "Invert abundance",
                              "Invert richness",
                              "Coral cover",
                              "Kelp cover"))),
    x = mean,
    colour = factor(compliance, 
                    levels = rev(c("High", "Low"))),
    group = factor(compliance, 
                   levels = rev(c("High", "Low")))
  )) +
  
  geom_vline(xintercept = 1, 
             linetype = "dashed",
             colour = "grey50") +
  
  geom_point(position = pd, size = 2.5) +
  
  geom_linerange(
    aes(xmin = lower, xmax = upper),
    position = pd,
    linewidth = 0.6
  ) +
  
  geom_text(aes(x = 5, 
                y = factor(metric,
                           levels = rev(c("large_fish_bio",
                                          "large_fish_abund", 
                                          "large_fish_richness",
                                          "small_fish_bio", 
                                          "small_fish_abund", 
                                          "small_fish_richness",
                                          "cf_richness", 
                                          "invert_abundance", 
                                          "invert_richness",
                                          "live_coral", 
                                          "kelp_cover")),
                           labels = rev(c("Large fish biomass",
                                          "Large fish abundance",
                                          "Large fish richness",
                                          "Small fish biomass",
                                          "Small fish abundance",
                                          "Small fish richness",
                                          "Cryptic fish richness", 
                                          "Invert abundance", 
                                          "Invert richness",
                                          "Coral cover", 
                                          "Kelp cover"))), 
                label = n, 
                colour = factor(compliance, 
                                levels = rev(c("High", "Low"))),
                group = factor(compliance, 
                               levels = rev(c("High", "Low"))))) + 
  scale_x_log10(
    breaks = c(0.5, 1, 2, 4),
    labels = c("0.5", "1", "2", "4") 
  ) +
  guides(colour = guide_legend("Compliance")) + 
  scale_color_manual(values = c("Low" = "#fc8d59",
                                "High" = "#91bfdb")) +   
  theme_bw() + 
  theme(axis.ticks = element_blank(),
        axis.text = element_text(face = "plain", color = "black", 
                                 size = 10),
        axis.title = element_text(face = "plain", size = rel(1.33)),
        axis.title.x = element_text(margin = ggplot2::margin(0.5, 0, 0, 0, 
                                                             unit = "cm")),
        axis.text.x = element_text(angle = 45, vjust = 0.95, hjust = 1), 
        axis.title.y = element_text(margin = ggplot2::margin(0, 0.5, 0, 0, 
                                                             unit = "cm"), 
                                    angle = 90),
        plot.title = element_text(face = "plain", size = rel(1.67), hjust = 0),
        axis.line = element_line(colour = "black"), 
        plot.title.position = "plot",
        plot.background = element_rect(fill = "#ffffff", color = NA),
        panel.background = element_rect(fill = "#ffffff", color = NA),
        panel.grid.major =  element_line(color = "#ffffff"),
        strip.background = element_blank(),
        strip.text = element_text(size = rel(1.33), face = "plain", hjust = 0)
  ) + 
  ylab("Mean effect size") +
  xlab("Indicator") +
  facet_wrap2(
    ~factor(cluster, 
            levels = c(1, 2), labels = c("Cluster 1", "Cluster 2")),
    ncol = 1
  )  



