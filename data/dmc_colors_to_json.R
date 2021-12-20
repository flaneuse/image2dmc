library(tidyverse)
library(readxl)
library(jsonlite)

df = read_excel("~/GitHub/image2dmc/data/DMC_Embroidery_Floss_Color_Families_2021.xlsx")

df = df %>% 
  mutate(across(starts_with("hex"), ~ str_c("#", .x))) %>% 
  select(-hex_8801_8811_avg) %>% 
  rowwise() %>% 
  mutate(
    row = as.numeric(row),
    column = as.numeric(column),
    hex_8801_8811 = rgb(colorRamp(c(hex_8801, hex_8811))(0.5), max=255),
    hex_8801_8815 = rgb(colorRamp(c(hex_8801, hex_8815))(0.5), max=255),
    hex_8801_8824 = rgb(colorRamp(c(hex_8801, hex_8824))(0.5), max=255),
    hex_8801_scan = rgb(colorRamp(c(hex_8801, hex_scan001))(0.5), max=255),
    hex_8811_8815 = rgb(colorRamp(c(hex_8811, hex_8815))(0.5), max=255),
    hex_8811_8824 = rgb(colorRamp(c(hex_8811, hex_8824))(0.5), max=255),
    hex_8811_scan = rgb(colorRamp(c(hex_8811, hex_scan001))(0.5), max=255),
    hex_8815_8824 = rgb(colorRamp(c(hex_8815, hex_8824))(0.5), max=255),
    hex_8815_scan = rgb(colorRamp(c(hex_8815, hex_scan001))(0.5), max=255),
    hex_8824_scan = rgb(colorRamp(c(hex_8824, hex_scan001))(0.5), max=255),
    mid1 = rgb(colorRamp(c(hex_8815, hex_8801))(0.5), max=255),
    mid2 = rgb(colorRamp(c(hex_8811, hex_8824))(0.5), max=255),
    avg = rgb(colorRamp(c(mid1,mid2))(0.5), max=255))

# Deciding which image is the most "representative"
colors = df %>% 
  filter(!is.na(hex_8815)) %>% 
  select(-name, -mid1, -mid2) %>% 
  gather(key = "key", value="value", -dmc_id)

colors$key = factor(colors$key, c("hex_8811", 
                                  "hex_8811_8815",
                                  "hex_8811_8824",
                                  "hex_8815", 
                                  "hex_8815_8824",
                                  
                                  "hex_8824", 
                                  
                                  "avg", 
                                  "hex_8811_scan",
                                  "hex_8815_scan",
                                  "hex_8801_8811",
                                  "hex_8801_8815",
                                  "hex_8801_8824",
                                  "hex_8824_scan",
                                  "hex_8801",
                                  "hex_8801_scan",
                                  "hex_scan001"
                                  ))

ggplot(colors, aes(x = key, y = dmc_id, fill = value)) +
  geom_tile() +
  scale_fill_identity()

ggplot(colors %>% filter(key %in% c("hex_scan001", "hex_8801", "hex_8811", "hex_8815", "hex_8824", "avg")), 
       aes(x = key, y = dmc_id, fill = value)) +
  geom_tile() +
  scale_fill_identity()

ggplot(colors %>% filter(key %in% c(
                                    "hex_8824", 
                                    "hex_8815_scan",
                                    "hex_8801_8824",
                                    "hex_8824_scan",
                                    "hex_8801",
                                    "hex_8801_scan",
                                    "hex_scan001")), 
       aes(x = key, y = dmc_id, fill = value)) +
  geom_tile() +
  scale_fill_identity()

# 8824 / 8815 / scan?

df %>% 
  filter(! is.na(hex_8824_scan)) %>% 
  select(dmc_id, name, hex = hex_8824_scan, dmc_col = column, dmc_row = row, group = group) %>% 
  jsonlite::write_json("~/GitHub/image2dmc/src/assets/dmc_colors_ldh.json")

df[df %>% select(hex_8824) %>% duplicated(), "hex_8824"]
df[df %>% select(hex_scan001) %>% duplicated(), "hex_scan001"]

df %>% ggplot(aes(x = column, y = row, fill = hex_8824))+
  geom_tile() +
  scale_y_reverse() +
  scale_fill_identity() +
  theme_void()

df %>% ggplot(aes(x = column, y = row, fill = hex_scan001))+
  geom_tile() +
  scale_y_reverse() +
  scale_fill_identity() +
  theme_void()

df %>% ggplot(aes(x = column, y = row, fill = hex_8824_scan))+
  geom_tile() +
  scale_y_reverse() +
  scale_fill_identity() +
  theme_void()

sampled = df %>% ungroup() %>% sample_n(9) 
sampled %>% pull(name)

sampled %>% 
  ggplot(aes(x = column, y = row, fill = hex_8824_scan))+
  geom_tile() +
  scale_y_reverse() +
  scale_fill_identity() +
  theme_void()
