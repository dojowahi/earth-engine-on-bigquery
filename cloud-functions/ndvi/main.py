import json
import ee
from datetime import date, datetime, timedelta
import os
import urllib.request


def get_ndvi_month(request):
      url = "http://metadata.google.internal/computeMetadata/v1/project/project-id"
      req = urllib.request.Request(url)
      req.add_header("Metadata-Flavor", "Google")
      project_id = urllib.request.urlopen(req).read().decode()
      service_account = os.environ['SERVICE_ACCOUNT']
      credentials = ee.ServiceAccountCredentials(service_account, 'eeKey.json')
      ee.Initialize(credentials=credentials, project=project_id)
      
      request_json = request.get_json(silent=True)
      print('Req Json',type(request_json))
      replies = []
      calls = request_json['calls']
      for call in calls:
        farm_lon = call[0]
        farm_lat = call[1]
        farm_name = call[2]
        farm_year = call[3]
        farm_mon = call[4]
        
        farm_poi = (farm_lon,farm_lat)

        ee_ndvi = farm_ndvi_calc(farm_poi,farm_year,farm_mon)
        ndvi = ee_ndvi.getInfo()

        replies.append({
          'farm_name': f'{farm_name}',
          'farm_ndvi': f'{ndvi}'
        })
      return json.dumps({
        # each reply is a STRING (JSON not currently supported)
        'replies': [json.dumps(reply) for reply in replies]
      })

def farm_ndvi_calc(farm_poi,year,month):
  
  startDate = '2020-01-01'
  endDate = '2021-01-01'
  first_date = datetime(year, month, 1)
  startDate = first_date.strftime("%Y-%m-%d")
  last_date = datetime(year, month + 1, 1) + timedelta(days=-1)
  endDate = last_date.strftime("%Y-%m-%d")
  landsat8 = ee.ImageCollection("LANDSAT/LC08/C01/T1_RT")
  filtered = landsat8.filter(ee.Filter.date(startDate, endDate))
  composite = ee.Algorithms.Landsat.simpleComposite(filtered)
  ndviImage = composite.normalizedDifference(['B5', 'B4']).rename('NDVI')
  poi = ee.Geometry.Point(farm_poi)
  ndviValue = ndviImage.reduceRegion(**{
    'geometry': poi,
    'reducer': ee.Reducer.mean(),
    'scale': 30
  }).get('NDVI'); 
  return ndviValue