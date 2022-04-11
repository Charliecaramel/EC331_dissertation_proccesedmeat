
********************************************************************************
*DO file for Statistical Analysis used in the final project of EC331

*Student Number: u1910377
*Supervisor: Dr Thijs Van Rens

*University of Warwick
*Department of Economics
********************************************************************************

********************************************************************************
* Note: DO files used for data processing are avaliable on request. Alternatively,
*       they are avaliable on the GitHub repository lineked below.
*       https://github.com/Charliecaramel/EC331_dissertation_proccesedmeat

********************************************************************************
* Section A - Product Group Data
********************************************************************************
* 1. Loading  group data and setting seed for replicability
********************************************************************************
clear all 
set seed 89

* Loading Product Group Data 
use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\panelgroup_household_level_processed.dta"

********************************************************************************
* 2. Visual Inspection of average prices and consumption over time
********************************************************************************
xtset household_code monthly_date
foreach i in 1 3{
	by monthly_date, sort: egen ave_p`i' = mean(P`i') if monthly_date > tm(2003m12)
	twoway (tsline ave_p`i', lcolor(dkorange)), ytitle(Average Monthly Prices, size(medsmall)) xtitle(Time) title(Average Monthly Prices, size(medsmall)) name(ave_p`i',replace)
}

foreach i in 1 3{
	by monthly_date, sort: egen ave_q`i' = mean(Q`i') if monthly_date > tm(2003m12)
	twoway (tsline ave_q`i', lcolor(dkorange)), ytitle(Quantity Consumed for pc_`i', size(medsmall)) xtitle(Time) title(Average Quantity Consumed, size(medsmall)) name(ave_q`i',replace)
}

********************************************************************************
* 3. Data Generation for regression analysis
********************************************************************************
xtset household_code monthly_date
* Generating Drought and Herd Liquidation Dummies
gen drought2011 = 0 if monthly_date ~=.
replace drought2011 = 1 if monthly_date == tm(2011m6)|monthly_date == tm(2011m7)|monthly_date == tm(2011m8)|monthly_date == tm(2011m9)|monthly_date == tm(2011m10)|monthly_date == tm(2011m11)|monthly_date == tm(2011m12)|monthly_date == tm(2012m1)|monthly_date == tm(2012m2)


gen drought2012 = 0 if monthly_date ~=.
replace drought2012 = 1 if monthly_date == tm(2012m7)|monthly_date == tm(2012m8)|monthly_date == tm(2012m9)|monthly_date == tm(2012m10)|monthly_date == tm(2012m11)|monthly_date == tm(2012m12)|monthly_date == tm(2013m1)|monthly_date == tm(2013m2)|monthly_date == tm(2013m3)|monthly_date == tm(2013m4)|monthly_date == tm(2013m5)|monthly_date == tm(2013m6)|monthly_date == tm(2013m7)|monthly_date == tm(2013m8)|monthly_date == tm(2013m9)|monthly_date == tm(2013m10)

gen l_drought_2012 = 0 if monthly_date ~=.
replace l_drought_2012 = 1 if monthly_date == tm(2014m3)|monthly_date == tm(2014m4)|monthly_date == tm(2014m5)|monthly_date == tm(2014m6)|monthly_date == tm(2014m7)|monthly_date == tm(2014m8)|monthly_date == tm(2014m9)|monthly_date == tm(2014m10)|monthly_date == tm(2014m11)|monthly_date == tm(2014m12)

* Generating counties households frist lived in to accomodate stata's ivreg inability
* to accomodate nonest options
by household_code (fips_code), sort: gen byte moved = (fips_code[1] != fips_code[_N])
clonevar county = fips_code
by household_code(fips_code), sort: replace county= fips_code[1] if fips_code[1] != fips_code[_N]
by household_code (county), sort: gen byte moved2 = (county[1] != county[_N])
label values county fips_code

* Generating log prices and quantities
foreach i in 1 3{
    gen ln_q`i' = ln(Q`i')
    gen ln_p`i' = ln(P`i')
}

* Generating monthly dummies
gen dm = monthly_date
format dm %10.0g
gen date = dofm(dm)
format date %tm
gen m =month(date)
gen y = year(date)

* Generating selection variables
foreach i in  1 3{
	gen s_`i' = . 
	replace s_`i' = 1 if ln_q`i' != .
	replace s_`i' = 0 if ln_q`i' == .
	bysort household_code(monthly_date): gen last_period_`i' = s_`i'[_n-1]
}

* Income Category
proportion income_category 
gen low = 0 
replace low = 1 if income_category == 1
gen med = 0 
replace med = 1 if income_category == 2
gen high = 0 
replace high = 1 if income_category == 3

by monthly_date, sort: egen ave_low = mean(low)
by monthly_date, sort: egen ave_med = mean(med)
by monthly_date, sort: egen ave_high = mean(high)

by monthly_date, sort: egen lowave_q1 = mean(Q1) if low == 1
by monthly_date, sort: egen medave_q1 = mean(Q1) if med == 1
by monthly_date, sort: egen highave_q1 = mean(Q1) if high == 1

by monthly_date, sort: egen lowave_q3 = mean(Q3) if low == 1
by monthly_date, sort: egen medave_q3 = mean(Q3) if med == 1
by monthly_date, sort: egen highave_q3 = mean(Q3) if high == 1

* Generating time averages of household demographics in the selection equation
by household_code, sort: egen ave_age = mean(age)
by household_code, sort: egen ave_income = mean(income)
by household_code, sort: egen ave_size = mean(size)
by household_code, sort: egen ave_drought2011 = mean(drought2011)
by household_code, sort: egen ave_drought2012 = mean(drought2012)
by household_code, sort: egen ave_l_drought_2012 = mean(l_drought_2012)

foreach i in  1 3{
	by household_code,sort: egen ave_last_period_`i' = mean(last_period_`i')
}

drop if monthly_date < tm(2004m1)

********************************************************************************
* 4. Regression analysis on the entire sample
********************************************************************************

* Naive OLS
foreach i in 1 3{
	xtreg ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date ln_p`i' i.m income size age ,fe vce(cluster county)
	estimates store ols_`i'
}

* FE-2SLS
foreach i in 1 3{
	xtreg  ln_p`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age drought2011 drought2012  l_drought_2012 ,fe vce(cluster county)
	test drought2011 drought2012  l_drought_2012
	xtivreg ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age (ln_p`i' = drought2011 drought2012  l_drought_2012),fe vce(cluster county)
	estimates store fe_2sls_`i'
}

* Test for random selection using methods proposed by Semykina and Wooldridge(2010)
* step one: Estimate Selection Equation and obtain inverse mills ratio
foreach i in 1 3{
	probit s_`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age last_period_`i' drought2011 drought2012 l_drought_2012 ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012
	predict hats_`i', xb
	gen lambda_`i' = normalden(hats_`i')/normal(hats_`i')
}

