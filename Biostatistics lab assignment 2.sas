data titanic;
    input group surv n class age sex;
    percent_survived = surv / n * 100; /* Calculate percent survived for plotting*/
    datalines;
1 20 23 0 0 1 
2 192 862 0 0 0 
3 1 1 1 1 1 
4 5 5 1 1 0 
5 140 144 1 0 1 
6 57 175 1 0 0 
7 13 13 2 1 1 
8 11 11 2 1 0 
9 80 93 2 0 1 
10 14 168 2 0 0 
11 14 31 3 1 1 
12 13 48 3 1 0 
13 76 165 3 0 1 
14 75 462 3 0 0
;
run;

data titanic;
    length c $10; /* Adjust the length of c to accommodate longer labels */
    set titanic;
    if sex = 1 then s = 'Female';
    else if sex = 0 then s = 'Male';
    if class = 0 then c = 'Crew';
    else if class = 1 then c = 'Class 1';
    else if class = 2 then c = 'Class 2';
    else if class = 3 then c = 'Class 3';
    if age = 0 then age_group = 'Adult';
    else if age = 1 then age_group = 'Child';
run;

/* Plot percent survived for different age groups, sex and class */
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=WORK.TITANIC;
	title height=14pt 
		"Titanic Survival Percentage for Different Age Groups, Sex and Class";
	footnote2 justify=left height=10pt "Figure 1: The scatter plot illustrates the survival percentage on the Titanic. Each marker represents a combination of sex, age group, and class, with different markers indicating sex (Male or Female) and different colours representing age groups (Adult or Child). The x-axis represents the class and the y-axis represents the percentage of individuals who survived.";
	scatter x=c y=percent_survived / group=age_group datalabel=s 
		markerattrs=(symbol=circle size=15) datalabelattrs=(size=13);
	xaxis grid label="Class" valuesrotate=diagonal;
	yaxis min=0 grid label="Percent Survived";
run;

ods graphics / reset;
title;
footnote2;

/* Prepare data for logistic regression */
data titanic_binary;
    set titanic;
    do i = 1 to n;
        if i <= surv then survived = 1;
        else survived = 0;
        output;
    end;
    drop i surv n;
run;

proc logistic data=titanic_binary;
    class sex (ref='0') age (ref='0') class / param=reference;
    model survived(event='1') = sex age class / scale=NONE aggregate = (age sex  class);
    title 'model 1';
run;

/* model that includes all the two factor interactions */
proc logistic data=titanic_binary;
    class sex (ref='0') age (ref='0') class / param=reference;
    model survived(event='1') = sex age class sex*age sex*class age*class / scale=NONE aggregate = (age sex  class);
    title 'model 2';
run;

/* sequentially remove terms starting with the highest p-value*/
proc logistic data=titanic_binary;
    class sex (ref='0') age (ref='0') class / param=reference;
    model survived(event='1') = sex age class sex*age sex*class / scale=NONE aggregate = (age sex  class);
    title 'model 2 w/o age*class';
run;

/* best model */
proc logistic data=titanic_binary;
    class sex (ref='0') age (ref='0') class / param=reference;
    model survived(event='1') = sex age class sex*class age*class / scale=NONE aggregate = (age sex  class);
    title 'model 2 w/o sex*age';
    ods output ParameterEstimates=ModelParameters; 
run;

proc logistic data=titanic_binary;
    class sex (ref='0') age (ref='0') class / param=reference;
    model survived(event='1') = sex age class sex*age age*class / scale=NONE aggregate = (age sex  class);
    title 'model 2 w/o sex*class';
run;

/* evaluate the effect of the single interaction that led to a significant increase in  the deviance when removed*/
proc logistic data=titanic_binary;
    class sex (ref='0') age (ref='0') class / param=reference;
    model survived(event='1') = sex age class sex*class / scale=NONE aggregate = (age sex  class);
    title 'model 3 only sex*class interaction';
run;

proc logistic data=titanic_binary;
    class sex (ref='0') age (ref='0') class / param=reference;
    model survived(event='1') = sex age class age*class / scale=NONE aggregate = (age sex  class);
    title 'model 3 only age*class interaction';
run;
