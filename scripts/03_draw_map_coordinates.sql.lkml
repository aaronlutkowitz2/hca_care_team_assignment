# /**************
# Care Team Assignment - Generate GeoJSON File
# Author: Aaron Wilkowitz
# Date: Oct 25, 2022

# https://geojson.io/#map=2.44/-33.03/77.03
# https://cloud.google.com/looker/docs/best-practices/how-to-create-custom-map-regions
# **************/

# /**************
# 0. Pre-steps
# **************/

# -- Declare the 4 corners of your map (note: this assumes north long > south long & east_lat > west_lat)

# DECLARE north_long_col FLOAT64 DEFAULT -14.0 ;
# DECLARE south_long_col FLOAT64 DEFAULT -39.0 ;
# DECLARE east_lat_col FLOAT64 DEFAULT 100 ;
# DECLARE west_lat_col FLOAT64 DEFAULT 85 ;

# -- Declare the # squares of X & Y (they don't have to be equal)

# DECLARE x_axis_col INT64 DEFAULT 25 ; ## 2 floors - 12 x-axis + 1 break + 12 x-axis
# DECLARE y_axis_col INT64 DEFAULT 12 ;

# -- Put into a table

# CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_1_set_variables` AS
# SELECT
#   north_long_col as north_long
# , south_long_col as south_long
# , east_lat_col as east_lat
# , west_lat_col as west_lat
# , x_axis_col as x_axis
# , y_axis_col as y_axis
# ;

# -- Calc size of all squares, normalize to smaller of two

# CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_2_axis_length` AS
# with original_lengths as (
#   SELECT
#       (east_lat - west_lat) / x_axis as x_axis_length
#     , (north_long - south_long) / y_axis as y_axis_length
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_1_set_variables`
# )
# SELECT round(case when x_axis_length < y_axis_length then x_axis_length else y_axis_length end,2) as axis_length
# FROM original_lengths
# ;

# /**************
# A. Set coordinates
# **************/

# #### Process 1 -- For all squares

# -- Calc top_left, top_right, bottom_left, bottom_right coordinates of every square

# CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_3_coordinates` AS
# -- Move floor 2 13 spaces to the right
# with updated_x_y_based_on_floor as (
#   SELECT
#       * except (x,y)
#     , case when floor_id = 2 then x + 15 else x end as x
#     , y
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_location_fact`
# )
# SELECT
#     a.location_id
#   , west_lat + round(((x-1) * axis_length)   + 0.05,6) as top_left_lat
#   , north_long - round(((y-1) * axis_length) + 0.05,6) as top_left_long
#   , west_lat + round(((x) * axis_length)     - 0.05,6) as top_right_lat
#   , north_long - round(((y-1) * axis_length) + 0.05,6) as top_right_long
#   , west_lat + round(((x-1) * axis_length)   + 0.05,6) as bottom_left_lat
#   , north_long - round(((y) * axis_length)   - 0.05,6) as bottom_left_long
#   , west_lat + round(((x) * axis_length)     - 0.05,6) as bottom_right_lat
#   , north_long - round(((y) * axis_length)   - 0.05,6) as bottom_right_long
# FROM updated_x_y_based_on_floor a
# , `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_2_axis_length` b
# , `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_1_set_variables` c
# -- WHERE x in (1,2,14)
# -- AND y < 2
# ORDER BY 1
# ;

# #### Process 2 -- For all rooms

# -- Calc top_left, top_right, bottom_left, bottom_right coordinates of every room

# CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_3b_coordinates_rooms` AS
# with pre_table as (
#   SELECT
#     a.room_id
#   , a.x_size
#   , a.y_size
#   , b.floor_id
#   , b.x
#   , b.y
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_room_dim` a
# LEFT JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_location_fact` b
#   ON a.top_left_location_id = b.location_id
# GROUP BY 1,2,3,4,5,6
# )
# , top_left as (
#   SELECT
#       room_id
#     , floor_id
#     , x as x
#     , y as y
#   FROM pre_table
# )
# , top_left_location as (
#   SELECT
#       b.room_id
#     , a.location_id
#     , c.top_left_lat
#     , c.top_left_long
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_location_fact` a
#   JOIN top_left b
#     ON a.floor_id = b.floor_id
#     AND a.x = b.x
#     AND a.y = b.y
#   JOIN `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_3_coordinates` c
#     ON a.location_id = c.location_id
#   GROUP BY 1,2,3,4
# )
# , top_right as (
#   SELECT
#       room_id
#     , floor_id
#     , x + x_size - 1 as x
#     , y as y
#   FROM pre_table
# )
# , top_right_location as (
#   SELECT
#       b.room_id
#     , a.location_id
#     , c.top_right_lat
#     , c.top_right_long
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_location_fact` a
#   JOIN top_right b
#     ON a.floor_id = b.floor_id
#     AND a.x = b.x
#     AND a.y = b.y
#   JOIN `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_3_coordinates` c
#     ON a.location_id = c.location_id
#   GROUP BY 1,2,3,4
# )
# , bottom_left as (
#   SELECT
#       room_id
#     , floor_id
#     , x as x
#     , y + y_size - 1 as y
#   FROM pre_table
# )
# , bottom_left_location as (
#   SELECT
#       b.room_id
#     , a.location_id
#     , c.bottom_left_lat
#     , c.bottom_left_long
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_location_fact` a
#   JOIN bottom_left b
#     ON a.floor_id = b.floor_id
#     AND a.x = b.x
#     AND a.y = b.y
#   JOIN `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_3_coordinates` c
#     ON a.location_id = c.location_id
#   GROUP BY 1,2,3,4
# )
# , bottom_right as (
#   SELECT
#       room_id
#     , floor_id
#     , x + x_size - 1 as x
#     , y + y_size - 1 as y
#   FROM pre_table
# )
# , bottom_right_location as (
#   SELECT
#       b.room_id
#     , a.location_id
#     , c.bottom_right_lat
#     , c.bottom_right_long
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_location_fact` a
#   JOIN bottom_right b
#     ON a.floor_id = b.floor_id
#     AND a.x = b.x
#     AND a.y = b.y
#   JOIN `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_3_coordinates` c
#     ON a.location_id = c.location_id
#   GROUP BY 1,2,3,4
# )
# SELECT
#     a.room_id
#   , a.top_left_lat
#   , a.top_left_long
#   , b.top_right_lat
#   , b.top_right_long
#   , c.bottom_left_lat
#   , c.bottom_left_long
#   , d.bottom_right_lat
#   , d.bottom_right_long
# FROM top_left_location a
# LEFT JOIN top_right_location b
#   ON a.room_id = b.room_id
# LEFT JOIN bottom_left_location c
#   ON a.room_id = c.room_id
# LEFT JOIN bottom_right_location d
#   ON a.room_id = d.room_id
# ;

