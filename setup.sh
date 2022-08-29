##################################################
##
## Create and Configure GCP project for dekart
##
##################################################

# source the previously set env variables
source ./config.sh

# prompt user to login
gcloud auth login ${USER_EMAIL}

##################################################
##
## Project
##
##################################################

echo "Creating new project"

gcloud projects create ${PROJECT_ID}

echo "Set default project"

gcloud config set project ${PROJECT_ID}

##################################################
##
## Billing
##
##################################################

echo "Assigning billing account"

gcloud beta billing projects link ${PROJECT_ID} --billing-account=${BILLING_ACCOUNT_ID}

##################################################
##
## Org Policies
##
##################################################

echo "configuring org policies at project level"

#enable VPC peering, disabled in argolis
cat <<EOF > new_policy.yaml
constraint: constraints/compute.restrictVpcPeering
listPolicy:
    allValues: ALLOW
EOF
gcloud resource-manager org-policies set-policy \
    --project=${PROJECT_ID} new_policy.yaml

#disable the shielded vm requirement, enabled in argolis
gcloud resource-manager org-policies disable-enforce \
    compute.requireShieldedVm --project=${PROJECT_ID}

#allow external IPs for app engine, disabled in argolis
    cat <<EOF > new_policy.yaml
constraint: constraints/compute.vmExternalIpAccess
listPolicy:
    allValues: ALLOW
EOF
gcloud resource-manager org-policies set-policy  \
    --project=${PROJECT_ID} new_policy.yaml
    
#enable Cloud Function
cat <<EOF > new_policy.yaml
constraint: constraints/cloudfunctions.allowedIngressSettings
listPolicy:
    allValues: ALLOW
EOF
gcloud resource-manager org-policies set-policy \
    --project=${PROJECT_ID} new_policy.yaml
    
    
#enable Key creation
cat <<EOF > new_policy.yaml
constraint: constraints/iam.disableServiceAccountKeyCreation
boolean_policy:
    enforced: false
EOF
gcloud resource-manager org-policies set-policy \
    --project=${PROJECT_ID} new_policy.yaml

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
