view: scenario_builder {
  sql_table_name: `hca-sandbox-aaron-argolis.care_team_assignment.scenario_3_distance_moving_between_rooms`
    ;;

  dimension: pk {
    primary_key: yes
    type: string
    sql: ${nurse_id} || '|' || ${room_id} || '|' || ${other_room_id} ;;
  }

  dimension: count_steps {
    type: number
    sql: ${TABLE}.count_steps ;;
  }

  dimension: number_visits {
    type: number
    sql: ${TABLE}.number_visits ;;
  }

  dimension: nurse_id {
    type: string
    sql: ${TABLE}.nurse_id ;;
  }

  dimension: other_room_id {
    type: number
    sql: ${TABLE}.other_room_id ;;
  }

  dimension: room_distance {
    type: number
    sql: ${TABLE}.room_distance ;;
  }

  dimension: room_id {
    type: number
    sql: ${TABLE}.room_id ;;
  }

  dimension: travel_type {
    type: string
    sql: ${TABLE}.travel_type ;;
  }

  dimension: nurse_id_string {
    label: "Nurse Name"
    type: string
    sql: 'Nurse ' || ${nurse_id} ;;
  }

  dimension: travel_type_string {
    type: string
    sql:
      CASE
        WHEN ${travel_type} = 'Room to Room' then '1 - Room to Room'
        WHEN ${travel_type} = 'Medicine' then '2 - Medicine'
        WHEN ${travel_type} = 'Supply Closet' then '3 - Supply Closet'
        ELSE 'Unknown'
      END
    ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }

  measure: total_steps {
    type: sum
    sql: ${count_steps} ;;
    value_format_name: decimal_1
  }

  measure: average_room_distance {
    type: average
    sql: ${room_distance} ;;
    value_format_name: decimal_1
  }

  measure: total_visits {
    type: sum
    sql: ${number_visits} ;;
    value_format_name: decimal_1
  }
}
