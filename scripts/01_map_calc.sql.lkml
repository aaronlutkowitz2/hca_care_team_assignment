# /**************
# Care Team Assignment - Map Calculator
# Author: Aaron Wilkowitz
# Date: Oct 24, 2022

# https://docs.google.com/spreadsheets/d/1g3yqObc9XUoF7kDkwmhh4eas-Hb056cyDs9yYKD0FwA
# synthetic_data_fact_location_fact (data_location_fact)
# synthetic_data_status_code_dim (data_status_code_dim)
# synthetic_data_room_dim (data_room_dim) -- A1:I1000
# synthetic_data_room_code_dim (data_room_code_dim)
# synthetic_data_scenario_nurse_assignments (scenario_nurse_assignments) -- A3:C1000
# synthetic_data_patient_intensity_dim (scenario_nurse_assignments) -- F3:J1000
# **************/

# /**************
# 0. Pre-steps
# **************/

# -- Declare variables - Loop A

# DECLARE run_name STRING DEFAULT 'map_algo_' || current_timestamp() ;
# DECLARE loop_counter_a INT64 default 0 ;
# DECLARE max_counter_a INT64 default (SELECT count(*) FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_room_dim`) ;

# -- Declare variables - Loop B

# DECLARE loop_counter_b INT64 default 0 ;

# -- Change roomIDs to row_num so counter = row_num

# CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_1_room_dim_as_row_num` AS
# SELECT
#   row_number() over (order by room_id) as row_num
#   , *
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_room_dim` ;

# -- 1 time -- Create the Loop A table to insert into, then clear table

# /*
#   CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room` AS
#   SELECT
#       'x' as run_name
#     , 1 as start_room_id
#     , 1 as end_room_id
#     , current_timestamp() as inserted_timestamp
#     , 1 as count_steps ;

#   DELETE FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room` WHERE TRUE ;
# */

# -- To add later: double check that all exit locations are in fact

# /**************
# A. Loop A - start with a room
# **************/

# -- Start loop A

# LOOP

# -- Add 1 to counter A

#   SET loop_counter_a = loop_counter_a + 1;
#   IF loop_counter_a > max_counter_a
#     THEN LEAVE;
#   END IF;

# -- Set room row_num = loop counter A

#   CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_2_loop_a_room` AS
#   SELECT *
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_1_room_dim_as_row_num`
#   WHERE row_num = loop_counter_a ;

# /**************
# B. Loop B - move one space until all rooms have been identified
# **************/

# -- Start at the starting point for the room as 0 steps

#   CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_3_loop_b_steps` AS
#   SELECT
#       room_id
#     , exit_location_id as location_id
#     , floor_id
#     , x
#     , y
#     , 0 as count_steps
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_2_loop_a_room` a
#   LEFT JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_location_fact` b
#     ON a.exit_location_id = b.location_id ;

#   SET loop_counter_b = 1 ;

# -- Start loop B

#   REPEAT

# -- Move 1 step up, down, left, right
#   -- If a step is not possible, remove it
#   -- If step is possible, record each as loop_counter_b

#     INSERT INTO `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_3_loop_b_steps`
#     with pre_work as (
#       SELECT *
#       FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_3_loop_b_steps`
#       WHERE count_steps = loop_counter_b - 1
#     )
#     , step_1_up as (
#       SELECT room_id, floor_id, x as x, y-1 as y
#       FROM pre_work
#     )
#     , step_1_down as (
#       SELECT room_id, floor_id, x as x, y+1 as y
#       FROM pre_work
#     )
#     , step_1_left as (
#       SELECT room_id, floor_id, x-1 as x, y as y
#       FROM pre_work
#     )
#     , step_1_right as (
#       SELECT room_id, floor_id, x+1 as x, y as y
#       FROM pre_work
#     )
#     , steps_combined as (
#                 SELECT * FROM step_1_up
#       UNION ALL SELECT * FROM step_1_down
#       UNION ALL SELECT * FROM step_1_left
#       UNION ALL SELECT * FROM step_1_right
#     )
#     -- Switch to location ID
#     -- Remove not walkable
#     -- Use loop as count_steps
#     SELECT
#         a.room_id
#       , b.location_id
#       , a.floor_id
#       , a.x
#       , a.y
#       , loop_counter_b as count_steps
#     FROM steps_combined a
#     LEFT JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_location_fact` b
#       ON a.floor_id = b.floor_id
#       AND a.x = b.x
#       AND a.y = b.y
#     LEFT JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_status_code_dim` c
#       ON b.status_code_id = c.status_code_id
#     WHERE is_walkable
#     GROUP BY 1,2,3,4,5,6 ;

# -- Check if all rooms on the floor have been found
#   -- If yes, stop
#   -- If no, run the loop again

#     CREATE OR REPLACE TABLE `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_4_loop_b_unfound_room_count` AS
#     -- Only consider rooms on same floor
#     with floor_id_to_use as (
#       SELECT floor_id
#       FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_3_loop_b_steps`
#       GROUP BY 1
#     )
#     -- Only need to figure out distance from I to II, not II to I, so only consider rooms whose IDs are greater than the current room (saves time on loops)
#     , room_id_to_use as (
#       SELECT room_id
#       FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_room_dim`
#       WHERE room_id > (SELECT room_id FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_3_loop_b_steps` GROUP BY 1)
#       GROUP BY 1
#     )
#     , distinct_rooms_to_use as (
#       SELECT a.exit_location_id, a.room_id
#       FROM `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_room_dim` a
#       INNER JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_location_fact` b
#         ON a.exit_location_id = b.location_id
#       INNER JOIN floor_id_to_use c
#         ON b.floor_id = c.floor_id
#       INNER JOIN room_id_to_use d
#         ON a.room_id = d.room_id
#       GROUP BY 1,2
#     )
#     , distinct_loops_found as (
#       SELECT location_id
#       FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_3_loop_b_steps`
#       GROUP BY 1
#     )
#     SELECT * -- count(distinct a.exit_location_id) as count_unfound_rooms
#     FROM distinct_rooms_to_use a
#     LEFT JOIN distinct_loops_found e
#       ON a.exit_location_id = e.location_id
#     WHERE e.location_id is null ;

#   SET loop_counter_b = loop_counter_b + 1;
#   UNTIL (SELECT count(*) FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_4_loop_b_unfound_room_count`) = 0

# -- End loop B

#   END REPEAT ;

# -- Insert B into historical statement, where only min path is kept

#   INSERT INTO `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room`
#   SELECT
#       run_name
#     , a.room_id as start_room_id
#     , b.room_id as end_room_id
#     , current_timestamp() as inserted_timestamp
#     , min(a.count_steps) as count_steps
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_3_loop_b_steps` a
#   INNER JOIN `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_room_dim` b
#     ON a.location_id = b.exit_location_id
#   -- Add this where clause to ensure we're not double counting II to Is
#   WHERE a.room_id < b.room_id
#   GROUP BY 1,2,3,4 ;

# -- End loop A

# END LOOP;

# -- After all loops have run, insert the reserve of every I to II to account for II to I

# INSERT INTO `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room`
# SELECT
#     run_name
#   , end_room_id as start_room_id
#   , start_room_id as end_room_id
#   , count_steps
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room`
# WHERE a.run_name = run_name ;

# SELECT
#     start_room_id
#   , end_room_id
#   , count_steps
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room`
# ORDER BY run_name, start_room_id, end_room_id, count_steps
# LIMIT 1000
