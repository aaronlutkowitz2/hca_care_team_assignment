# /**************
# Care Team Assignment - Scenario Builder
# Author: Aaron Wilkowitz
# Date: Oct 24, 2022

# https://docs.google.com/spreadsheets/d/1g3yqObc9XUoF7kDkwmhh4eas-Hb056cyDs9yYKD0FwA
# synthetic_data_scenario_nurse_assignments (scenario_nurse_assignments) -- A3:C1000
# synthetic_data_patient_intensity_dim (scenario_nurse_assignments) -- F3:J1000
# **************/

# /**************
# Pre-step
# **************/

# --- Add in declarations

# CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.scenario_0_declarations` AS
# SELECT
#     patient_intensity_desc as key_col
#   , num_visits_hour as value_col
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_patient_intensity_dim`
# WHERE patient_intensity_desc in ('Hourly visits on busy day','Steps per block') ;

# --- For every room, calc distance to every other kind of room (supply closet, medicine, nurse station, elevator)
#   ## To add later: deal with elevators for supply closet on 2nd floor

# CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.scenario_1_min_distance_to_room_types` AS
# with room_distance_info as (
#   SELECT
#       a.start_room_id as room_id
#     , a.end_room_id as other_room_id
#     , c.room_code_desc as other_room_code_desc
#     ## I'm assume each room block is 5 steps
#     , min(coalesce(a.count_steps,0)) * min(d.value_col) as count_steps
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room` a
#   JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_room_dim` b
#     ON a.end_room_id = b.room_id
#   JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_room_code_dim` c
#     ON b.room_code_id = c.room_code_id
#   JOIN `hca-sandbox-aaron-argolis.care_team_assignment.scenario_0_declarations` d
#     ON d.key_col = 'Steps per block'
#   GROUP BY 1,2,3
#   ORDER BY 1,2
# )
# , min_count_steps as (
# SELECT
#     room_id
#   , other_room_code_desc
#   , min(count_steps) as count_steps
# FROM room_distance_info
# WHERE other_room_code_desc <> 'regular room'
# GROUP BY 1,2
# ORDER BY 1,2
# )
# SELECT
#     b.room_id
#   , min(a.other_room_id) as other_room_id
#   , b.other_room_code_desc
#   , b.count_steps
# FROM room_distance_info a
# INNER JOIN min_count_steps b
#   ON a.room_id = b.room_id
#   AND a.other_room_code_desc = b.other_room_code_desc
#   AND a.count_steps = b.count_steps
# GROUP BY 1,3,4
# ;

# --- For every room, calc distance to every other room

# CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.scenario_2_min_distance_to_other_rooms` AS
# SELECT
#     a.start_room_id as room_id
#   , a.end_room_id as other_room_id
#   ## I'm assume each room block is 5 steps
#   , min(coalesce(a.count_steps,0)) * min(b.value_col) as count_steps
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room` a
# JOIN `hca-sandbox-aaron-argolis.care_team_assignment.scenario_0_declarations` b
#   ON b.key_col = 'Steps per block'
# GROUP BY 1,2 ;

# /**************
# A: Calculate moving between rooms
# **************/

# ## Assumptions:
#   # if someone has more visits to a room than all other visits combined, assume all leftover visits came from nursing station
#   # if someone has fewer than 10 visits an hour, assume they go to the nursing station to round them up to 10
#   # if someone has > 10 visits an hour & it's spread evenly, assume they never go to nursing station

# CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.scenario_3_distance_moving_between_rooms` AS
# with by_nurse_total_visits_rooms as (
#   SELECT
#       a.nurse_id
#     , count(distinct a.room_id) as total_rooms
#     , sum(b.num_visits_hour) as total_visits
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_scenario_nurse_assignments` a
#   LEFT JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_patient_intensity_dim` b
#     ON a.patient_intensity_id = b.patient_intensity_id
#   WHERE a.nurse_id is not null
#   GROUP BY 1
# )
# , by_nurse_by_room_how_many_to_add_to_nursing_station_pre as (
#   SELECT
#       a.nurse_id
#     , a.room_id
#     , b.num_visits_hour as number_visits
#     , c.total_visits as total_visits
#     ## Scenario A: there's more visits to 1 single room than all others combined - move those to nursing station
#     , case when (2 * b.num_visits_hour - c.total_visits) < 0 then 0 else (2 * b.num_visits_hour - c.total_visits) end as nursing_station_to_add_a
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_scenario_nurse_assignments` a
#   LEFT JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_patient_intensity_dim` b
#     ON a.patient_intensity_id = b.patient_intensity_id
#   LEFT JOIN by_nurse_total_visits_rooms c
#     ON a.nurse_id = c.nurse_id
# )
# , by_nurse_by_room_how_many_to_add_to_nursing_station as (
#   SELECT
#       a.nurse_id
#     , a.room_id
#     , a.number_visits
#     , a.total_visits
#     , a.nursing_station_to_add_a
#   ## Scenario B: total # visits < 10 - add remaining to nursing station until total visits = 10
#     , case when a.total_visits + a.nursing_station_to_add_a > b.value_col then 0 else b.value_col - (a.total_visits + a.nursing_station_to_add_a) end as nursing_station_to_add_b
#   FROM by_nurse_by_room_how_many_to_add_to_nursing_station_pre a
#   JOIN `hca-sandbox-aaron-argolis.care_team_assignment.scenario_0_declarations` b
#     ON b.key_col = 'Hourly visits on busy day'
# )
# , add_in_nursing_station_visits as (
#   SELECT
#       nurse_id
#     , room_id
#     , 'Room to Room' as travel_type
#     , number_visits
#       ## Take sum of A b/c it's sum of anytime that's true
#       ## Take min of B b/c it'll be same value for all rooms for a nurse
#   FROM by_nurse_by_room_how_many_to_add_to_nursing_station
#   GROUP BY 1,2,3,4

