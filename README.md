# Analyzing Satellite Imagery via BigQuery SQL
The goal of this demo is to run a BigQuery SQL and extract information from Google Earth Engine

## Requirements
* Earth Engine access to a service account --> [EE SA signup process](https://developers.google.com/earth-engine/guides/service_account). The service account created should have Service Usage Admin, Earth Engine Resource Admin roles enabled. After creating the service account, create a private key and store it in a secure location. The URL for the sign up process lists out all the steps in detail
* A Google Cloud project with billing enabled, Cloud Functions, Earth Engine APIs enabled


## Setting up the demo
In Cloud Shell or other environment where you have the gcloud SDK installed, execute the following commands:
```console
gcloud components update 
cd $HOME
git clone https://github.com/dojowahi/earth-engine-on-bigquery.git
cd earth-engine-on-bigquery 
```

Edit the following files to reflect your environment:

1) setup.sh -- Ensure the value of ee_sa in setup.sh reflects the name of service account which has access to EE
2) eeKey.json -- The value in this file should contain the private you have generated for service account  which has access to EE

```console
sh setup.sh
```

If the shell script has executed successfully, you should now have a dataset gee and table land_point under your project in BigQuery along with a function get_ndvi_month. 
<br/><br/>
You will also see a sample query output with ndvi values on the Cloud shell, as shown below
<br/><br/>
![NDVI output](/img/ndvi_output.png)

<br/><br/>
## Congrats! You just executed BigQuery SQL over Landsat imagery
