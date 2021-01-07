# calculate patient level reproduction numbers

source("generate fake data.R")
# 4. R_components
# 
# data frame with one row per infectious person and holding number of secdonary cases 
# 
# personID 
# person_type
# date_infected_or_admitted    - assumed date first infected or admitted to hospital if community acquired
# expected_secondary_cases   (=expected_secondary_patient_cases+expected_secondary_hcw_cases)
# expected_secondary_patient_cases
# expected_secondary_hcw_cases

#  to calculate for each individual in Infected_patients and Infected_staff
# get vector of potential infectors and another of relative infectiousness
# calc prob each caused the infection  and update expected_secondary_cases accordingly
# note that relative infectiousness might be different to staff and to patients


temp_IDs<-unique(Infectious_people$personID)
sel<-match(temp_IDs,Infectious_people$personID )
temp_types<-Infectious_people$person_type[sel]
date.first.infectious<-Infectious_people$date[sel]
R_components<-data.frame(personID=temp_IDs, person_type=temp_types,expected_secondary_cases=0, expected_secondary_patient_cases=0, expected_secondary_hcw_cases=0, date=date.first.infectious)

# define a matrix,whoinfectswhomprobs, to hold the probability that each assumed person infected in hospital was infected by each potential infector

num_new_infections<- length(Infected_patients$personID)  + length(Infected_staff$personID)
num_potential_infectors<-length(temp_IDs)

whoinfectswhomprobs<-matrix(data=0,nrow = num_potential_infectors, ncol=num_new_infections,dimnames = list(infectors=temp_IDs,infectees=c(Infected_patients$personID,Infected_staff$personID)))



#  First loop over hospital-acquired patient cases in Infected_patients
#  We assume patients can only be infected by other patients on the same ward

for(i in 1:length(Infected_patients$personID)){
  # then, for the day they became infected create three vectors of the same length
  # potential_infector_IDs  to hold person_IDs of patients and staff who were in the same ward and infectious on the day the patients were infected
  # potential_infector_Wards  to hold Ward_IDs of patients and staff who were in the same ward and infectious on the day the patients were infected
  # potential_infector_infectiousness to hold relative_infectiousness of patients and staff who were in the same ward and infectious on the day the patients were infected
  # make sure not to include the infectee as a potential infector (patients can't infect themselves!)
  infected_person_ID<-Infected_patients$personID[i]
  ward<-Infected_patients$Ward_ID[i]
  date.infected<-Infected_patients$Date_infection[i]
  potential_infector_IDs<- subset(Infectious_people,date==date.infected & Ward_ID==ward & Infectious_people$personID!=infected_person_ID,select=personID)
  potential_infector_Wards<- subset(Infectious_people,date==date.infected & Ward_ID==ward & Infectious_people$personID!=infected_person_ID,select=Ward_ID)
  potential_infector_infectiousness<- subset(Infectious_people,date==date.infected & Ward_ID==ward & Infectious_people$personID!=infected_person_ID,select=Relative_infectiousness)
  # next create a vector of probabilities that source of infection was each 
  if( dim(potential_infector_IDs)[1] >0 ){  # if at least one potential source of infection
       denom=sum(potential_infector_infectiousness)
       prob_infector<-t(potential_infector_infectiousness/denom)
       #update individual reproduction number components
       recordstoupdate<-match(t(potential_infector_IDs),R_components$personID)
       R_components$expected_secondary_cases[recordstoupdate]<-R_components$expected_secondary_cases[recordstoupdate]+prob_infector
       R_components$expected_secondary_patient_cases[recordstoupdate]<-R_components$expected_secondary_patient_cases[recordstoupdate]+prob_infector
       # update matrix whoinfectswhomprobs 
       col <- i # column to update
       ids.of.possible.infectors<- t(potential_infector_IDs)
       ids.of.all.infectious<- as.integer(dimnames(whoinfectswhomprobs)[[1]])
       rows<- match(ids.of.possible.infectors,ids.of.all.infectious )
       whoinfectswhomprobs[rows,col] <- prob_infector
    } else {
     # do nothing 
  }
 }  