* step two: Estimate FE-2SLS using inverse mills ratio, and the drought as IV
*    == Specification one: coeifficent on lambda is time invariant == 
foreach i in 1 3{
	xtivreg ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age lambda_`i' (ln_p`i' = drought2011 drought2012  l_drought_2012  lambda_`i'),fe vce(cluster county)
	test lambda_`i'
}

*    == Specification two: coeifficent on lambda is time variant == 
foreach i in 1 3{
	xtivreg ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age lambda_`i' c.lambda_`i'#i.dm (ln_p`i' = drought2011 drought2012  l_drought_2012  lambda_`i'),fe vce(cluster county)
	test lambda_`i'
	testparm c.lambda_`i'#i.dm
}

* Pooled 2SLS selection correction using methods proposed by Semykina and Wooldridge(2010)
foreach i in 1 3{
	ivregress 2sls ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age last_period_`i' ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012 lambda_`i' (ln_p`i' = drought2011 drought2012  l_drought_2012 ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012 lambda_`i'), vce(cluster county)
	estimates store p_2sls_`i'
}

* Estimating the correct standard erros via bootstraping panels
clonevar id = household_code
xtset id monthly_date
foreach i in 1 3{
	bootstrap, cluster(household_code) idcluster(id) seed(134) rep(200):ivregress 2sls ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age last_period_`i' ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012 lambda_`i' (ln_p`i' = drought2011 drought2012  l_drought_2012 ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012 lambda_`i'), vce(robust)
	estimates store bsp_2sls_`i'
}

esttab ols_3 fe_2sls_3 p_2sls_3 using regression1.tex, se ar2 varwidth(35) label mtitles("OLS" "FE 2SLS" "Pooled 2SLS") addnote("Regression results for processed red meat") compress


esttab ols_3 fe_2sls_3 p_2sls_3 using regression2.tex, se ar2 varwidth(35) label mtitles("OLS" "FE 2SLS" "Pooled 2SLS") addnote("Regression results for processed red meat") compress


********************************************************************************
* Section B - Product Modules Data
********************************************************************************
* 1. Loading  group data and setting seed for replicability
********************************************************************************
clear all 
set seed 243536

* Loading Product Group Data 
use  "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\panelmodule_household_level_processed.dta"

