#!/bin/bash

#####################################################################################################
# Script Name: setup_sa.sh
# Date of Creation: 9/26/2022
# Author: Ankur Wahi
# Updated: 9/26/2022
#####################################################################################################



source ./config.sh
gcloud auth login ${USER_EMAIL}
echo "Assigning IAM Permissions"
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

gcloud services enable bigqueryconnection.googleapis.com

gcloud services enable cloudfunctions.googleapis.com

gcloud services enable earthengine.googleapis.com

gcloud services enable artifactregistry.googleapis.com

gcloud services enable run.googleapis.com

gcloud services enable cloudbuild.googleapis.com

PROJECT_NUMBER=$(gcloud projects list --filter="project_id:${PROJECT_ID}"  --format='value(project_number)')



SERVICE_ACCOUNT=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com 
echo "Compute engine SA - ${SERVICE_ACCOUNT}"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${SERVICE_ACCOUNT} \
    --role=roles/serviceusage.serviceUsageAdmin
    
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${SERVICE_ACCOUNT} \
    --role=roles/earthengine.admin

sleep 15

# gcloud iam service-accounts keys create ~/eeKey.json --iam-account ${SERVICE_ACCOUNT}
# cd ~/
# cp eeKey.json ~/earth-engine-on-bigquery/src/cloud-functions/ndvi/
# cp eeKey.json ~/earth-engine-on-bigquery/src/cloud-functions/temperature/
# cp eeKey.json ~/earth-engine-on-bigquery/src/cloud-functions/crop/

# Cloud function setup for EE

project_id=${PROJECT_ID}

ee_sa=${SERVICE_ACCOUNT}

echo "Earth engine SA: ${ee_sa}"


#Create the external connection for BQ

bq mk --connection --display_name='my_gcf_ee_conn' \
      --connection_type=CLOUD_RESOURCE \
      --project_id=$(gcloud config get-value project) \
      --location=US  gcf-ee-conn

#Get serviceAccountID associated with the connection  

serviceAccountId=`bq show --location=US --connection --format=json gcf-ee-conn| jq -r '.cloudResource.serviceAccountId'`
echo "Service Account: ${serviceAccountId}"

# Add Cloud run admin
gcloud projects add-iam-policy-binding \
$(gcloud config get-value project) \
--member='serviceAccount:'${serviceAccountId} \
--role='roles/run.admin'

echo "export ee_sa=${ee_sa}" >> ~/earth-engine-on-bigquery/config.sh

echo ""
echo " NOW sign up service account ${ee_sa} at https://signup.earthengine.google.com/#!/service_accounts "
echo ""
