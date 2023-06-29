view: room_dim {
  sql_table_name: `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_room_dim`
    ;;

  dimension: exit_floor_x_y {
    type: string
    sql: ${TABLE}.exit_floor_x_y ;;
  }

  dimension: exit_location_id {
    type: number
    sql: ${TABLE}.exit_location_id ;;
  }

  dimension: room_code_id {
    type: string
    sql: ${TABLE}.room_code_id ;;
  }

  dimension: room_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.room_id ;;
    map_layer_name: hospital_floor_map_rooms
  }

  dimension: size {
    type: number
    sql: ${TABLE}.size ;;
  }

  dimension: top_left_floor_x_y {
    type: string
    sql: ${TABLE}.top_left_floor_x_y ;;
  }

  dimension: top_left_location_id {
    type: number
    sql: ${TABLE}.top_left_location_id ;;
  }

  dimension: x_size {
    type: number
    sql: ${TABLE}.x_size ;;
  }

  dimension: y_size {
    type: number
    sql: ${TABLE}.y_size ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }

  measure: avg_size {
    type: average
    sql: ${size} ;;
  }
}
