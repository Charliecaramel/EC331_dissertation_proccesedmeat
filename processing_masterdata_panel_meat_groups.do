*Data Cleaning  - From master data to yearly panels organised by aggreagted PG

clear all
********************************************************************************
* Merging UPC data with master data, and dropping irrelavet upc codes
********************************************************************************

foreach i in 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014{
	use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\masterdata_`i'.dta"
	merge m:1 upc upc_ver_uc using "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\upc_codes_merge.dta"
	drop if _merge ==2
	keep if group != 7
	save "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel `i'.dta",replace
}

********************************************************************************
* Combing datasets in accordance to yearly pannels
********************************************************************************

forvalues i = 2004/2014{
	scalar define x_`i' = `i'
}

foreach i in 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014{
		use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel `i'.dta"
		tab purchase_year
		keep if purchase_year != x_`i'
		tab purchase_year
		save "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\append_`i'.dta",replace
}

forvalues j = 2003/2013{
	foreach i in 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014{
		if `i' == `j' + 1{
			use"C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\append_`i'.dta"
			tab purchase_year
			save "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\append_`j'.dta",replace
		}	
	}
}

foreach i in 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014{
		use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel `i'.dta"
		tab purchase_year
		keep if purchase_year == x_`i'
		tab purchase_year
		save "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel `i'.dta", replace
}

foreach i in 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013{
		use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel `i'.dta"
		append using "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\append_`i'.dta"
		save "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel `i'.dta", replace
}

foreach i in 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014{
		use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel `i'.dta"
		tab purchase_year
}

use"C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\append_2003.dta"
tab purchase_year
save"C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel 2003.dta",replace

foreach i in 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014{
		use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel `i'.dta"
		tab purchase_year
}

********************************************************************************
* Data aggreagtion, constructing panel data based on household codes
********************************************************************************

foreach i in 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014{
	use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel `i'.dta"
	*Panel Data Processing - Dealing with state codes befroe aggregation
	tostring fips_state_code, gen (fips_state_code_1)
	tostring fips_county_code, gen(fips_county_code_1)
	gen num = strlen(fips_state_code_1)
	gen num2 = strlen(fips_county_code_1)

	replace fips_county_code_1 = "0" + fips_county_code_1 if num2 == 2
	replace fips_county_code_1 = "00" + fips_county_code_1 if num2 == 1
	replace fips_state_code_1 = "0" + fips_state_code_1 if num == 1

	gen fips_code = fips_state_code_1+ fips_county_code_1
	destring fips_code, replace
	drop _merge num num2

	merge m:1 fips_code using "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\fips_county_data\fips_county_data.dta"
	drop if _merge == 2
	drop _merge fips_county_name fips_state_name
	**********************************************************************
	* Run the following for housheolds facing county level prices*
	***********************************************************************
	* Generating County level prices to be quantity adjusted 
	by fips_code purchase_month upc, sort: egen qc = total(quantity)
	by fips_code purchase_month upc, sort: gen wqc = w * qc
	by fips_code purchase_month upc, sort: gen dup = cond(_N == 1, 0,_n)
	replace wqc = . if dup > 1
	drop dup
	by fips_code purchase_month group, sort: egen EXP = total(total_price_paid)
	by fips_code purchase_month group, sort: egen Qc = total(wqc)
	by fips_code purchase_month group, sort: gen P = EXP/Qc

	* Generating household level price adjusted quantities
	by household_code purchase_month upc, sort: egen q = total(quantity)
	by household_code purchase_month upc, sort: gen wq = w * q
	by household_code purchase_month upc, sort: gen dup = cond(_N == 1, 0,_n)
	replace wq = . if dup > 1
	by household_code purchase_month group, sort: egen Q = total(wq)
	drop dup

	* Generating expenditures for each households (Expenditure in group and total expenditure over all groups)
	* Subscrpit i denotes product groups, h denotes for each household
	by household_code purchase_month group, sort: egen expenditure_h_i = total(total_price_paid)
	by household_code purchase_month, sort: egen total_expenditure = total(total_price_paid)

	* Generating budget shares for each product group purchased by households in a month
	by household_code purchase_month group, sort: gen bs = expenditure_h_i/total_expenditure
	
	* Generating Stone's Price index for LAIDS
	gen ln_p = ln(P)
	by household_code purchase_month group, sort: gen bslnp = bs*ln_p
	by household_code purchase_month group, sort: gen dup = cond(_N == 1, 0,_n)
	replace bslnp = . if dup > 1
	by household_code purchase_month, sort:egen price_index = total(bslnp)
	drop dup qc wqc exp EXP Qc q wq expenditure_h_i bslnp ln_p w
	************************************************************************
	* Run the following for household facing household specific prices
	************************************************************************
	*by household_code purchase_month upc, sort: egen exp_h = total(total_price_paid)
	*by household_code purchase_month group, sort: egen EXP_h = total(exp_h)
	*by fips_code purchase_month group, sort: gen P = EXP_h/Q

	*Generating date and time variables
	gen date = mdy(purchase_month, purchase_day, purchase_year)
	gen monthly_date = mofd(date)
	format monthly_date %tm
	format date %td
	save  "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\panel_household_`i'.dta",replace

	* Generating sub-dataset with variable varying to household and months 
	keep price_index total_expenditure household_code household_income household_size race hispanic_origin gender age edu empstat monthly_date fips_code
	collapse(first) price_index total_expenditure household_income household_size race hispanic_origin gender age edu empstat fips_code, by( household_code monthly_date)
	save "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\demographics_`i'.dta", replace
	
	* Reshaping variables that vary over time, product types, and household into panel forms
	use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\panel_household_`i'.dta"
	keep household_code monthly_date P Q group bs
	collapse(first) P Q bs, by(household_code monthly_date group)
	reshape wide P Q bs, i(household_code monthly_date) j(group)
	merge m:1 household_code monthly_date using  "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\demographics_`i'.dta"
	tab _merge
	drop _merge
	save  "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\panelgroup_household_`i'.dta",replace	
}