for(i in 1:length(Infected_staff$personID)){
  # then, for the day they became infected create three vectors of the same length
  # potential_infector_IDs  to hold person_IDs of patients and staff who were in the same ward and infectious on the day the patients were infected
  # potential_infector_Wards  to hold Ward_IDs of patients and staff who were in the same ward and infectious on the day the patients were infected
  # potential_infector_infectiousness to hold relative_infectiousness of patients and staff who were in the same ward and infectious on the day the patients were infected
  # make sure not to include the infectee as a potential infector (patients can't infect themselves!)
  infected_person_ID<-Infected_staff$personID[i]
  ward<-Infected_staff$Ward_ID[i]
  date.infected<-Infected_staff$Date_infection[i]
  potential_infector_IDs<- subset(Infectious_people,date==date.infected & Ward_ID==ward & Infectious_people$personID!=infected_person_ID,select=personID)
  potential_infector_Wards<- subset(Infectious_people,date==date.infected & Ward_ID==ward & Infectious_people$personID!=infected_person_ID,select=Ward_ID)
  potential_infector_infectiousness<- subset(Infectious_people,date==date.infected & Ward_ID==ward & Infectious_people$personID!=infected_person_ID,select=Relative_infectiousness)
  # next create a vector of probabilities that source of infection was each 
  if( dim(potential_infector_IDs)[1] >0 ){  # if at least one potential source of infection
    denom=sum(potential_infector_infectiousness)
    prob_infector<-t(potential_infector_infectiousness/denom)
    #update individual reproduction number components
    recordstoupdate<-match(t(potential_infector_IDs),R_components$personID)
    R_components$expected_secondary_cases[recordstoupdate]<-R_components$expected_secondary_cases[recordstoupdate]+prob_infector
    R_components$expected_secondary_patient_cases[recordstoupdate]<-R_components$expected_secondary_patient_cases[recordstoupdate]+prob_infector
    # update matrix whoinfectswhomprobs 
    col <- i + length(Infected_patients$personID) # column to update
    ids.of.possible.infectors<- t(potential_infector_IDs)
    ids.of.all.infectious<- as.integer(dimnames(whoinfectswhomprobs)[[1]])
    rows<- match(ids.of.possible.infectors,ids.of.all.infectious )
    whoinfectswhomprobs[rows,col] <- prob_infector
  } else {
    # do nothing 
  }
}  

# now create summaries 


# Now plot time series plotting a) mean secondary cases per case [in staff and patients] for each 7 day interval
# b)  associated bootstrapped confidnce intervals

R_components$week<-1+ floor(R_components$date/7)
RbyWeek<-tapply(R_components$expected_secondary_cases,  R_components$week, mean)


# Next, assign sources of each acquired case probabilistically with a multinomial model - do this N times and store results in a matrix 

N<-100 # number of samples of who infects whome to perform
secondarycases.sample<-matrix(data = 0,nrow = dim(whoinfectswhomprobs)[1],ncol=N, dimnames = list(personID=unique(Infectious_people$personID), sample=1:N) )
# Then for each infected person choose a source from probs in whoinfectswhomprobs and assign number of infections in whoinfectswhom.sample
for(i in 1:N){
  for(j in 1: dim(whoinfectswhomprobs)[2]){
   if(sum(whoinfectswhomprobs[,j])>0){  
    chosen.infector<-rmultinom(1,1,whoinfectswhomprobs[,j])
    secondarycases.sample[,i]<- secondarycases.sample[,i] + chosen.infector
   }
  }
}


# now summarise by week....showing percentiles (e.g 10,50, and 90)
# R_components$week gives the week first infectoius 
# So  procdure is, for a each, calculate he mean number of secondary cases per person for that week for each iteration
# than calculate percentiles over the different iterations 

maxwk<-max(R_components$week)
Rquantiles<-data.frame(week=1:maxwk, q10=NA, q50=NA, q90=NA)
for(w in 1:maxwk){
  rows<-R_components$week == w
  meansecondarycases<-apply(secondarycases.sample[rows,],2,mean)  # mean secondary cases per case for each iteration
  Rquantiles[w,2:4]<- quantile(meansecondarycases,c(.10,.50,.90))
}

plot(Rquantiles$week,Rquantiles$q50,type='l',lty=1,ylim=c(0,2))
lines(Rquantiles$q10,lty=2)
lines(Rquantiles$q90,lty=2)




