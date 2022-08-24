# CHD Complexity Score

An algorithm for scoring the complexity of a congenital heart disease patient's diagnosis based on the ESC 2020 guidelines (<https://doi.org/10.1093/eurheartj/ehaa554>)

## Contents

-   **Diagnosis_Complexity_Reference_Table_20210723.csv** - contained the expert provided complexity score for each EPCC diagnosis code used in the CHAANZ CHD Registry. Complexity scores were assigned by CHD clinicians based on ESC guidelines or expert knowledge where necessary.

-   **patient_diagnosis_example.csv** - an example of the input patient data

-   **esc_complexity.R -** Contains the function that will calculate patient complexity

-   **Run_Complexity.Rmd** - An example of the function in use.

## Using the `esc.complexity` function

### Inputs

**`patient.diagnosis`** - a diagnosis-level data frame with two variables:

-   `patient_id` - Unique patient identifier that can be used to group EPCC_codes by patients

-   `EPCC_code` - Character, EPCC Code denoting the patient's diagnoses

**`complexity.reference`** - List of EPCC diagnosis codes with complexity score

-   This is provided as "Diagnosis_Complexity_Reference_Table_20210723.csv"

### Output

**`patient.complexity`** - a patient-level data frame with 8 variables:

-   `patient_id` - Unique patient identifier that can be used to group EPCC_codes by patients

-   `diagnosis` - Nested dataframe with diagnosis level information for each patient

-   `no_dx` - Number of diagnoses

-   `patientcomplexity` - The numeric complexity score for a patient, 0.5 - missing, 1 - mild, 1.5 unknown, 2 - moderate, 3 - severe

-   `uncertaincomplexity` - Flag for patients whose complexity is determined by an uncertain diagnosis (i.e. score of 0.5 or 1.5)

-   `max_dx_code` - The code(s) that determined the patient complexity score

-   `max_dx_name` - The diagnosis name(s) that determined the patient complexity score

-   `patientclassification` - The final classification score