********************************************************************************
* Appending yearly panels into panel data set for analysis
********************************************************************************
use  "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\panelgroup_household_2004.dta"
foreach i in 2003 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014{
	tab monthly_date
	append using  "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\panelgroup_household_`i'.dta"
	tab monthly_date
	save  "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\panelgroup_household_level_processed.dta", replace
}

foreach i in household_income household_size race hispanic_origin gender age edu empstat{
	tab `i'
}

label define household_size 1 "Single Member" 2"Two Member" 3"Three Member" 4"Four Member" 5"Five Member" 6"Six Member" 7"Seven Member" 8 "Eight Member" 9 "Nine+ Member"
label values household_size household_size

gen size = household_size

label define household_income 3 "under $5000 pa" 4"$5000-$7999" 6"$8000-$9999" 8"$10,0000-$11,999" 10"$12,000-$14,999" 11"$15,000-$19,999" 13"$20,000-$24,999" 15"$25,000-$29,999" 16"$30,000-$34,999" 17"$35,000-$39,999" 18"$40,000-$44,999" 19"$45000-$49,999" 21"50,000-$59,000" 23"$60,000-$69,000" 26"$70,000-$99,999" 27"$100,000+",replace
replace household_income = 27 if household_income == 28|household_income == 29|household_income == 30
label values household_income household_income
gen income = 0 
replace income = 5000 if household_income == 3
replace income = 6499.5 if household_income == 4
replace income = 8999.5 if household_income == 6
replace income = 10999.5 if household_income == 8 
replace income = 13499.5 if household_income == 10
replace income = 17499.5 if household_income == 11
replace income = 22499.5 if household_income == 13
replace income = 27499.5 if household_income == 15
replace income = 32499.5 if household_income == 16
replace income = 37499.5 if household_income == 17
replace income = 42499.5 if household_income == 18
replace income = 47499.5 if household_income == 19
replace income = 54500 if household_income == 21
replace income = 64500 if household_income == 23
replace income = 84999.5 if household_income == 26
replace income = 100000 if household_income == 27

gen dm = monthly_date
format dm %10.0g
gen date = dofm(dm)
format date %tm
gen m =month(date)
gen y = year(date)

gen income_category = .
replace income_category  = 1 if (y == 2004) & (size == 1) & income <= 12103
replace income_category  = 1 if (y == 2004) & (size == 2) & income <= 16237
replace income_category  = 1 if (y == 2004) & (size == 3) & income <= 20371
replace income_category  = 1 if (y == 2004) & (size == 4) & income <= 24505
replace income_category  = 1 if (y == 2004) & (size == 5) & income <= 28639
replace income_category  = 1 if (y == 2004) & (size == 6) & income <= 32784
replace income_category  = 1 if (y == 2004) & (size == 7) & income <= 36907
replace income_category  = 1 if (y == 2004) & (size == 8) & income <= 41041
replace income_category  = 1 if (y == 2004) & (size == 9) & income <= 45175

replace income_category  = 3 if (y == 2004) & (size == 1) & income > 65170
replace income_category  = 3 if (y == 2004) & (size == 2) & income > 87430
replace income_category  = 3 if (y == 2004) & (size == 3) & household_income == 27
replace income_category  = 3 if (y == 2004) & (size == 4) & household_income == 27
replace income_category  = 3 if (y == 2004) & (size == 5) & household_income == 27
replace income_category  = 3 if (y == 2004) & (size == 6) & household_income == 27
replace income_category  = 3 if (y == 2004) & (size == 7) & household_income == 27
replace income_category  = 3 if (y == 2004) & (size == 8) & household_income == 27 
replace income_category  = 3 if (y == 2004) & (size == 9) & household_income == 27

replace income_category  = 1 if (y == 2005) & (size == 1) & income <= 12675
replace income_category  = 1 if (y == 2005) & (size == 2) & income <= 16679
replace income_category  = 1 if (y == 2005) & (size == 3) & income <= 20917
replace income_category  = 1 if (y == 2005) & (size == 4) & income <= 25155
replace income_category  = 1 if (y == 2005) & (size == 5) & income <= 29393
replace income_category  = 1 if (y == 2005) & (size == 6) & income <= 33631
replace income_category  = 1 if (y == 2005) & (size == 7) & income <= 37856
replace income_category  = 1 if (y == 2005) & (size == 8) & income <= 42107
replace income_category  = 1 if (y == 2005) & (size == 9) & income <= 46345

replace income_category  = 3 if (y == 2005) & (size == 1) & income >= 68250
replace income_category  = 3 if (y == 2005) & (size == 2) & income >= 89810
replace income_category  = 3 if (y == 2005) & (size == 3) & household_income == 27
replace income_category  = 3 if (y == 2005) & (size == 4) & household_income == 27
replace income_category  = 3 if (y == 2005) & (size == 5) & household_income == 27
replace income_category  = 3 if (y == 2005) & (size == 6) & household_income == 27
replace income_category  = 3 if (y == 2005) & (size == 7) & household_income == 27
replace income_category  = 3 if (y == 2005) & (size == 8) & household_income == 27
replace income_category  = 3 if (y == 2005) & (size == 9) & household_income == 27

replace income_category  = 1 if (y == 2006) & (size == 1) & income <= 12740
replace income_category  = 1 if (y == 2006) & (size == 2) & income <= 17160
replace income_category  = 1 if (y == 2006) & (size == 3) & income <= 21580
replace income_category  = 1 if (y == 2006) & (size == 4) & income <= 26000
replace income_category  = 1 if (y == 2006) & (size == 5) & income <= 30420
replace income_category  = 1 if (y == 2006) & (size == 6) & income <= 34840
replace income_category  = 1 if (y == 2006) & (size == 7) & income <= 39260
replace income_category  = 1 if (y == 2006) & (size == 8) & income <= 43680
replace income_category  = 1 if (y == 2006) & (size == 9) & income <= 48100

replace income_category  = 3 if (y == 2006) & (size == 1) & income >= 68600
replace income_category  = 3 if (y == 2006) & (size == 2) & income >= 92400
replace income_category  = 3 if (y == 2006) & (size == 3) & household_income == 27
replace income_category  = 3 if (y == 2006) & (size == 4) & household_income == 27
replace income_category  = 3 if (y == 2006) & (size == 5) & household_income == 27
replace income_category  = 3 if (y == 2006) & (size == 6) & household_income == 27
replace income_category  = 3 if (y == 2006) & (size == 7) & household_income == 27
replace income_category  = 3 if (y == 2006) & (size == 8) & household_income == 27
replace income_category  = 3 if (y == 2006) & (size == 9) & household_income == 27

replace income_category  = 1 if (y == 2007) & (size == 1) & income <= 13273
replace income_category  = 1 if (y == 2007) & (size == 2) & income <= 17797
replace income_category  = 1 if (y == 2007) & (size == 3) & income <= 22321
replace income_category  = 1 if (y == 2007) & (size == 4) & income <= 26845
replace income_category  = 1 if (y == 2007) & (size == 5) & income <= 31369
replace income_category  = 1 if (y == 2007) & (size == 6) & income <= 35893
replace income_category  = 1 if (y == 2007) & (size == 7) & income <= 40417
replace income_category  = 1 if (y == 2007) & (size == 8) & income <= 44941
replace income_category  = 1 if (y == 2007) & (size == 9) & income <= 49465

replace income_category  = 3 if (y == 2007) & (size == 1) & income >= 71470
replace income_category  = 3 if (y == 2007) & (size == 2) & income >= 95830
replace income_category  = 3 if (y == 2007) & (size == 3) & household_income == 27
replace income_category  = 3 if (y == 2007) & (size == 4) & household_income == 27
replace income_category  = 3 if (y == 2007) & (size == 5) & household_income == 27
replace income_category  = 3 if (y == 2007) & (size == 6) & household_income == 27
replace income_category  = 3 if (y == 2007) & (size == 7) & household_income == 27
replace income_category  = 3 if (y == 2007) & (size == 8) & household_income == 27
replace income_category  = 3 if (y == 2007) & (size == 9) & household_income == 27

replace income_category  = 1 if (y == 2008) & (size == 1) & income <= 13520
replace income_category  = 1 if (y == 2008) & (size == 2) & income <= 18200
replace income_category  = 1 if (y == 2008) & (size == 3) & income <= 22880
replace income_category  = 1 if (y == 2008) & (size == 4) & income <= 27560
replace income_category  = 1 if (y == 2008) & (size == 5) & income <= 32240
replace income_category  = 1 if (y == 2008) & (size == 6) & income <= 36920
replace income_category  = 1 if (y == 2008) & (size == 7) & income <= 41600
replace income_category  = 1 if (y == 2008) & (size == 8) & income <= 46280
replace income_category  = 1 if (y == 2008) & (size == 9) & income <= 50960

replace income_category  = 3 if (y == 2008) & (size == 1) & income >= 72800
replace income_category  = 3 if (y == 2008) & (size == 2) & income >= 98000
replace income_category  = 3 if (y == 2008) & (size == 3) & household_income == 27
replace income_category  = 3 if (y == 2008) & (size == 4) & household_income == 27
replace income_category  = 3 if (y == 2008) & (size == 5) & household_income == 27
replace income_category  = 3 if (y == 2008) & (size == 6) & household_income == 27
replace income_category  = 3 if (y == 2008) & (size == 7) & household_income == 27
replace income_category  = 3 if (y == 2008) & (size == 8) & household_income == 27
replace income_category  = 3 if (y == 2008) & (size == 9) & household_income == 27

replace income_category  = 1 if (y == 2009) & (size == 1) & income <= 14079
replace income_category  = 1 if (y == 2009) & (size == 2) & income <= 18941
replace income_category  = 1 if (y == 2009) & (size == 3) & income <= 23803
replace income_category  = 1 if (y == 2009) & (size == 4) & income <= 28665
replace income_category  = 1 if (y == 2009) & (size == 5) & income <= 33527
replace income_category  = 1 if (y == 2009) & (size == 6) & income <= 38389
replace income_category  = 1 if (y == 2009) & (size == 7) & income <= 43251
replace income_category  = 1 if (y == 2009) & (size == 8) & income <= 48113
replace income_category  = 1 if (y == 2009) & (size == 9) & income <= 52975

replace income_category  = 3 if (y == 2009) & (size == 1) & income >= 75810
replace income_category  = 3 if (y == 2009) & (size == 2) & household_income == 27
replace income_category  = 3 if (y == 2009) & (size == 3) & household_income == 27
replace income_category  = 3 if (y == 2009) & (size == 4) & household_income == 27
replace income_category  = 3 if (y == 2009) & (size == 5) & household_income == 27
replace income_category  = 3 if (y == 2009) & (size == 6) & household_income == 27
replace income_category  = 3 if (y == 2009) & (size == 7) & household_income == 27
replace income_category  = 3 if (y == 2009) & (size == 8) & household_income == 27
replace income_category  = 3 if (y == 2009) & (size == 9) & household_income == 27

replace income_category  = 1 if (y == 2010) & (size == 1) & income <= 14079
replace income_category  = 1 if (y == 2010) & (size == 2) & income <= 18941
replace income_category  = 1 if (y == 2010) & (size == 3) & income <= 23803
replace income_category  = 1 if (y == 2010) & (size == 4) & income <= 28665
replace income_category  = 1 if (y == 2010) & (size == 5) & income <= 33527
replace income_category  = 1 if (y == 2010) & (size == 6) & income <= 38389
replace income_category  = 1 if (y == 2010) & (size == 7) & income <= 43251
replace income_category  = 1 if (y == 2010) & (size == 8) & income <= 48113
replace income_category  = 1 if (y == 2010) & (size == 9) & income <= 52975

replace income_category  = 3 if (y == 2010) & (size == 1) & income >= 75810
replace income_category  = 3 if (y == 2010) & (size == 2) & household_income == 27
replace income_category  = 3 if (y == 2010) & (size == 3) & household_income == 27
replace income_category  = 3 if (y == 2010) & (size == 4) & household_income == 27
replace income_category  = 3 if (y == 2010) & (size == 5) & household_income == 27
replace income_category  = 3 if (y == 2010) & (size == 6) & household_income == 27
replace income_category  = 3 if (y == 2010) & (size == 7) & household_income == 27
replace income_category  = 3 if (y == 2010) & (size == 8) & household_income == 27
replace income_category  = 3 if (y == 2010) & (size == 9) & household_income == 27

replace income_category  = 1 if (y == 2011) & (size == 1) & income <= 14157
replace income_category  = 1 if (y == 2011) & (size == 2) & income <= 19123
replace income_category  = 1 if (y == 2011) & (size == 3) & income <= 24089
replace income_category  = 1 if (y == 2011) & (size == 4) & income <= 29055
replace income_category  = 1 if (y == 2011) & (size == 5) & income <= 34021
replace income_category  = 1 if (y == 2011) & (size == 6) & income <= 38987
replace income_category  = 1 if (y == 2011) & (size == 7) & income <= 43953
replace income_category  = 1 if (y == 2011) & (size == 8) & income <= 48919
replace income_category  = 1 if (y == 2011) & (size == 9) & income <= 53885

replace income_category  = 3 if (y == 2011) & (size == 1) & income >= 76230
replace income_category  = 3 if (y == 2011) & (size == 2) & household_income == 27
replace income_category  = 3 if (y == 2011) & (size == 3) & household_income == 27
replace income_category  = 3 if (y == 2011) & (size == 4) & household_income == 27
replace income_category  = 3 if (y == 2011) & (size == 5) & household_income == 27
replace income_category  = 3 if (y == 2011) & (size == 6) & household_income == 27
replace income_category  = 3 if (y == 2011) & (size == 7) & household_income == 27
replace income_category  = 3 if (y == 2011) & (size == 8) & household_income == 27
replace income_category  = 3 if (y == 2011) & (size == 9) & household_income == 27

replace income_category  = 1 if (y == 2012) & (size == 1) & income <= 14521
replace income_category  = 1 if (y == 2012) & (size == 2) & income <= 19669
replace income_category  = 1 if (y == 2012) & (size == 3) & income <= 24817
replace income_category  = 1 if (y == 2012) & (size == 4) & income <= 29965
replace income_category  = 1 if (y == 2012) & (size == 5) & income <= 35113
replace income_category  = 1 if (y == 2012) & (size == 6) & income <= 40261
replace income_category  = 1 if (y == 2012) & (size == 7) & income <= 45409
replace income_category  = 1 if (y == 2012) & (size == 8) & income <= 50557
replace income_category  = 1 if (y == 2012) & (size == 9) & income <= 55705

replace income_category  = 3 if (y == 2012) & (size == 1) & income >= 78190
replace income_category  = 3 if (y == 2012) & (size == 2) & household_income == 27
replace income_category  = 3 if (y == 2012) & (size == 3) & household_income == 27
replace income_category  = 3 if (y == 2012) & (size == 4) & household_income == 27
replace income_category  = 3 if (y == 2012) & (size == 5) & household_income == 27
replace income_category  = 3 if (y == 2012) & (size == 6) & household_income == 27
replace income_category  = 3 if (y == 2012) & (size == 7) & household_income == 27
replace income_category  = 3 if (y == 2012) & (size == 8) & household_income == 27
replace income_category  = 3 if (y == 2012) & (size == 9) & household_income == 27

replace income_category  = 1 if (y == 2013) & (size == 1) & income <= 14937
replace income_category  = 1 if (y == 2013) & (size == 2) & income <= 20163
replace income_category  = 1 if (y == 2013) & (size == 3) & income <= 25389
replace income_category  = 1 if (y == 2013) & (size == 4) & income <= 30615
replace income_category  = 1 if (y == 2013) & (size == 5) & income <= 35841
replace income_category  = 1 if (y == 2013) & (size == 6) & income <= 41067
replace income_category  = 1 if (y == 2013) & (size == 7) & income <= 46293
replace income_category  = 1 if (y == 2013) & (size == 8) & income <= 51519
replace income_category  = 1 if (y == 2013) & (size == 9) & income <= 56745

replace income_category  = 3 if (y == 2013) & (size == 1) & income >= 80430
replace income_category  = 3 if (y == 2013) & (size == 2) & household_income == 27
replace income_category  = 3 if (y == 2013) & (size == 3) & household_income == 27
replace income_category  = 3 if (y == 2013) & (size == 4) & household_income == 27
replace income_category  = 3 if (y == 2013) & (size == 5) & household_income == 27
replace income_category  = 3 if (y == 2013) & (size == 6) & household_income == 27
replace income_category  = 3 if (y == 2013) & (size == 7) & household_income == 27
replace income_category  = 3 if (y == 2013) & (size == 8) & household_income == 27
replace income_category  = 3 if (y == 2013) & (size == 9) & household_income == 27

replace income_category  = 1 if (y == 2014) & (size == 1) & income <= 15171
replace income_category  = 1 if (y == 2014) & (size == 2) & income <= 20449
replace income_category  = 1 if (y == 2014) & (size == 3) & income <= 25727
replace income_category  = 1 if (y == 2014) & (size == 4) & income <= 31005
replace income_category  = 1 if (y == 2014) & (size == 5) & income <= 36283
replace income_category  = 1 if (y == 2014) & (size == 6) & income <= 41561
replace income_category  = 1 if (y == 2014) & (size == 7) & income <= 46839
replace income_category  = 1 if (y == 2014) & (size == 8) & income <= 52117
replace income_category  = 1 if (y == 2014) & (size == 9) & income <= 57395

replace income_category  = 3 if (y == 2014) & (size == 1) & income >= 81690
replace income_category  = 3 if (y == 2014) & (size == 2) & household_income == 27
replace income_category  = 3 if (y == 2014) & (size == 3) & household_income == 27
replace income_category  = 3 if (y == 2014) & (size == 4) & household_income == 27
replace income_category  = 3 if (y == 2014) & (size == 5) & household_income == 27
replace income_category  = 3 if (y == 2014) & (size == 6) & household_income == 27
replace income_category  = 3 if (y == 2014) & (size == 7) & household_income == 27
replace income_category  = 3 if (y == 2014) & (size == 8) & household_income == 27
replace income_category  = 3 if (y == 2014) & (size == 9) & household_income == 27

replace income_category = 2 if income_category == . 

label define income_category 1"low income" 2"middle income" 3"high income"

label values income_category income_category

label define race 1"White/Caucasian" 2"Black/African American" 3"Asian" 4"Other"
label values race race


label define hispanic_origin 1"yes" 0"no"
replace hispanic_origin = 0 if hispanic_origin == 2
label values hispanic_origin hispanic_origin

label define gender 1"female head" 2"male head" 3"couple"
label values gender gender

label define empstat 1"non-employed" 2"employed, part-time" 3"employed, full-time"
label values empstat empstat

merge m:1 fips_code using "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\fips_county_data\fips_county_data.dta"
drop if _merge == 2
drop _merge fips_county_name fips_state_name



label var P1 p_freshred
label var P2 p_frozenred
label var P3 p_processedred
label var P4 p_freshother
label var P5 p_frozenother
label var P6 p_processedother

label var Q1 q_freshred
label var Q2 q_frozenred
label var Q3 q_processedred
label var Q4 q_freshother
label var Q5 q_frozenother
label var Q6 q_processedother


drop dm date m y

save "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\panelgroup_household_level_processed.dta", replace

