import json
import ee
from datetime import date, datetime, timedelta
import os
import urllib.request
import geojson
import shapely
from google.auth import compute_engine
from shapely import wkt
import math

scopes = ["https://www.googleapis.com/auth/earthengine"]
credentials = compute_engine.Credentials(scopes=scopes)
ee.Initialize(credentials)


def get_fire_polygon(request):

      request_json = request.get_json(silent=True)
      print('Req Json',type(request_json))
      replies = []
      calls = request_json['calls']
      for call in calls:

        start_dt = call[0]
        end_dt = call[1]
        state = call[2]

        fire_polygon = state_fire(start_dt,end_dt,state)
        keys = ['type', 'coordinates']
        bq = {x:fire_polygon[x] for x in keys}
      

        replies.append(bq)
      return json.dumps({'replies': [json.dumps(bq)]})

def state_fire(start_dt,end_dt,state):
  
  admin2 = ee.FeatureCollection("FAO/GAUL_SIMPLIFIED_500m/2015/level2")

  state = admin2.filter(ee.Filter.eq('ADM1_NAME', state))

  state_area = state.geometry()



  dataset = ee.ImageCollection('FIRMS').filter(ee.Filter.date(start_dt, end_dt)).mosaic().clip(state_area)
    
  fires = dataset.select('T21')
  blaze = fires.gte(300)
  blaze = blaze.updateMask(blaze.lt(300));

# get fire regions as vectors
  vectors = blaze.addBands(blaze).reduceToVectors(**{
  'geometry': state_area,
  'scale': 100,
  # crs: current.projection(),
  'labelProperty': 'blaze',
  'geometryType': 'polygon',
  #'eightConnected': 'true',
  'reducer': ee.Reducer.mean(),
  'maxPixels': 1e10
})
  return vectors.geometry().getInfo()

