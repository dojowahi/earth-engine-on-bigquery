import json
import ee
from datetime import date, datetime, timedelta
import os
import urllib.request
import geojson
import shapely
from shapely import wkt
from google.auth import compute_engine

scopes = ["https://www.googleapis.com/auth/earthengine"]
credentials = compute_engine.Credentials(scopes=scopes)
ee.Initialize(credentials)

def get_crop(request):

      crop_dict = {
      1:'Corn',
      2:'Cotton',
      3:'Rice',
      4:'Sorghum',
      5:'Soybeans',
      6:'Sunflower',
      10:'Peanuts',
      11:'Tobacco',
      12:'Sweet Corn',
      13:'Pop or Orn Corn',
      14:'Mint',
      21:'Barley',
      22:'Durum Wheat',
      23:'Spring Wheat',
      24:'Winter Wheat',
      25:'Other Small Grains',
      26:'Dbl Crop WinWht/Soybeans',
      27:'Rye',
      28:'Oats',
      29:'Millet',
      30:'Speltz',
      31:'Canola',
      32:'Flaxseed',
      33:'Safflower',
      34:'Rape Seed',
      35:'Mustard',
      36:'Alfalfa',
      38:'Camelina',
      39:'Buckwheat',
      41:'Sugarbeets',
      42:'Dry Beans',
      43:'Potatoes',
      44:'Other Crops',
      45:'Sugarcane',
      46:'Sweet Potatoes',
      47:'Misc Vegs & Fruits',
      48:'Watermelons',
      49:'Onions',
      50:'Cucumbers',
      51:'Chick Peas',
      52:'Lentils',
      53:'Peas',
      54:'Tomatoes',
      55:'Caneberries',
      56:'Hops',
      57:'Herbs',
      58:'Clover/Wildflowers',
      61:'Fallow/Idle Cropland',
      66:'Cherries',
      67:'Peaches',
      68:'Apples',
      69:'Grapes',
      70:'Christmas Trees',
      71:'Other Tree Crops',
      72:'Citrus',
      74:'Pecans',
      75:'Almonds',
      76:'Walnuts',
      77:'Pears',
      204:'Pistachios',
      205:'Triticale',
      206:'Carrots',
      207:'Asparagus',
      208:'Garlic',
      209:'Cantaloupes',
      210:'Prunes',
      211:'Olives',
      212:'Oranges',
      213:'Honeydew Melons',
      214:'Broccoli',
      215:'Avocado',
      216:'Peppers',
      217:'Pomegranates',
      218:'Nectarines',
      219:'Greens',
      220:'Plums',
      221:'Strawberries',
      222:'Squash',
      223:'Apricots',
      224:'Vetch',
      225:'Dbl Crop WinWht/Corn',
      226:'Dbl Crop Oats/Corn',
      227:'Lettuce',
      228:'Dbl Crop Triticale/Corn',
      229:'Pumpkins',
      230:'Dbl Crop Lettuce/Durum Wht',
      231:'Dbl Crop Lettuce/Cantaloupe',
      232:'Dbl Crop Lettuce/Cotton',
      233:'Dbl Crop Lettuce/Barley',
      234:'Dbl Crop Durum Wht/Sorghum',
      235:'Dbl Crop Barley/Sorghum',
      236:'Dbl Crop WinWht/Sorghum',
      237:'Dbl Crop Barley/Corn',
      238:'Dbl Crop WinWht/Cotton',
      239:'Dbl Crop Soybeans/Cotton',
      240:'Dbl Crop Soybeans/Oats',
      241:'Dbl Crop Corn/Soybeans',
      242:'Blueberries',
      243:'Cabbage',
      244:'Cauliflower',
      245:'Celery',
      246:'Radishes',
      247:'Turnips',
      248:'Eggplants',
      249:'Gourds',
      250:'Cranberries',
      254:'Dbl Crop Barley/Soybeans',
      37:'Other Hay/Non Alfalfa',
      59:'Sod/Grass Seed',
      60:'Switchgrass',
      63:'Forest',
      64:'Shrubland',
      65:'Barren',
      81:'Clouds/No Data',
      82:'Developed',
      83:'Water',
      87:'Wetlands',
      88:'Nonag/Undefined',
      92:'Aquaculture',
      111:'Open Water',
      112:'Perennial Ice/Snow',
      121:'Developed/Open Space',
      122:'Developed/Low Intensity',
      123:'Developed/Med Intensity',
      124:'Developed/High Intensity',
      131:'Barren',
      141:'Deciduous Forest',
      142:'Evergreen Forest',
      143:'Mixed Forest',
      152:'Shrubland',
      176:'Grass/Pasture',
      190:'Woody Wetlands',
      195:'Herbaceous Wetlands'
      }
     
      request_json = request.get_json(silent=True)
      print('Req Json',type(request_json))
      replies = []
      calls = request_json['calls']
      for call in calls:

        farm_json_str = call[0]
        farm_year = call[1]
        farm_json = shapely.wkt.loads(farm_json_str)
        farm_poly = geojson.Feature(geometry=farm_json, properties={})
        farm_aoi = ee.Geometry(farm_poly.geometry)
        farm_centroid = farm_aoi.centroid()

        #print("Farm ",farm_name)
        
        ee_crop = farm_crop_calc(farm_centroid,farm_year)

        replies.append(ee_crop)
      return json.dumps({'replies':[crop_dict.get(x,str(x)) for x in ee.List(replies).getInfo()]})

        

def farm_crop_calc(farm_centroid,year):
  
  startDate = str(year)+'-'+'01'+'-'+'01'
  endDate = str(year)+'-'+'12'+'-'+'31'
  usda = ee.ImageCollection("USDA/NASS/CDL")
  crop_county = usda.filter(ee.Filter.date(startDate, endDate)).first()
  #farm_poi = ee.Geometry.Point(poi)
  
  cropType = crop_county.reduceRegion(**{
            'reducer': ee.Reducer.first(),
            'geometry': farm_centroid,
            'scale': 30
          }).get('cropland')
  # print(cropType.getInfo())

  return cropType
