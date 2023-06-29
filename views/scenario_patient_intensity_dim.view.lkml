view: scenario_patient_intensity_dim {
  sql_table_name: `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_patient_intensity_dim`
    ;;

  dimension: num_visits_hour {
    type: number
    sql: ${TABLE}.num_visits_hour ;;
  }

  dimension: patient_intensity_desc {
    type: string
    sql: ${TABLE}.patient_intensity_desc ;;
  }

  dimension: patient_intensity_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.patient_intensity_id ;;
  }

  dimension: perc_meds {
    type: number
    sql: ${TABLE}.perc_meds ;;
  }

  dimension: perc_supply {
    type: number
    sql: ${TABLE}.perc_supply ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }
}
