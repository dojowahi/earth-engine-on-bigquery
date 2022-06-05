# Analyzing Satellite Imagery via BigQuery SQL
Executing operations with consistent frequency is a common task in many satellite remote sensing frameworks, e.g., weekly estimates of crop production or daily detection of burned areas. Once developed, such routines can be automated to simplify execution and delivery. The following is a simple example of using Cloud Scheduler to automate the export of 16-day Landsat NDVI composites in Earth Engine.

## Requirements
* Earth Engine access
* A Google Cloud project with billing enabled, Cloud Functions, Earth Engine APIs enabled
* An Earth Engine authorized service account

## Setting up the demo
