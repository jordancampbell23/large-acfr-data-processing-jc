library(tidyverse)
library(jsonlite)

# read csv
state_data <- read_csv("input/all_states_2023.csv")
state_data <- state_data[, -1]

# filter for only 2023 data, standardize names
state_data <- state_data |>
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
    urban_population = urban_pop,
    pct_urban_population = pct_urban_pop
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
  )


state_data <- state_data |>
  select(
    entity_id,
    entity_name,
    entity_type,
    geo_id,
    year,
    state_name,
    state_abbr,
    total_assets,
    current_assets,
    total_liabilities,
    current_liabilities,
    pension_liability,
    non_net_pension_liability,
    opeb_liability,
    non_net_opeb_liability,
    bonds_outstanding,
    loans_outstanding,
    notes_outstanding,
    compensated_absences,
    bond_loans_notes,
    total_revenues,
    total_expenses,
    net_position,
    debt_ratio,
    current_ratio,
    free_cash_flow,
    non_current_liabilities,
    population,
    urban_population,
    pct_urban_population,
    document_url,
    flg_acfr
  )




# write to json
state_json <- toJSON(state_data, pretty = TRUE)
state_json <- paste0("export default ", state_json)
write(state_json, "output/state_data.js")
# also save as RDS for downstream R consumption
saveRDS(state_data, "output/state_data.rds")
