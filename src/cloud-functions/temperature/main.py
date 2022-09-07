import json
import ee
from datetime import date, datetime, timedelta
import os
import urllib.request
import geojson
import shapely
from google.auth import compute_engine
from shapely import wkt

def get_temp_month(request):

#       url = "http://metadata.google.internal/computeMetadata/v1/project/project-id"
#       req = urllib.request.Request(url)
#       req.add_header("Metadata-Flavor", "Google")
#       project_id = urllib.request.urlopen(req).read().decode()
#       service_account = os.environ['SERVICE_ACCOUNT']
#       credentials = ee.ServiceAccountCredentials(service_account, 'eeKey.json')
#       ee.Initialize(credentials=credentials, project=project_id)

      scopes = ["https://www.googleapis.com/auth/earthengine"]
      credentials = compute_engine.Credentials(scopes=scopes)
      ee.Initialize(credentials)

      request_json = request.get_json(silent=True)
      print('Req Json',type(request_json))
      replies = []
      calls = request_json['calls']
      for call in calls:

        farm_json_str = call[0]
        #farm_name = call[1]
        farm_year = call[1]
        farm_mon = call[2]
        farm_json = shapely.wkt.loads(farm_json_str)
        farm_poly = geojson.Feature(geometry=farm_json, properties={})
        farm_aoi = ee.Geometry(farm_poly.geometry)

        #print("Farm ",farm_name)

        ee_temp = farm_temp_calc(farm_aoi,farm_year,farm_mon)
        #ndvi = ee_ndvi.getInfo()

        replies.append(ee_temp)
      return json.dumps({'replies': [str(x) for x in ee.List(replies).getInfo()]})

def farm_temp_calc(farm_aoi,year,month):
  
  first_date = datetime(year, month, 1)
  startDate = first_date.strftime("%Y-%m-%d")
  last_date = datetime(year, month + 1, 1) + timedelta(days=-1)
  endDate = last_date.strftime("%Y-%m-%d")
  terra = terra = ee.ImageCollection("IDAHO_EPSCOR/TERRACLIMATE")
  tmaxScaled = terra.filter(ee.Filter.date(startDate, endDate)).mean().select('tmmx').multiply(0.1)

  tempValue = tmaxScaled.reduceRegion(**{
    'geometry': farm_aoi,
    'reducer': ee.Reducer.mean(),
    'scale': 30
  }).get('tmmx'); 
  return tempValue