********************************************************************************
* 2. Visual Inspection of average prices and consumption over time
********************************************************************************
xtset household_code monthly_date
foreach i in 1 3 4 6{
	by monthly_date, sort: egen ave_p`i' = mean(P`i')  if monthly_date > tm(2003m12)
	twoway (tsline ave_p`i', lcolor(dkorange)), ytitle(Average Monthly Prices, size(medsmall)) xtitle(Time) title(Average Monthly Prices, size(medsmall)) name(ave_p`i',replace)
}

foreach i in 1 3 4 6{
	by monthly_date, sort: egen ave_q`i' = mean(Q`i')  if monthly_date > tm(2003m12)
	twoway (tsline ave_q`i', lcolor(dkorange)), ytitle(Quantity Consumed for pc_`i', size(medsmall)) xtitle(Time) title(Average Quantity Consumed, size(medsmall)) name(ave_q`i',replace)
}

********************************************************************************
* 3. Data Generation for regression analysis
********************************************************************************
xtset household_code monthly_date
* Generating Drought and Herd Liquidation Dummies
gen drought2011 = 0 if monthly_date ~=.
replace drought2011 = 1 if monthly_date == tm(2011m6)|monthly_date == tm(2011m7)|monthly_date == tm(2011m8)|monthly_date == tm(2011m9)|monthly_date == tm(2011m10)|monthly_date == tm(2011m11)|monthly_date == tm(2011m12)|monthly_date == tm(2012m1)|monthly_date == tm(2012m2)


gen drought2012 = 0 if monthly_date ~=.
replace drought2012 = 1 if monthly_date == tm(2012m7)|monthly_date == tm(2012m8)|monthly_date == tm(2012m9)|monthly_date == tm(2012m10)|monthly_date == tm(2012m11)|monthly_date == tm(2012m12)|monthly_date == tm(2013m1)|monthly_date == tm(2013m2)|monthly_date == tm(2013m3)|monthly_date == tm(2013m4)|monthly_date == tm(2013m5)|monthly_date == tm(2013m6)|monthly_date == tm(2013m7)|monthly_date == tm(2013m8)|monthly_date == tm(2013m9)|monthly_date == tm(2013m10)

gen l_drought_2012 = 0 if monthly_date ~=.
replace l_drought_2012 = 1 if monthly_date == tm(2014m3)|monthly_date == tm(2014m4)|monthly_date == tm(2014m5)|monthly_date == tm(2014m6)|monthly_date == tm(2014m7)|monthly_date == tm(2014m8)|monthly_date == tm(2014m9)|monthly_date == tm(2014m10)|monthly_date == tm(2014m11)|monthly_date == tm(2014m12)

* Generating counties households frist lived in to accomodate stata's ivreg inability
* to accomodate nonest options
by household_code (fips_code), sort: gen byte moved = (fips_code[1] != fips_code[_N])
clonevar county = fips_code
by household_code(fips_code), sort: replace county= fips_code[1] if fips_code[1] != fips_code[_N]
by household_code (county), sort: gen byte moved2 = (county[1] != county[_N])
label values county fips_code

* Generating log prices and quantities
foreach i in 1 3 4 6 7 9{
    gen ln_q`i' = ln(Q`i')
    gen ln_p`i' = ln(P`i')
}

* Generating monthly dummies
gen dm = monthly_date
format dm %10.0g
gen date = dofm(dm)
format date %tm
gen m =month(date)
gen y = year(date)

* Generating selection variables
foreach i in  1 3 4 6 7 9{
	gen s_`i' = . 
	replace s_`i' = 1 if ln_q`i' != .
	replace s_`i' = 0 if ln_q`i' == .
	bysort household_code(monthly_date): gen last_period_`i' = s_`i'[_n-1]
}

* Generating time averages of household demographics in the selection equation
by household_code, sort: egen ave_age = mean(age)
by household_code, sort: egen ave_income = mean(income)
by household_code, sort: egen ave_size = mean(size)
by household_code, sort: egen ave_drought2011 = mean(drought2011)
by household_code, sort: egen ave_drought2012 = mean(drought2012)
by household_code, sort: egen ave_l_drought_2012 = mean(l_drought_2012)

foreach i in  1 3 4 6 7{
	by household_code,sort: egen ave_last_period_`i' = mean(last_period_`i')
}

drop if monthly_date < tm(2004m1)

********************************************************************************
* 4. PM Level Regression analysis on the entire sample
********************************************************************************

* Naive OLS
foreach i in 1 3 4 6{
	xtreg ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date ln_p`i' i.m income size age if monthly_date > tm(2003m12) ,fe vce(cluster county)
	estimates store ols_`i'
}

* FE-2SLS
foreach i in 1 3{
	xtreg  ln_p`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age drought2011 drought2012 if monthly_date > tm(2003m12) ,fe vce(cluster county)
	test drought2011 drought2012
	xtivreg ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age (ln_p`i' = drought2011 drought2012) if monthly_date > tm(2003m12),fe vce(cluster county)
	estimates store fe_2sls_`i'
}

* FE-2SLS
foreach i in 7{
	xtreg  ln_p`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age drought2011 drought2012 if monthly_date > tm(2003m12) ,fe vce(cluster county)
	test drought2011 drought2012
	xtivreg ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age (ln_p`i' = drought2011 drought2012) if monthly_date > tm(2003m12),fe vce(cluster county)
	estimates store fe_2sls_`i'
}

foreach i in 4 6{
	xtreg  ln_p`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age drought2011 drought2012  l_drought_2012 if monthly_date > tm(2003m12) ,fe vce(cluster county)
	test drought2011 drought2012  l_drought_2012
	xtivreg ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age (ln_p`i' = drought2011 drought2012  l_drought_2012) if monthly_date > tm(2003m12),fe vce(cluster county)
	estimates store fe_2sls_`i'
}

* Test for random selection using methods proposed by Semykina and Wooldridge(2010)
* step one: Estimate Selection Equation and obtain inverse mills ratio
foreach i in 1 3 4 6 7{
	probit s_`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age last_period_`i' drought2011 drought2012 l_drought_2012 ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012
	predict hats_`i', xb
	gen lambda_`i' = normalden(hats_`i')/normal(hats_`i')
}

* step two: Estimate FE-2SLS using inverse mills ratio, and the drought as IV
*    == Specification one: coeifficent on lambda is time invariant == 
foreach i in 1 3 4 6 7{
	xtivreg ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age lambda_`i' (ln_p`i' = drought2011 drought2012  l_drought_2012  lambda_`i') if monthly_date > tm(2003m12),fe vce(cluster county)
	test lambda_`i'
}

*   == Specification two: coeifficent on lambda is time variant == 
foreach i in 1 3 4 6{
	xtivreg ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age lambda_`i' c.lambda_`i'#i.dm (ln_p`i' = drought2011 drought2012  l_drought_2012  lambda_`i') if monthly_date > tm(2003m12),fe vce(cluster county)
	test lambda_`i'
	testparm c.lambda_`i'#i.dm
}

