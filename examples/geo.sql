SELECT * from `gee.land_coords

-- Ag
SELECT
    name,
    gee.get_poly_ndvi_month(aoi,2021,7) AS ndvi_jul,
    gee.get_poly_temp_month(aoi,2021,7) AS temperature,
    gee.get_poly_crop(aoi,2021) AS crop
  FROM
    `gee.land_coords`;
    
 
--Wildfire 
 select st_geogfromgeojson(
gee.get_fire_polygon_state('2022-09-01','2022-09-14','California'),make_valid =>TRUE)
as fire_state;  
