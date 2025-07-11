library(tidyverse)
library(jsonlite)

# read csv
school_district_data <- read_csv("input/all_schooldistricts_2023.csv")
school_district_data <- school_district_data[, -1]

# filter for only 2023 data, standardize names
school_district_data <- school_district_data |>
  filter(year == 2023) |>
  rename(
    state_abbr = state.abb,
    state_name = state.name,
    entity_id = id,
    document_url = url,
    entity_name = name,
    entity_type = category,
    total_revenues = revenues,
    total_expenses = expenses,
    student_enrollment = enrollment_23
  )|>
  mutate(
    non_net_pension_liability = net_pension_liability,
    non_net_opeb_liability = net_opeb_liability
  ) |>
  # create net net pension and opeb liabilities
  mutate(
    net_pension_assets = ifelse(is.na(net_pension_assets), 0, net_pension_assets),
    net_opeb_assets = ifelse(is.na(net_opeb_assets), 0, net_opeb_assets),
    net_pension_liability = ifelse(is.na(net_pension_liability), 0, net_pension_liability),
    net_opeb_liability = ifelse(is.na(net_opeb_liability), 0, net_opeb_liability),
    net_net_pension_liability = net_pension_liability - net_pension_assets,
    net_net_opeb_liability = net_opeb_liability - net_opeb_assets
  ) |>
  mutate(
    pension_liability = net_net_pension_liability,
    opeb_liability = net_net_opeb_liability
  ) |>
  # net position
  mutate(
    net_position = total_assets - total_liabilities
  ) |>
  # debt ratio
  mutate(
    debt_ratio = total_liabilities / total_assets
  ) |>
  # free cash flow
  mutate(
    free_cash_flow = total_revenues - (total_expenses + current_liabilities)
  ) |>
  # current ratio
  mutate(
    current_ratio = current_assets / current_liabilities
  ) |>
  # non_current_liabilities
  mutate(
    non_current_liabilities = total_liabilities - current_liabilities
  ) |>
  # Add sum of bonds, loans, and notes
  mutate(
    bond_loans_notes = ifelse(is.na(bonds_outstanding), 0, bonds_outstanding) + 
                     ifelse(is.na(loans_outstanding), 0, loans_outstanding) + 
                     ifelse(is.na(notes_outstanding), 0, notes_outstanding)
  ) |>
  mutate(
    population = ifelse(is.na(student_enrollment), 0, student_enrollment),
  )


school_district_data <- school_district_data |>
  mutate(
    flg_acfr = ifelse(is.na(flg_acfr), 1, flg_acfr),
  ) |>
  select(
    entity_id,
    entity_name,
    entity_type,
    year,
    state_name,
    state_abbr,
    total_assets,
    current_assets,
    total_liabilities,
    current_liabilities,
    total_revenues,
    total_expenses,
    net_position,
    pension_liability,
    non_net_pension_liability,
    opeb_liability,
    non_net_opeb_liability,
    bonds_outstanding,
    loans_outstanding,
    notes_outstanding,
    compensated_absences,
    bond_loans_notes,
    debt_ratio,
    free_cash_flow,
    current_ratio,
    non_current_liabilities,
    student_enrollment,
    population,
    latitude,
    longitude,
    document_url,
    flg_acfr
  )


# Write to json/js
school_district_json <- toJSON(school_district_data, pretty = TRUE)
school_district_json <- paste0("export default ", school_district_json)
write(school_district_json, "output/school_district_data.js")
# save RDS copy
saveRDS(school_district_data, "output/school_district_data.rds")

