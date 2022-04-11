clear all

import delimited "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\upc_codes\products.tsv"
describe
save "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\upc_codes\upc_codes_raw_data.dta",replace


* Creating Categories
gen dep_code = department_code
gen dep_label = department_descr
labmask dep_code, value(dep_label)

replace product_group_descr = "LIGHT BULBS, ELECTRIC GOODS" if product_group_code == 5516
gen pg_code = product_group_code
gen pg_label = product_group_descr
labmask pg_code, value(pg_label)

replace product_module_descr = "SALAD DRESSING - MIRACLE WHIP TYPE" if product_module_code == 1173
replace product_module_descr = "INSECTICIDE - ANT & ROACH - OTHER CONTINUOUS PRODUCTS" if product_module_code == 7209
gen pm_code = product_module_code
gen pm_label = product_module_descr
replace pm_code = 9999 if pm_label == ""
replace pm_label = "UNCLASSIFIED" if pm_code == 9999
labmask pm_code, value(pm_label)

save "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\upc_codes\upc_codes_labeled.dta" ,replace

keep upc upc_ver_uc upc_descr brand_code_uc brand_descr multi size1_code_uc size1_amount size1_units dataset_found_uc size1_change_flag_uc dep_code pg_code pm_code
save "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\upc_codes\upc_codes_merge.dta" ,replace

********************************************************************************
* Load commands from the file meat_types AND ensure yearly consistency of the panels before running the following
********************************************************************************
use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel 2004.dta" 
scalar define cpi_2003 = 193.2250100
scalar define cpi_2004 = 196.6416667
scalar define cpi_2005 = 200.8666667
scalar define cpi_2006 = 205.9166667
scalar define cpi_2007 = 210.7250833
scalar define cpi_2008 = 215.5650833
scalar define cpi_2009 = 219.2366667
scalar define cpi_2010 = 221.3358333
scalar define cpi_2011 = 225.0064167
scalar define cpi_2012 = 229.7568333
scalar define cpi_2013 = 233.8104167
scalar define cpi_2014 = 237.9023333



foreach i in  2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 {
	use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\Processed Data\househol_level_data\panel `i'.dta"
	* Generating the average unit values for each item across households to 2004 levels
	by upc, sort: egen w`i'= mean(total_price_paid/quantity)
	sum w`i'
	by upc, sort: gen w`i'_04 = w`i' * (cpi_2004/cpi_`i')
	keep upc upc_ver_uc w`i'_04
	sum w`i'_04
	collapse(first) w`i'_04, by(upc upc_ver)
	save  "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\upc_codes\upc_codes_weights_`i'.dta",replace
}

use "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\upc_codes\upc_codes_merge.dta"
foreach i in 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 {
	merge 1:1 upc upc_ver using  "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\upc_codes\upc_codes_weights_`i'.dta"
	drop _merge
}

gen w = w2004_04
foreach i in 2003 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 {
	replace w= w`i'_04 if w == . 
	replace w= w`i'_04 if w == 0
}
drop w2003_04 w2004_04 w2005_04 w2006_04 w2007_04 w2008_04 w2009_04 w2010_04 w2011_04 w2012_04 w2013_04 w2014_04

save  "C:\Users\cmlvh\OneDrive\桌面\Dissertation - Food data\upc_codes\upc_codes_merge.dta",replace
