view: scenario_nurse_assignments {
  sql_table_name: `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_scenario_nurse_assignments`
    ;;

  dimension: pk {
    primary_key: yes
    type: string
    sql: ${room_id} || '|' || ${nurse_id} ;;
  }

  dimension: nurse_id {
    type: string
    sql: ${TABLE}.nurse_id ;;
  }

  dimension: patient_intensity_id {
    type: number
    sql: ${TABLE}.patient_intensity_id ;;
  }

  dimension: room_id {
    type: number
    sql: ${TABLE}.room_id ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }
}
