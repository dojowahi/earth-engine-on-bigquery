#!/bin/bash

#####################################################################################################
# Script Name: setup.sh
# Date of Creation: 8/11/2022
# Author: Ankur Wahi
# Updated: 8/25/2022
#####################################################################################################

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


source ./config.sh
gcloud config set project ${PROJECT_ID}

##################################################
##
## Enable APIs
##
##################################################

echo "enabling the necessary APIs"

gcloud services enable compute.googleapis.com

gcloud services enable storage.googleapis.com

gcloud services enable bigquery.googleapis.com

gcloud services enable appengine.googleapis.com

gcloud services enable appengineflex.googleapis.com

gcloud services enable appengineflex.googleapis.com

gcloud services enable bigqueryconnection.googleapis.com

gcloud services enable cloudfunctions.googleapis.com

gcloud services enable earthengine.googleapis.com

echo "Creating App Engine app" 

gcloud app create --region=${APP_ENGINE_REGION}

SERVICE_ACCOUNT=${PROJECT_ID}@appspot.gserviceaccount.com 
    
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${SERVICE_ACCOUNT} \
    --role=roles/serviceusage.serviceUsageAdmin
    
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${SERVICE_ACCOUNT} \
    --role=roles/earthengine.admin
    
# gcloud iam service-accounts keys create ~/eeKey.json --iam-account ${SERVICE_ACCOUNT}
# cd ~/
# cp eeKey.json ~/earth-engine-on-bigquery/src/cloud-functions/ndvi/
# cp eeKey.json ~/earth-engine-on-bigquery/src/cloud-functions/temperature/
# cp eeKey.json ~/earth-engine-on-bigquery/src/cloud-functions/crop/

# Cloud function setup for EE

project_id=${PROJECT_ID}
cf_ndvi="polyNDVIcf"
cf_temp="polyTempcf"
ee_sa=${SERVICE_ACCOUNT}
cd ~/earth-engine-on-bigquery/src/cloud-functions/ndvi

echo "Earth engine SA: ${ee_sa}"
gcloud config set project ${project_id}

echo "Waiting for services to be enabled.."
sleep 15

#Create the external connection for BQ

bq mk --connection --display_name='my_gcf_ee_conn' \
      --connection_type=CLOUD_RESOURCE \
      --project_id=$(gcloud config get-value project) \
      --location=US  gcf-ee-conn

#Get serviceAccountID assocaited with the connection  

serviceAccountId=`bq show --location=US --connection --format=json gcf-ee-conn| jq -r '.cloudResource.serviceAccountId'`
echo "Service Account: ${serviceAccountId}"

gcloud functions deploy ${cf_ndvi} --entry-point get_ndvi_month --runtime python39 --trigger-http --allow-unauthenticated --set-env-vars SERVICE_ACCOUNT=${ee_sa} --project ${project_id} --service-account ${ee_sa} --memory 2048MB

cd ~/earth-engine-on-bigquery/src/cloud-functions/temperature

gcloud functions deploy ${cf_temp} --entry-point get_temp_month --runtime python39 --trigger-http --allow-unauthenticated --set-env-vars SERVICE_ACCOUNT=${ee_sa} --project ${project_id} --service-account ${ee_sa} --memory 2048MB

#Add Cloud Invoker function role

gcloud projects add-iam-policy-binding \
$(gcloud config get-value project) \
--member='serviceAccount:'${serviceAccountId} \
--role='roles/cloudfunctions.invoker'


endpoint_ndvi=$(gcloud functions describe ${cf_ndvi} --region=us-central1 --format=json | jq -r '.httpsTrigger.url')
endpoint_temp=$(gcloud functions describe ${cf_temp} --region=us-central1 --format=json | jq -r '.httpsTrigger.url')


bq mk -d gee

    
# build_sql="CREATE OR REPLACE FUNCTION gee.get_ndvi_month(lon float64,lat float64, farm_name STRING, year int64, month int64) RETURNS STRING REMOTE WITH CONNECTION \`${project_id}.us.gcf-ee-conn\` OPTIONS ( endpoint = '${endpoint}')"

build_sql="CREATE OR REPLACE FUNCTION gee.get_poly_ndvi_month(farm_aoi STRING, year int64, month int64) RETURNS STRING REMOTE WITH CONNECTION \`${project_id}.us.gcf-ee-conn\` OPTIONS ( endpoint = '${endpoint_ndvi}')"

    
bq query --use_legacy_sql=false ${build_sql}

build_sql="CREATE OR REPLACE FUNCTION gee.get_poly_temp_month(farm_aoi STRING, year int64, month int64) RETURNS STRING REMOTE WITH CONNECTION \`${project_id}.us.gcf-ee-conn\` OPTIONS ( endpoint = '${endpoint_temp}')"

    
bq query --use_legacy_sql=false ${build_sql}



#bq load --source_format=CSV --replace=true --skip_leading_rows=1  --schema=lon:FLOAT,lat:FLOAT,name:STRING ${project_id}:gee.land_coords  ./land_point.csv 

#bq query --use_legacy_sql=false 'SELECT gee.get_ndvi_month(lon,lat,name,2020,7) as ndvi_jul FROM `gee.land_coords` LIMIT 10'

cd ~/earth-engine-on-bigquery/src/data

bq load --source_format=CSV --replace=true --skip_leading_rows=1  --schema=farm_aoi:STRING,name:STRING ${project_id}:gee.land_coords  ./farm_dim.csv 

sleep 60

#bq query --use_legacy_sql=false 'SELECT gee.get_poly_ndvi_month(farm_aoi,2020,7) as ndvi_jul FROM `gee.land_coords` LIMIT 10'
bq query --use_legacy_sql=false 'SELECT * from `gee.land_coords` LIMIT 10'
echo ""
echo " NOW sign up service account ${SERVICE_ACCOUNT} at https://signup.earthengine.google.com/#!/service_accounts "
echo ""