#   UNION ALL

#   SELECT
#       nurse_id
#       ## Set this to nursing station for now
#     , b.other_room_id as room_id
#     , 'Nursing Station' as travel_type
#       ## Take sum of A b/c it's sum of anytime that's true
#       ## Take min of B b/c it'll be same value for all rooms for a nurse
#     , sum(nursing_station_to_add_a) + min(nursing_station_to_add_b) as number_visits
#   FROM by_nurse_by_room_how_many_to_add_to_nursing_station a
#   JOIN `hca-sandbox-aaron-argolis.care_team_assignment.scenario_1_min_distance_to_room_types` b
#     ON a.room_id = b.room_id
#     AND b.other_room_code_desc = 'nursing_station'
#   GROUP BY 1,2,3
# )
# , calc_new_total_visits as (
#   SELECT
#       nurse_id
#     , sum(number_visits) as total_visits
#   FROM add_in_nursing_station_visits
#   GROUP BY 1
# )
# , combine_in_new_total_visits as (
#   SELECT a.*, b.total_visits
#   FROM add_in_nursing_station_visits a
#   JOIN calc_new_total_visits b
#     ON a.nurse_id = b.nurse_id
# )
# , by_nurse_by_room_by_all_other_rooms as (
#   SELECT
#       a.nurse_id
#     , a.room_id
#     , b.room_id as other_room_id
#     , a.travel_type
#     , a.total_visits
#     , b.number_visits
#     , b.number_visits / a.total_visits as percent_visits_pre_normalized
#     , coalesce(min(c.count_steps), min(d.count_steps),0) as count_steps
#   FROM combine_in_new_total_visits a ## main room
#   LEFT JOIN combine_in_new_total_visits b ## other room ID
#     ON a.nurse_id = b.nurse_id
#     AND a.room_id <> b.room_id
#   LEFT JOIN `hca-sandbox-aaron-argolis.care_team_assignment.scenario_1_min_distance_to_room_types` c ## bring in nursing station - this join may be redundant with join d
#     ON a.room_id = c.room_id
#     AND b.room_id = c.other_room_id
#   LEFT JOIN `hca-sandbox-aaron-argolis.care_team_assignment.scenario_2_min_distance_to_other_rooms` d ## bring in all other rooms
#     ON a.room_id = d.room_id
#     AND b.room_id = d.other_room_id
#   ## Avoid double counting I to II and II to I
#   WHERE a.room_id < b.room_id
#   GROUP BY 1,2,3,4,5,6
# )
# , factor_to_normalize as (
#   SELECT
#       nurse_id
#     , sum(percent_visits_pre_normalized) as percent_visits_pre_normalized_sum
#   FROM by_nurse_by_room_by_all_other_rooms
#   GROUP BY 1
# )
# , pre_calc as (
# SELECT
#     a.nurse_id
#   , a.room_id
#   , a.other_room_id
#   , a.travel_type
#   , a.total_visits
#   , a.number_visits
#   , a.percent_visits_pre_normalized
#   , a.percent_visits_pre_normalized * (a.total_visits / b.percent_visits_pre_normalized_sum) as number_visits_normalized
#   , (a.total_visits / b.percent_visits_pre_normalized_sum) as ratio
#   , a.count_steps
# FROM by_nurse_by_room_by_all_other_rooms a
# JOIN factor_to_normalize b
#   ON a.nurse_id = b.nurse_id
# )
# SELECT
#     nurse_id
#   , room_id
#   , other_room_id
#   , travel_type
#   ## Divide by 2 b/c we're double counting I to II and II to I
#   , (number_visits_normalized / 2) as number_visits
#   , count_steps as room_distance
#   ## Divide by 2 b/c we're double counting I to II and II to I
#   , (number_visits_normalized / 2) * count_steps as count_steps
# FROM pre_calc
# ORDER BY 2,3
# ;

