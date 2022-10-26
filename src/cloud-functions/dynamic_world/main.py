import json
import ee
from datetime import date, datetime, timedelta
import os
import urllib.request
import geojson
import shapely
from google.auth import compute_engine
from shapely import wkt

scopes = ["https://www.googleapis.com/auth/earthengine"]
credentials = compute_engine.Credentials(scopes=scopes)
ee.Initialize(credentials)


def get_area(request):
     
      request_json = request.get_json(silent=True)
      print('Req Json',type(request_json))
      replies = []
      calls = request_json['calls']
      for call in calls:

        poly_json_str = call[0]
        start_dt = call[1]
        end_dt = call[2]
        area_type = call[3]
        poly_json = shapely.wkt.loads(poly_json_str)
        poly = geojson.Feature(geometry=poly_json, properties={})
        poly_aoi = ee.Geometry(poly.geometry)

        #print("Farm ",farm_name)

        ee_area = area_calc(poly_aoi,start_dt,end_dt,area_type)

        replies.append(ee_area)
      return json.dumps({'replies': [str(x) for x in ee.List(replies).getInfo()]})

def area_calc(poly_aoi,start_dt,end_dt,area_type):
  
  dw = ee.ImageCollection('GOOGLE/DYNAMICWORLD/V1').filterDate(start_dt, end_dt).filterBounds(poly_aoi)

#Create a Mode Composite.
  classification = dw.select('label')
  dwComposite = classification.reduce(ee.Reducer.mode())

#Extract the Type of Area class.
  myArea = dwComposite.eq(area_type)


# Rename the band names.
  dwComposite = dwComposite.rename(['classification'])
  myArea = myArea.rename(['my_area'])

# Calculate Pixel Counts.

# Count all pixels.
  statsTotal = myArea.reduceRegion(**{
      'reducer': ee.Reducer.count(),
      'geometry': geometry,
      'scale': 10,
      'maxPixels': 1e10
      }); 
  totalPixels = statsTotal.get('my_area')

# Mask 0 pixel values and count remaining pixels.
  myAreaMasked = myArea.selfMask()

  statsMasked = myAreaMasked.reduceRegion(**{
      'reducer': ee.Reducer.count(),
      'geometry': geometry,
      'scale': 10,
      'maxPixels': 1e10
      })
  myAreaPixels = statsMasked.get('my_area')
  fraction = (ee.Number(myAreaPixels).divide(totalPixels)).multiply(100)
  return fraction.format('%.2f')
