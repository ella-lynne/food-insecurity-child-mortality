* Final Project;
* Ella Tamayo | Linear Models | Spring 2024 | Dr. Yu ; 

*library;
libname final '/home/u63679507/sasuser.v94/Linear Models/Final/Data';

*read in data;
FILENAME one '/home/u63679507/sasuser.v94/Linear Models/Final/Data/2023 County Health Rankings Data - v2 copy.xlsx';
PROC IMPORT DATAFILE=one
	DBMS=XLSX replace
	OUT=final.county;
	sheet="Additional Measure Data (3)";
	GETNAMES=YES;
RUN;

*check out data;
proc print data=final.county(obs=50); run;

*isolate variables I want to look at, keeping variables I want to analyze;
data newproj; set final.county;
keep Child_Mort_Rate County
Perc_Food_Insecure perc_Lim_Access_Healthy_Food
perc_Uninsured_Children
Median_Household_Income 
HIV_Prev_Rate
perc_Black perc_Asian perc_Hispanic perc_NonHispanic_White perc_native_am perc_Native_Hawaiian perc_rural State;
run;


proc univariate data=newproj;
var Child_Mort_Rate
Perc_Food_Insecure perc_Lim_Access_Healthy_Food
perc_Uninsured_Children
Median_Household_Income 
HIV_Prev_Rate;run;
*1258 counties are missing data on child mortality rate;
*data on HIV is missing in 458 counties;

*Creating new categorical variables Race and Region;
		*Quick way;
data newproj; set newproj;
Minority=(perc_Black>=50 or perc_Asian>=50 or perc_Hispanic>=50 or perc_native_am=>50 or perc_Native_Hawaiian=>50);
if State in ('Washington', 'California', 'Oregon', 'Nevada', 'Idaho', 'Montana', 'Wyoming', 'Colorado', 'Arizona', 'Utah', 'Arkansas', 'Hawaii', 'Alaska', 'New Mexico') then region=1;
if State in ('North Dakota', 'South Dakota', 'Nebraska', 'Kansas', 'Missouri', 'Iowa', 'Minnnesota', 'Wisconsin', 'Michigan', 'Illinois', 'Indiana', 'Ohio') then region=2;
if State in ('Maryland', 'Delaware', 'Viginia', 'West Virginia', 'Kentucky', 'Tennessee', 'North Carolina', 'South Carolina', 'Florida', 'Georgia', 'Alabama', 'Mississippi', 'Louisiana', 'Arkansas', 'Texas', 'Oklahoma', 'Arkansas', 'District of Columbia') then region=3;
if State in ('Maine', 'Massachussetts', 'New Hampshire', 'New Jersey', 'New York', 'Pennsylvania', 'Rhode Island', 'Vermont', 'Delaware', 'Connecticut') then region=4;run;
*Region 1 is west, 2 is Midwest, 3 is South, 4 is East. ;

*Creating formats;
PROC FORMAT;
	VALUE Race		0 = 'Majority White'
					1 = "Majority Non-White";
	VALUE Region	1='West'
				    2='Midwest'
				    3='South'
				    4='East';
RUN;

PROC PRINT DATA=newproj; 
VAR county Minority Region;
FORMAT Minority Race. Region Region.;
RUN;


*Dummy variables for Region;
*Region 1 is reference;
data newproj; set newproj;
if region=1 then do; region_2=0; region_3=0; region_4=0; end;
if region=2 then do; region_2=1; region_3=0; region_4=0; end;
if region=3 then do; region_2=0; region_3=1; region_4=0; end;
if region=4 then do; region_2=0; region_3=0; region_4=1; end;

*labeling data;
data newproj;
set newproj;
label Child_Mort_Rate="Child Mortality Rate"
Perc_Food_Insecure="Percent Food Insecurity"
perc_Lim_Access_Healthy_Food="Percent with Limited Access to Healthy Food"
perc_Uninsured_Children="Percent of Uninsured Children"
Median_Household_Income="Median Household Income"
HIV_Prev_Rate="HIV Prevalence Rate"
perc_rural="Percent Rural"
minority="Minority"
region="Region"
region_2="Midwest"
region_3="South"
region_4="East";
run;

