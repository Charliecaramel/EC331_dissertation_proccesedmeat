# Estimating Price Elasticity of Demand for Processed and Red Meats, and Instrumental Variable Approach

This is a repository created for documenting the commands used for my undergraduate dissertation. The abstract of this paper is avaliable below. We use this space to create a hub of files where you can replicate my results. 


## Abstract
This study assesses the consumption effects of introducing a processed and red meat tax in the United States. We do this by estimating price elasticities for American households using an Instrumental Variable approach, and the Instrument we use is the price effects of the 2011-2012 drought. Using the Nielson homescan dataset, we estimated a two-stage pooled-IV model for unprocessed and processed red meats consumption. The estimated accounts for price endogeneity and household non-purchases. The results demonstrated that processed red meat price elasticity of demand for American households is at -0.29, suggesting a small consumption response to a processed meat tax. 

## How to use this github
There are a number of files avaliable on this repository. If you would like to replicate my results, please email me to request the dataset. Upon recieving the raw data, first you will have to clean the upc codes dataset. This step allows you to identify the Nielson constructed product modules and product groups. This can be done by using the commands in "upc_code_processing.do". Once you have followed the instructions in the file, you may proceed to running the commands of the files "processing_masterdata_panel_meat_groups.do" and "processing_masterdata_panel_meat_module.do" to clean the raw data and construct the dataset used for analysis. 
Please feel free to message me if you have any questions.
