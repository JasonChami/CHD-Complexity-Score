library(tidyverse)

esc.complexity <- function(patient.diagnosis, complexity.reference) {
  
  patient.complexity <- left_join(patient.diagnosis, complexity.reference, by = 'EPCC_code') %>%
    #------------------CLEANING STEPS----------------------#
    # sort by Unique ID - ascending
    arrange(patient_id) %>%
    # Create new columns - Diagnosis level
    mutate(# complexity score for each dx                        
      diagnosiscomplexity = ( mild + ( 2 * moderate ) + ( 3 * severe ) ) / 
        ( mild + moderate + severe ),
      # flag for dx with multiple complexity options
      multiplecomplexity = if_else( (mild + moderate + severe == 1), 0, 1)
    ) %>%
    # Create person level dataset, nesting the diagnosis level variables
    nest(diagnosis = c(EPCC_code, EPCC_name, EPCC_category, 
                       mild, moderate, severe, 
                       diagnosiscomplexity, multiplecomplexity) ) %>%
    # Reevaluate the inconclusive diagnoses based on what other diagnoses a person has
    mutate(diagnosis = map(diagnosis, 
                           ~.x %>% mutate(diagnosiscomplexity2 = 
                                            if_else(multiplecomplexity == 1,
                                                    case_when(
                                                      # Atrial Septum Abnormality; Interatrial Communication
                                                      EPCC_code %in% c("05.03.00", "05.04.01")  ~ 
                                                        if (any(EPCC_code %in% "10.13.06")) {3} 
                                                      else if (any(EPCC_code %in% "06.06.01")) {2}
                                                      else if (any(EPCC_code %in% c("05.03.01", "05.04.03", "05.05.00"))) {1}
                                                      else {1.5},
                                                      # ASD in oval fossa
                                                      EPCC_code == "05.04.02" ~
                                                        if (any(EPCC_code %in% "10.13.06")) {3}
                                                      else {1.5},
                                                      # Mitral Stenosis
                                                      EPCC_code == "06.02.92" ~ 
                                                        if (any(EPCC_code %in% "06.02.56")) {2}
                                                      else {1},
                                                      # Mitral Valvar Abnormality
                                                      EPCC_code == "06.02.00" ~
                                                        if (any(EPCC_code %in% c("06.02.56", "06.02.36"))) {2}
                                                      else {1},
                                                      # VSD and varieties
                                                      EPCC_code %in% c("07.10.00", "07.10.01", "07.11.01", 
                                                                       "07.12.00", "07.12.01", "07.14.02") ~
                                                        if (any(EPCC_code %in% "10.13.06")) {3}
                                                      else if (length(unique(EPCC_code)) > 1) {2}
                                                      else {1},
                                                      # Pulmonary Stenosis
                                                      EPCC_code == "09.05.92" ~
                                                        if (any(EPCC_code %in% c("09.05.01", "09.05.04"))) {1}
                                                      else {1.5},
                                                      # Subpulmonary Stenosis
                                                      EPCC_code == "07.05.30" ~ 1.5,
                                                      # Aortic Stenosis
                                                      EPCC_code == "09.15.92" ~
                                                        if (length(unique(EPCC_code)) > 1) {2}
                                                      else {1},
                                                      # Patent Arterial Duct (PDA)
                                                      EPCC_code == "09.27.21" ~ 
                                                        if (any(EPCC_code %in% "10.13.06")) {3}
                                                      else if (length(unique(EPCC_code)) > 1) {2}
                                                      else {1},
                                                      # AVSD with ventricular imbalance 
                                                      EPCC_code == "06.07.26" ~
                                                        if (any(EPCC_code %in% c("10.13.06", "10.17.03", "10.17.12"))) {3}
                                                      else {2},
                                                      # Aortopulmonary Window
                                                      EPCC_code == "09.04.01" ~
                                                        if (any(EPCC_code %in% "10.13.06")) {3}
                                                      else if (length(unique(EPCC_code)) > 1) {2}
                                                      else {1},
                                                      # Aortic Abnormality 
                                                      EPCC_code == "07.09.31" ~
                                                        if (any(EPCC_code %in% "09.29.01")) {2}
                                                      else {1.5},
                                                      # Tricuspid Valvar Abnormality
                                                      EPCC_code == "06.01.00" ~
                                                        if (any(EPCC_code %in% "06.01.01")) {3}
                                                      else if (any(EPCC_code %in% "06.01.34")) {2}
                                                      else {1.5},
                                                      # Pulmonary Valvar Abnormality
                                                      EPCC_code == "09.05.00" ~
                                                        if (any(EPCC_code %in% "09.05.11")) {3}
                                                      else {1.5}
                                                    ),
                                                    diagnosiscomplexity)
                                                          )) # Closes Map
                ) %>% # Closes Mutate
    
    mutate(# Number of diagnoses per person
      no_dx = map_dbl(diagnosis, ~.x %>% pull(EPCC_code) %>% unique() %>% length()),
      # if all diagnosis complexity scores are missing, make it 1.5 for unknown
      diagnosis = map(diagnosis, 
                      ~.x %>% mutate(diagnosiscomplexity2 = if_else(is.na(.$diagnosiscomplexity2),
                                                                    0.5, diagnosiscomplexity2))),
      # Complexity score for each person based on maximum of diagnosis complexity
      
      patientcomplexity = map_dbl(diagnosis, ~ max(.$diagnosiscomplexity2, na.rm = TRUE)), # Closes map
      # Flag for patients who complexity is uncertain
      uncertaincomplexity = if_else(patientcomplexity %in% c(1,2,3), 0, 1),
      # Find the diagnosis that is determining the Complexity - code
      max_dx_code = map(diagnosis, 
                        ~ .$EPCC_code[.$diagnosiscomplexity2 == max(.$diagnosiscomplexity2, na.rm = TRUE)]),
      # Find the diagnosis that is determining the Complexity - name
      max_dx_name = map(diagnosis, 
                        ~ .$EPCC_name[.$diagnosiscomplexity2 == max(.$diagnosiscomplexity2, na.rm = TRUE)]),
      # Create the patient classification
      patientclassification = as_factor(case_when(
        patientcomplexity == 1 ~ "mild",
        patientcomplexity == 2 ~ "moderate",
        patientcomplexity == 3 ~ "severe",
        patientcomplexity == 1.5 ~ "unknown",
        patientcomplexity == 0.5 ~ "unknown")
      )
    )
  
  patient.complexity
}
