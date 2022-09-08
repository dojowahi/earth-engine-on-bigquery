# Analyzing Satellite Imagery via BigQuery SQL
The goal of this demo is to run a BigQuery SQL and extract information from Google Earth Engine

## Requirements
* Ensure your GCP user has access to Earth Engine. You can signup for Earth Engine at :- [Earth Engine Signup](https://signup.earthengine.google.com/)
* Ensure the GCP user is allowed to create service accounts and assign roles


## Setting up the demo
**1)** In Cloud Shell or other environment where you have the gcloud SDK installed, execute the following commands:
```console
gcloud components update 
cd $HOME
git clone https://github.com/dojowahi/earth-engine-on-bigquery.git
cd ~/earth-engine-on-bigquery
chmod +x *.sh
```

**2)** **Edit config.sh** - In your editor of choice update the variables in config.sh to reflect your desired gcp project.

**3)** Next execute the command below

```console
sh deploy.sh
```

If the shell script has executed successfully, you should now have a new Service Account, a dataset gee and table land_coords under your project in BigQuery along with a functions get_ndvi_month and get_temp_month. 
<br/><br/>
You will also see a sample query output on the Cloud shell, as shown below
<br/><br/>
![BQ output](/img/deploy.png)

**4)** A Service Account(SA) in format <Project_Number>-compute@developer.gserviceaccount.com was created in previous step, you need to signup this SA for Earth Engine at [EE SA signup](https://signup.earthengine.google.com/#!/service_accounts). Check out the last line of the screenshot above it will list out SA name
<br/><br/>
**5)** Once signup is complete execute the command below in Cloudshell
```console
bq query --use_legacy_sql=false 'SELECT name,gee.get_poly_ndvi_month(farm_aoi,2020,7) as ndvi_jul, gee.get_poly_temp_month(farm_aoi,2020,7) as temp_jul  FROM `gee.land_coords` LIMIT 10'
```
You will also see the NDVI output on the Cloud shell, as shown below
<br/><br/>
![NDVI output](/img/output.png)

<br/><br/>
## Congrats! You just executed BigQuery SQL over Landsat imagery