# /**************
# B: Calculate med & supply visit times
# **************/

# -- Insert in "med" & "supply closet" into this same table -- using % of times to med & supply chain

# INSERT INTO `hca-sandbox-aaron-argolis.care_team_assignment.scenario_3_distance_moving_between_rooms`
# with num_visits_calc as (
#   SELECT
#       a.nurse_id
#     , a.room_id
#     , a.number_visits * c.perc_meds as number_visits_meds
#     , a.number_visits * c.perc_supply as number_visits_supply
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.scenario_3_distance_moving_between_rooms` a
#   JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_scenario_nurse_assignments` b
#     ON a.room_id = b.room_id
#   JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_patient_intensity_dim` c
#     ON b.patient_intensity_id = c.patient_intensity_id
# )
# , distance_to_calc as (

#   ## Medicine

#   SELECT
#     a.nurse_id
#   , a.room_id
#   , b.other_room_id
#   , 'Medicine' as travel_type
#   ## Halve it b/c I to II and II to I
#   , (a.number_visits_meds / 2) as number_visits
#   ## Multiple by 2 b/c you have to go back & forth
#   , b.count_steps * 2 as room_distance
#   , (a.number_visits_meds / 2) * b.count_steps * 2  as count_steps
#   FROM num_visits_calc a
#   LEFT JOIN `hca-sandbox-aaron-argolis.care_team_assignment.scenario_1_min_distance_to_room_types` b
#     ON a.room_id = b.room_id
#     AND b.other_room_code_desc = 'medicine cabinet'

#   UNION ALL

#   ## Supply

#     SELECT
#     a.nurse_id
#   , a.room_id
#   , b.other_room_id
#   , 'Supply Closet' as travel_type
#   ## Halve it b/c I to II and II to I
#   , (a.number_visits_supply / 2) as number_visits
#   ## Multiple by 2 b/c you have to go back & forth
#   ## Multiply by 16*5 b/c it's 16 paces from elevator to supply closet on 2nd floor so that has to be added in
#   -- , (b.count_steps + 16 * 5) * 2 as room_distance
#   ## For now remove supply closet - just make the elevator the supply closet
#   , (b.count_steps) * 2 as room_distance
#   , (a.number_visits_supply / 2) * (b.count_steps + 16 * 5) * 2  as count_steps
#   FROM num_visits_calc a
#   ### For now join on elevator + hard code walking from elevator to 2nd floor - fix this logic later in the min distance table @ top of script
#   LEFT JOIN `hca-sandbox-aaron-argolis.care_team_assignment.scenario_1_min_distance_to_room_types` b
#     ON a.room_id = b.room_id
#     AND b.other_room_code_desc = 'elevator'

# )
# SELECT *
# FROM distance_to_calc ;

# -- Insert in every nurse, every room with NULL values so that map shows everything (note: this step is just for Looker viz)
# INSERT INTO `hca-sandbox-aaron-argolis.care_team_assignment.scenario_3_distance_moving_between_rooms`
# with every_nurse as (
#   SELECT nurse_id
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.scenario_3_distance_moving_between_rooms`
#   GROUP BY 1
# )
# , every_room as (
#   SELECT room_id
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_room_dim`
#   ## only floor 1
#   WHERE room_id < 200
#   GROUP BY 1
# )
# , every_room_to_every_room as (
#   SELECT
#       a.room_id
#     , b.room_id as other_room_id
#   FROM every_room a
#   LEFT JOIN every_room b
#     ON a.room_id > b.room_id
# )
# SELECT
#     a.nurse_id
#   , b.room_id
#   , b.other_room_id
#   , cast(NULL as string) as travel_type
#   , NULL as number_visits
#   , NULL as room_distance
#   , NULL as count_steps
# FROM every_nurse a
# , every_room_to_every_room b ;

# -- Insert a flipped version of everything at the end, so we can see I to II and II to I
# INSERT INTO `hca-sandbox-aaron-argolis.care_team_assignment.scenario_3_distance_moving_between_rooms`
# SELECT
#     nurse_id
#   , other_room_id as room_id
#   , room_id as other_room_id
#   , travel_type
#   , number_visits
#   , room_distance
#   , count_steps
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.scenario_3_distance_moving_between_rooms` ;
