view: location_fact {
  sql_table_name: `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_location_fact`
    ;;

  dimension: dept_id {
    type: number
    sql: ${TABLE}.dept_id ;;
  }

  dimension: facility_id {
    type: number
    sql: ${TABLE}.facility_id ;;
  }

  dimension: floor_id {
    type: number
    sql: ${TABLE}.floor_id ;;
  }

  dimension: floor_x_y {
    type: string
    sql: ${TABLE}.floor_x_y ;;
  }

  dimension: location_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.location_id ;;
    map_layer_name: hospital_floor_map_squares
  }

  dimension: status_code_id {
    type: string
    sql: ${TABLE}.status_code_id ;;
  }

  dimension: x {
    type: number
    sql: ${TABLE}.x ;;
  }

  dimension: y {
    type: number
    sql: ${TABLE}.y ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }

  measure: sum_x_y {
    type: number
    sql: sum(${x}) * sum(${y}) * sum(pow(floor_id,2)) ;;
  }
}
