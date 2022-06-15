# Cloud function setup for EE

project_id=$(gcloud config get-value project)
cf_ndvi="farmNDVIcf"
ee_sa="xxxxx-xxxxx@xxxxx.gserviceaccount.com"

cd ~/earth-engine-on-bigquery/cloud-functions/ndvi

#Create the external connection for BQ

bq mk --connection --display_name='my_gcf_ee_conn' \
      --connection_type=CLOUD_RESOURCE \
      --project_id=$(gcloud config get-value project) \
      --location=US  gcf-ee-conn

#Get serviceAccountID assocaited with the connection  

serviceAccountId=`bq show --location=US --connection --format=json gcf-ee-conn| jq -r '.cloudResource.serviceAccountId'`


gcloud functions deploy ${cf_ndvi} --entry-point get_ndvi_month --runtime python39 --trigger-http --allow-unauthenticated --set-env-vars SERVICE_ACCOUNT=${ee_sa} --project ${project_id} --service-account ${ee_sa} --memory 2048MB

#Add Cloud Invoker function role

gcloud projects add-iam-policy-binding \
$(gcloud config get-value project) \
--member='serviceAccount:${serviceAccountId} \
--role='roles/cloudfunctions.invoker'


endpoint=$(gcloud functions describe ${cf_ndvi} --region=us-central1 --format=json | jq -r '.httpsTrigger.url')

bq show gee || bq mk -d gee

    
# build_sql="CREATE OR REPLACE FUNCTION gee.get_ndvi_month(lon float64,lat float64, farm_name STRING, year int64, month int64) RETURNS STRING REMOTE WITH CONNECTION \`${project_id}.us.gcf-ee-conn\` OPTIONS ( endpoint = '${endpoint}')"

build_sql="CREATE OR REPLACE FUNCTION gee.get_poly_ndvi_month(farm_aoi STRING, farm_name STRING, year int64, month int64) RETURNS STRING REMOTE WITH CONNECTION \`${project_id}.us.gcf-ee-conn\` OPTIONS ( endpoint = '${endpoint}')"

    
bq query --use_legacy_sql=false ${build_sql}

#bq load --source_format=CSV --replace=true --skip_leading_rows=1  --schema=lon:FLOAT,lat:FLOAT,name:STRING ${project_id}:gee.land_coords  ./land_point.csv 

#bq query --use_legacy_sql=false 'SELECT gee.get_ndvi_month(lon,lat,name,2020,7) as ndvi_jul FROM `gee.land_coords` LIMIT 10'

bq load --source_format=CSV --replace=true --skip_leading_rows=1  --schema=farm_aoi:STRING,name:STRING ${project_id}:gee.land_coords  ./farm_dim.csv 

bq query --use_legacy_sql=false 'SELECT gee.get_poly_ndvi_month(farm_aoi,name,2020,7) as ndvi_jul FROM `gee.farm_dim` LIMIT 10'

