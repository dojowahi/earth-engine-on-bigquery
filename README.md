# Analyzing Satellite Imagery via BigQuery SQL
The goal of this demo is to run a BigQuery SQL and extract information from Google Earth Engine

## Requirements
* Earth Engine access to a service account --> [EE SA signup process](https://developers.google.com/earth-engine/guides/service_account)
* A Google Cloud project with billing enabled, Cloud Functions, Earth Engine APIs enabled


## Setting up the demo
In Cloud Shell or other environment where you have the gcloud SDK installed, do:
* gcloud components update
* git clone https://github.com/dojowahi/earth-engine-on-bigquery.git
* cd earth-engine-on-bigquery

Before executing setup.sh ensure the value of ee_sa in setup.sh reflects the name of service account which has access to EE
* sh setup.sh

If the shell script has executed successfully, you should now have a dataset gee and table land_point under your project in BigQuery along with a function get_ndvi_month. You will also see a sample query output with ndvi values on the Cloud shell.