* Pooled 2SLS selection correction using methods proposed by Semykina and Wooldridge(2010)
foreach i in 1 3{
	ivregress 2sls ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age last_period_`i' ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 lambda_`i' (ln_p`i' = drought2011 drought2012 ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 lambda_`i'), vce(cluster county)
	estimates store p_2sls_`i'
}

foreach i in 4 6{
	ivregress 2sls ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age last_period_`i' ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012 lambda_`i' (ln_p`i' = drought2011 drought2012  l_drought_2012 ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012 lambda_`i'), vce(cluster county)
	estimates store p_2sls_`i'
}

* Estimating the correct standard erros via bootstraping panels
clonevar id = household_code
xtset id monthly_date
foreach i in 1 3{
	bootstrap, cluster(household_code) idcluster(id) seed(134) rep(200):ivregress 2sls ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age last_period_`i' ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012 lambda_`i' (ln_p`i' = drought2011 drought2012  l_drought_2012 ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012 lambda_`i'), vce(cluster county)
	estimates store p_2sls_`i'
}

foreach i in 4 6{
	bootstrap, cluster(household_code) idcluster(id) seed(134) rep(200):ivregress 2sls ln_q`i' c.monthly_date c.monthly_date#c.monthly_date c.monthly_date#c.monthly_date#c.monthly_date i.m income size age last_period_`i' ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012 lambda_`i' (ln_p`i' = drought2011 drought2012  l_drought_2012 ave_income ave_size ave_age ave_last_period_`i' ave_drought2011 ave_drought2012 ave_l_drought_2012 lambda_`i'), vce(cluster county)
	estimates store p_2sls_`i'
}


esttab ols_1 fe_2sls_1 p_2sls_1 using regression3.tex, se ar2 varwidth(35) label mtitles("OLS" "FE 2SLS" "Pooled 2SLS") addnote("Regression results for unprocessed pork") compress
esttab ols_3 fe_2sls_3 p_2sls_3 using regression4.tex, se ar2 varwidth(35) label mtitles("OLS" "FE 2SLS" "Pooled 2SLS") addnote("Regression results for processed pork") compress

esttab ols_4 fe_2sls_4 p_2sls_4 using regression5.tex, se ar2 varwidth(35) label mtitles("OLS" "FE 2SLS" "Pooled 2SLS") addnote("Regression results for unprocessed beef") compress
esttab ols_6 fe_2sls_6 p_2sls_6 using regression6.tex, se ar2 varwidth(35) label mtitles("OLS" "FE 2SLS" "Pooled 2SLS") addnote("Regression results for processed beef") compress