# /**************
# B. Create json output
# Note: I copied it from format of https://geojson.io/#map=4.5/0.14/-111.6
# **************/

# #### Process 1 -- For all squares

# CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_4_json_output` AS
# with pre_text as (
# SELECT
#     location_id
#   , '{"type":"Feature","properties":{"location_id":"'
#     || location_id
#     || '"},"geometry":{"coordinates":[[['
#     || top_left_lat
#     || ','
#     || top_left_long
#     || '],['
#     || top_right_lat
#     || ','
#     || top_right_long
#     || '],['
#     || bottom_right_lat
#     || ','
#     || bottom_right_long
#     || '],['
#     || bottom_left_lat
#     || ','
#     || bottom_left_long
#     || '],['
#     || top_left_lat
#     || ','
#     || top_left_long
#     || ']]],"type":"Polygon"}}'
#     as text_middle
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_3_coordinates`
# )
# SELECT
#   '{"type":"FeatureCollection","features":[' || STRING_AGG(text_middle ORDER BY location_id) || "]}" AS text
# FROM pre_text
# ;

# #### Process 2 -- For all rooms

# CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_4b_json_output_rooms` AS
# with pre_text as (
# SELECT
#     room_id
#   , '{"type":"Feature","properties":{"room_id":"'
#     || room_id
#     || '"},"geometry":{"coordinates":[[['
#     || top_left_lat
#     || ','
#     || top_left_long
#     || '],['
#     || top_right_lat
#     || ','
#     || top_right_long
#     || '],['
#     || bottom_right_lat
#     || ','
#     || bottom_right_long
#     || '],['
#     || bottom_left_lat
#     || ','
#     || bottom_left_long
#     || '],['
#     || top_left_lat
#     || ','
#     || top_left_long
#     || ']]],"type":"Polygon"}}'
#     as text_middle
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_3b_coordinates_rooms`
# )
# SELECT
#   '{"type":"FeatureCollection","features":[' || STRING_AGG(text_middle ORDER BY room_id) || "]}" AS text
# FROM pre_text
# ;

# /**************
# C. Insert into Looker
# **************/

# ## Step 1: Copy this text -- one at a time

# /*
# ## Square based

# SELECT *
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_4_json_output`

# ## Room based

# SELECT *
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_drawing_4b_json_output_rooms`
# */

# ## Step 2: Paste into here: https://geojson.io/#map=4.5/0.14/-111.6

# ## Step 3: Download as TopoJSON

# ## Step 4: Load map file into Looker
