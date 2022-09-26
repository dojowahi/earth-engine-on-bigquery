#!/bin/bash

#####################################################################################################
# Script Name: deploy_cf.sh
# Date of Creation: 8/11/2022
# Author: Ankur Wahi
# Updated: 9/26/2022
#####################################################################################################

source ./config.sh

project_id=${PROJECT_ID}
cf_ndvi="polyndvicf-gen2"
cf_temp="polytempcf-gen2"
cd ~/earth-engine-on-bigquery/src/cloud-functions/ndvi

gcloud functions deploy ${cf_ndvi} --entry-point get_ndvi_month --runtime python39 --trigger-http --allow-unauthenticated --set-env-vars SERVICE_ACCOUNT=${ee_sa} --project ${project_id} --service-account ${ee_sa} --gen2 --region ${REGION} --run-service-account ${ee_sa} --memory 256MB

cd ~/earth-engine-on-bigquery/src/cloud-functions/temperature

gcloud functions deploy ${cf_temp} --entry-point get_temp_month --runtime python39 --trigger-http --allow-unauthenticated --set-env-vars SERVICE_ACCOUNT=${ee_sa} --project ${project_id} --service-account ${ee_sa} --gen2 --region ${REGION} --run-service-account ${ee_sa} --memory 256MB

#Add Cloud Invoker function role



endpoint_ndvi=$(gcloud functions describe ${cf_ndvi} --region=${REGION} --gen2 --format=json | jq -r '.serviceConfig.uri')
endpoint_temp=$(gcloud functions describe ${cf_temp} --region=${REGION} --gen2 --format=json | jq -r '.serviceConfig.uri')


bq mk -d gee

    
# build_sql="CREATE OR REPLACE FUNCTION gee.get_ndvi_month(lon float64,lat float64, farm_name STRING, year int64, month int64) RETURNS STRING REMOTE WITH CONNECTION \`${project_id}.us.gcf-ee-conn\` OPTIONS ( endpoint = '${endpoint}')"

build_sql="CREATE OR REPLACE FUNCTION gee.get_poly_ndvi_month(aoi STRING, year int64, month int64) RETURNS STRING REMOTE WITH CONNECTION \`${project_id}.us.gcf-ee-conn\` OPTIONS ( endpoint = '${endpoint_ndvi}')"

    
bq query --use_legacy_sql=false ${build_sql}

build_sql="CREATE OR REPLACE FUNCTION gee.get_poly_temp_month(aoi STRING, year int64, month int64) RETURNS STRING REMOTE WITH CONNECTION \`${project_id}.us.gcf-ee-conn\` OPTIONS ( endpoint = '${endpoint_temp}')"

    
bq query --use_legacy_sql=false ${build_sql}



#bq load --source_format=CSV --replace=true --skip_leading_rows=1  --schema=lon:FLOAT,lat:FLOAT,name:STRING ${project_id}:gee.land_coords  ./land_point.csv 

#bq query --use_legacy_sql=false 'SELECT gee.get_ndvi_month(lon,lat,name,2020,7) as ndvi_jul FROM `gee.land_coords` LIMIT 10'

cd ~/earth-engine-on-bigquery/src/data

bq load --source_format=CSV --replace=true --skip_leading_rows=1  --schema=aoi:STRING,name:STRING ${project_id}:gee.land_coords  ./land_dim.csv 

sleep 60

#bq query --use_legacy_sql=false 'SELECT gee.get_poly_ndvi_month(farm_aoi,2020,7) as ndvi_jul FROM `gee.land_coords` LIMIT 10'
bq query --use_legacy_sql=false 'SELECT * from `gee.land_coords` LIMIT 10'
