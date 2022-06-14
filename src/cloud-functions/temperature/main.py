import json
import ee
from datetime import date, datetime, timedelta
import geojson
import shapely
from shapely import wkt

def get_temp_month(request):
      service_account = 'earth-engine-343601@appspot.gserviceaccount.com'
      credentials = ee.ServiceAccountCredentials(service_account, 'eeKey.json')
      ee.Initialize(credentials=credentials, project='earth-engine-343601')
      request_json = request.get_json(silent=True)
      print('Req Json',type(request_json))
      replies = []
      calls = request_json['calls']
      for call in calls:
        farm_json_str = call[0]
        farm_name = call[1]
        farm_year = call[2]
        farm_mon = call[3]
        farm_json = shapely.wkt.loads(farm_json_str)
        farm_poly = geojson.Feature(geometry=farm_json, properties={})
        farm_aoi = ee.Geometry(farm_poly.geometry)

        ee_temp = farm_temp_calc(farm_aoi,farm_year,farm_mon)
        farm_temp = ee_temp.getInfo()

        replies.append({
          'farm_name': f'{farm_name}',
          'farm_temp': f'{farm_temp}'
        })
      return json.dumps({
        'replies': [json.dumps(reply) for reply in replies]
      })



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