*selecting data again based on the dummy variables we made;
data newproj; set newproj;
keep Child_Mort_Rate County
Perc_Food_Insecure perc_Lim_Access_Healthy_Food
perc_Uninsured_Children
Median_Household_Income 
HIV_Prev_Rate perc_rural 
minority region region_2 region_3 region_4;
run;

*Full dataset (for later purposes - see line 479);
data full;
set newproj;
run;

*taking out missing data;
*Child_Mort_Rate, perc_Lim_Access_Healthy_Food, perc_Uninsured_Children(has 1 missing),
Spending_per_Pupil, School_Funding_Adequacy, perc_freered_lunch(missing 577 - maybe just don't include it),
perc_Income_ChildCare(missing 2), Median_Household_Income(missing 2), perc_Houses_sev_Cost_Burden(missing 5),
HIV_Prev_Rate (missing ~500), perc_rural (missing 7);

data newproj;
set newproj;
if Child_Mort_Rate=. then delete; 
*start with 3143, now has 1885;
if perc_lim_access_healthy_food=. then delete;
if perc_Uninsured_Children=. then delete;
*1873;
if Median_Household_Income=. then delete;
if HIV_Prev_Rate=. then delete;
if region=. then delete;
run;
*left with 1693 observations;

*assessing outliers;

proc univariate data=newproj;run;

*Using general full, untransformed model to look at cook's d and leverage;
proc reg data=newproj  plots=(DFFITS(label) DFBETAS(label));
model child_mort_rate=Perc_Food_Insecure perc_Lim_Access_Healthy_Food
perc_Uninsured_Children
Median_Household_Income 
HIV_Prev_Rate perc_rural minority {region_2 region_3 region_4}/ r influence;
output out=residuals p=predicted residual=raw_residual student=studentized rstudent=jackknife h=leverage cookd=cook dffits=dffit;
run;

** check out outliers;
data residuals; set residuals;
 if cook>(4/1693) or leverage > (2*(9+1)/1693) or abs(jackknife) > tinv(0.95,1682);
 run;

*k=9 (9 variables in dataset);
*n=1693;

*These values seem extreme (especially Bronx county), but they make sense and are not unrealistic. ;
*I'm going to leave these values for now since they're plausible, but take them out later to see if it makes a big difference in model ;
*But this is how I would remove them: ;
/*data residuals; set residuals;
 if cook>.05 or leverage>.7 or abs(jackknife)>5; run;
data newproj; set newproj;
 if county=("Bronx") then delete; run;*/

*Descriptive Statistics;

proc means data=newproj;
var Child_Mort_Rate
Perc_Food_Insecure perc_Lim_Access_Healthy_Food
perc_Uninsured_Children
Median_Household_Income 
HIV_Prev_Rate perc_rural;
run;

proc freq data=newproj;
tables minority region;
run;


*plots for numerical;
proc univariate plots data=newproj;
var Child_Mort_Rate
Perc_Food_Insecure perc_Lim_Access_Healthy_Food
perc_Uninsured_Children
Median_Household_Income 
HIV_Prev_Rate perc_rural;
run;


*Plot matrix for relationships with multiple variables;
proc sgscatter data=newproj;
  title "Relationships with Child Mortality";
  plot (child_mort_rate)*(Perc_Food_Insecure perc_Lim_Access_Healthy_Food
perc_Uninsured_Children
Median_Household_Income 
HIV_Prev_Rate perc_rural);
run;
title;


*Simple regression - untransformed;
proc reg simple data=newproj plots;
model_1:model child_mort_rate=Perc_Food_Insecure;
model_2:model child_mort_rate=perc_Lim_Access_Healthy_Food;
model_3: model child_mort_rate=perc_Uninsured_Children;
model_4: model child_mort_rate=Median_Household_Income; 
model_5: model child_mort_rate=HIV_Prev_Rate;
model_6: model child_mort_rate=perc_rural; 
model_7: model child_mort_rate=minority;
model_8: model child_mort_rate={region_2 region_3 region_4};
run;

*bivariate analyses - correlation matrix;
proc corr nosimple data=newproj plots=matrix(histogram);
var child_mort_rate Perc_Food_Insecure perc_Lim_Access_Healthy_Food
perc_Uninsured_Children
Median_Household_Income 
HIV_Prev_Rate perc_rural 
minority
region_2 region_3 region_4;
run;

*Full model regression with partial plots - untransformed;
proc reg data=newproj;
model child_mort_rate=Perc_Food_Insecure perc_Lim_Access_Healthy_Food
perc_Uninsured_Children
Median_Household_Income 
HIV_Prev_Rate perc_rural minority region_2 region_3 region_4/partial;
run;


*********Transform data and add interaction variables (assessed later and added here);**********;
data transformed; set newproj;
Child_Mort_Rate=log(Child_Mort_Rate);
food_insurance=perc_food_insecure*perc_uninsured_children;
food_rural=perc_food_insecure*perc_rural;

*Check out data - transformed;

proc sgscatter data=transformed;
  title "Relationships with Child Mortality";
  plot (child_mort_rate)*(Perc_Food_Insecure perc_Lim_Access_Healthy_Food
perc_Uninsured_Children
Median_Household_Income 
HIV_Prev_Rate perc_rural
minority region food_insurance food_rural);
run;
title;

proc sgplot data=transformed;
loess x=median_household_income y= child_mort_rate /smooth=1;run;


proc univariate plots data=transformed;
var child_mort_rate perc_food_insecure 
perc_Lim_Access_Healthy_Food perc_uninsured_children hiv_prev_rate   
Median_Household_Income perc_rural 
minority
region;
run;


*Simple regression - transformed;
proc reg simple data=transformed plots;
model_1:model child_mort_rate=Perc_Food_Insecure;
model_2:model child_mort_rate=perc_Lim_Access_Healthy_Food;
model_3: model child_mort_rate=perc_Uninsured_Children;
model_4: model child_mort_rate=Median_Household_Income; 
model_5: model child_mort_rate=HIV_Prev_Rate;
model_6: model child_mort_rate=perc_rural; 
model_7: model child_mort_rate=minority;
model_8: model child_mort_rate=region_2 region_3 region_4;
model_9: model child_mort_rate=food_rural;
model_10: model child_mort_rate=food_insurance;
run;

*Full model regression with partial plots - transformed, with significant interactions;
proc reg data=transformed plots;
model child_mort_rate=Perc_Food_Insecure perc_Lim_Access_Healthy_Food perc_uninsured_children
hiv_prev_rate 
Median_Household_Income
perc_rural_ctr 
minority region_2 region_3 region_4 food_rural_ctr food_insurance_ctr /partial;
run;

*Look at interactions with food insecurity;

proc glm data=transformed plots=all;
model child_mort_rate=Perc_Food_Insecure perc_Lim_Access_Healthy_Food perc_uninsured_children
hiv_prev_rate 
Median_Household_Income
perc_rural 
minority region_2 region_3 region_4
Perc_Food_Insecure*perc_Lim_Access_Healthy_Food
Perc_Food_Insecure*perc_uninsured_children
Perc_Food_Insecure*hiv_prev_rate
Perc_Food_Insecure*Median_Household_Income
Perc_Food_Insecure*perc_rural
Perc_Food_Insecure*minority
Perc_Food_Insecure*region_2 
Perc_Food_Insecure*region_3 
Perc_Food_Insecure*region_4
; 
run;

data transformed;
set transformed;
food_access=Perc_Food_Insecure*perc_Lim_Access_Healthy_Food;
food_insurance=Perc_Food_Insecure*perc_uninsured_children;
food_hiv=Perc_Food_Insecure*hiv_prev_rate;
food_income=Perc_Food_Insecure*Median_Household_Income;
food_rural=Perc_Food_Insecure*perc_rural;
food_minority=Perc_Food_Insecure*minority;
food_reg2=Perc_Food_Insecure*region_2;
food_reg3=Perc_Food_Insecure*region_3;
food_reg4=Perc_Food_Insecure*region_4;
run;

proc reg data=transformed plots=all;
model child_mort_rate=food_access food_insurance food_hiv food_income food_rural food_minority food_reg2 food_reg3 food_reg4/vif;
test food_access, food_insurance, food_hiv, food_income, food_rural, food_minority, food_reg2, food_reg3, food_reg4; *p=0.3465 for any two-way interactions;
run; 

** standardize the variables;
proc standard data=transformed out=transformed_ctr mean=0;
var Perc_Food_Insecure perc_Lim_Access_Healthy_Food perc_uninsured_children
hiv_prev_rate 
Median_Household_Income
perc_rural;
run;
proc print data=transformed_ctr (obs=5); run;
data transformed_ctr2;
set transformed_ctr;
food_access=Perc_Food_Insecure*perc_Lim_Access_Healthy_Food;
food_insurance=Perc_Food_Insecure*perc_uninsured_children;
food_hiv=Perc_Food_Insecure*hiv_prev_rate;
food_income=Perc_Food_Insecure*Median_Household_Income;
food_rural=Perc_Food_Insecure*perc_rural;
food_minority=Perc_Food_Insecure*minority;
food_reg2=Perc_Food_Insecure*region_2;
food_reg3=Perc_Food_Insecure*region_3;
food_reg4=Perc_Food_Insecure*region_4;
run;
proc reg data=transformed_ctr2 plots=all;
model child_mort_Rate=Perc_Food_Insecure perc_Lim_Access_Healthy_Food perc_uninsured_children
hiv_prev_rate 
Median_Household_Income
perc_rural food_access food_insurance food_hiv food_income food_rural food_minority food_reg2 food_reg3 food_reg4/vif;
test food_access, food_insurance, food_hiv, food_income, food_rural, food_minority, food_reg2, food_reg3, food_reg4; *p=0.3465 for any two-way interactions;
run; 

*Assess for confounders;
*** adjusted estimates;
proc reg data = transformed;
model_2:model child_mort_rate=perc_food_insecure perc_Lim_Access_Healthy_Food;
model_3: model child_mort_rate=perc_food_insecure perc_Uninsured_Children;
model_4: model child_mort_rate=perc_food_insecure Median_Household_Income; 
model_5: model child_mort_rate=perc_food_insecure HIV_Prev_Rate;
model_6: model child_mort_rate=perc_food_insecure perc_rural; 
model_7: model child_mort_rate=perc_food_insecure minority;
model_8: model child_mort_rate=perc_food_insecure region_2 region_3 region_4;;
run;
*** crude estimate;
proc reg data = transformed;
    model child_mort_rate=perc_food_insecure;
run;

*Median Household income and Region are confounding variables;

*Model selection;

proc reg data=transformed plots=all;
model child_mort_rate=Perc_Food_Insecure food_insurance perc_rural food_rural Median_Household_Income 
{region_2 region_3 region_4}
perc_Lim_Access_Healthy_Food perc_uninsured_children
hiv_prev_rate 
minority /selection=stepwise include=1 include=2 include=3 include=4 include=5 include=6;
run;

*Check out new model;
proc reg data=transformed;
model child_mort_rate=Perc_Food_Insecure food_insurance perc_rural food_rural Median_Household_Income 
{region_2 region_3 region_4} perc_lim_access_healthy_food perc_uninsured_children
hiv_prev_rate /partial;
run;


*** collinearity index: VIF and tolerance;
proc reg data=transformed; 
model child_mort_rate=Perc_Food_Insecure food_insurance perc_rural food_rural Median_Household_Income 
{region_2 region_3 region_4} perc_lim_access_healthy_food perc_uninsured_children
hiv_prev_rate/tol vif; 
run;
*some significant collinearity detected;

*Testing collinearity of centered model;

*Centering variables due to collinearity (assessed later);
proc means data = transformed mean;
var perc_food_insecure perc_uninsured_children perc_rural;
run;


data transformed_ctr4;
set transformed;
perc_food_insecure_ctr=perc_food_insecure-12.8659776;
perc_uninsured_ctr = perc_uninsured_children - 6.1143735;
perc_rural_ctr = perc_rural - 44.3203261;
food_insurance_ctr = perc_food_insecure_ctr*perc_uninsured_ctr;
food_rural_ctr = perc_food_insecure_ctr*perc_rural_ctr;
run;

proc reg data=transformed_ctr4; 
model child_mort_rate=perc_food_insecure_ctr food_insurance_ctr perc_rural_ctr food_rural_ctr Median_Household_Income 
region_2 region_3 region_4 perc_lim_access_healthy_food perc_uninsured_children
hiv_prev_rate/partial; 
run;

*Sensitivity analysis of selected model;

proc reg data=transformed  plots=(DFFITS(label) DFBETAS(label));
model child_mort_rate=perc_food_insecure food_insurance perc_rural food_rural Median_Household_Income 
region_2 region_3 region_4 perc_lim_access_healthy_food perc_uninsured_children
hiv_prev_rate/ r influence;
output out=residuals p=predicted residual=raw_residual student=studentized rstudent=jackknife h=leverage cookd=cook dffits=dffit;
run;

data residuals; set residuals;
 if cook>(4/1693) or leverage > (2*(9+1)/1693) or abs(jackknife) > tinv(0.95,1682);
 run;
 
 *Did not remove any other outliers (other than Bronx, removed earlier);

*Looking at sensitivity analysis again;
proc reg data=transformed  plots=(DFFITS(label) DFBETAS(label));
model child_mort_rate=Perc_Food_Insecure food_insurance food_rural Median_Household_Income 
{region_2 region_3 region_4} perc_lim_access_healthy_food perc_uninsured_children
hiv_prev_rate/ r influence;
output out=residuals p=predicted residual=raw_residual student=studentized rstudent=jackknife h=leverage cookd=cook dffits=dffit;
run;

*k=9 (9 variables in dataset);

*These values seem extreme, but they make sense and are not unrealistic. ;
*I'm going to keep them in the model, then take them out later to see if they matter;

*I'm going remove outliers now;

data residuals; set residuals;
 if cook>.01 or leverage>.04 or abs(jackknife)>4; run;
data transformed; set transformed;
 if county in ('Apache', 'San Francisco', 'District of Columbia', 'Union', 'LaGrange', 'Switzerland', 'Baltimore City', 'Big Horn', 'Dallas', 'Bronx', 'New York', 'McKenzie', 'Dallam', 'Moore', 'Starr','Winkler') then delete; run;

*n=1664 now;
proc reg data=transformed;
model child_mort_rate=Perc_Food_Insecure food_insurance food_rural Median_Household_Income 
{region_2 region_3 region_4} perc_lim_access_healthy_food perc_uninsured_children
hiv_prev_rate ;
run;

*Regression estimates don't change drastically - the outliers don't matter whether they stay or go;


*Attempting to do interaction plots to look at relationships;

*Food insecurity and rural;
proc glm data=transformed;
   model child_mort_rate = perc_food_insecure | perc_rural / solution;
   ods select ParameterEstimates ContourFit;
   store GLMModel;
run;

proc plm restore=GLMModel noinfo;
   effectplot slicefit(x=perc_food_insecure sliceby=perc_rural) / clm;
   title "Interaction plot between % Food Insecurity and % Rural";
run;

*Food insecurity and percent uninsured;
proc glm data=transformed;
   model child_mort_rate = perc_food_insecure | perc_uninsured_children / solution;
   ods select ParameterEstimates ContourFit;
   store GLMModel2;
run;

proc plm restore=GLMModel2 noinfo;
   effectplot slicefit(x=perc_food_insecure sliceby=perc_uninsured_children) / clm;
   title "Interaction plot between % Food Insecurity and % Uninsured Children";
run;


*Apply model to full dataset and restricted dataset, see if it's still a good model;

*Full dataset=full;
*Restricted dataset=Transformed;

*Transform full data and add interaction variables;
data full; set full;
Child_Mort_Rate=log(Child_Mort_Rate);
food_insurance=perc_food_insecure*perc_uninsured_children;
food_rural=perc_food_insecure*perc_rural;
*** apply model to full dataset for report after validation ***;

*Center data;
proc means data = full mean;
var perc_food_insecure perc_uninsured_children perc_rural;
run;


data full_ctr;
set full;
perc_food_insecure_ctr=perc_food_insecure-12.4353166;
perc_uninsured_ctr = perc_uninsured_children - 6.7931876;
perc_rural_ctr = perc_rural - 58.5796666;
food_insurance_ctr = perc_food_insecure_ctr*perc_uninsured_ctr;
food_rural_ctr = perc_food_insecure_ctr*perc_rural_ctr;
run;

proc reg data=full_ctr plots=all;
model child_mort_rate=Perc_Food_Insecure_ctr food_insurance_ctr food_rural_ctr Median_Household_Income 
{region_2 region_3 region_4} perc_lim_access_healthy_food perc_uninsured_ctr
hiv_prev_rate;
run;


