# ### Check on loop B - # of steps taken on any individual room

# SELECT room_id, count(*) as count, max(count_steps) as num_steps, count(distinct location_id) as num_location
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_3_loop_b_steps`
# GROUP BY 1 ;

# ### Check on loop B never finding a room

# SELECT *
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_4_loop_b_unfound_room_count` ;

# ### Check on looped runs

# with max_run_id as (
#   SELECT max(run_name) as run_name
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room`
# )
# , time_to_run as (
#   SELECT
#     run_name
#     , round(TIMESTAMP_DIFF(max(inserted_timestamp), min(inserted_timestamp), second) / 60,1) as time_to_run
#     , count(distinct start_room_id) as total_rooms
#   FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room`
#   GROUP BY 1
# )
# SELECT
#     start_room_id
#   , count(distinct end_room_id) as count_rooms
#   , min(count_steps) as min_steps
#   , round(avg(count_steps),1) as avg_steps
#   , max(count_steps) as max_steps
#   , avg(time_to_run) as total_time_to_run
#   , avg(time_to_run) / avg(total_rooms) as avg_loop_time
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room` a
# JOIN max_run_id b
#   ON a.run_name = b.run_name
# JOIN time_to_run c
#   ON a.run_name = c.run_name
# GROUP BY 1
# ORDER BY 1
# LIMIT 100 ;

# ### Other validations

# SELECT x, y, count_steps
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_3_loop_b_steps`
# WHERE x in (9,10)
# GROUP BY 1,2,3
# ORDER BY 1,2,3 ;

# SELECT distinct x,y
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_3_loop_b_steps`
# WHERE count_steps = 19
# ORDER BY x,y ;

# SELECT start_room_id, min(inserted_timestamp), max(inserted_timestamp)
# FROM `hca-sandbox-aaron-argolis.care_team_assignment.map_algo_5_loop_a_distance_to_each_room`
# GROUP BY 1
# ORDER BY 2
