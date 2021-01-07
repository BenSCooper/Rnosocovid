# Rnosocovid
code related to quantifying reproduction numbers in hospital settings 
 R estimation 

## Overview and datastructures

Projects contains scripts to quantify components of reproduction number (i.e. secondary cases from HCW to HCW, HCW to Patient, Patient to Patient etc) under different assumptions in hospital setting.

Assumed data structures:

1. Infectious_people - dataframe where each row corresponds to one infectious person on one day:
fields:

personID  - unique id for person
person_type - eg. Community-acquired, Nosocomial, HCW

Date       - eg. integer for day of study
Relative_infectiousness - a number proportional to daily risk of transmission to a susceptible exposed to this person 
                          (e.g. based on viral shedding data or on ).
Ward_ID - what ward patient is on on a given day (assume at most one ward per day, so if more than one take ward where most time was spent)


2. Infected_patients - dataframe of patients  who became infected while in the hospital (according to assumed definition of nosocomial infections)

fields:

personID  - unique id for person
person_type - eg. Community-acquired, Nosocomial, HCW
Date_onset       - date of symptom onset (from data)
Date_infection       - date of first infection (imputed - will need to create multiple data frames with different dates )
Date_of_admission - date of first admission. 

3. Infected_staff - dataframe of HCWs  who became infected while in the hospital (according to assumed definition of nosocomial infections)

fields:

personID  - unique id for person
person_type - eg. Community-acquired, Nosocomial, HCW
Date_onset       - date of symptom onset (from data)
Date_infection       - date of first infection (imputed - will need to create multiple data frames with different dates )
Date_of_admission - date of first admission. 


4. R_components

data frame with one row per infectious person and holding number of secdonary cases 

personID 
person_type
date_infected_or_admitted    - assumed date first infected or admitted to hospital if community acquired
expected_secondary_cases   (=expected_secondary_patient_cases+expected_secondary_hcw_cases)
expected_secondary_patient_cases
expected_secondary_hcw_cases



### Estimation

Do two ways:

i) calculating expected number of secondary cases per case
ii) calculating variation in this - i.e. sampling 

For approach i)

For each infected patient, for the date of infection, look up all infectious people on that day and use relative hazards
formula to calc probl that each potential infector caused the infection. Then update R_components.

Approach ii) is the same except instead of looking at expected secondary cases, we sample a potential infector of each patient 


