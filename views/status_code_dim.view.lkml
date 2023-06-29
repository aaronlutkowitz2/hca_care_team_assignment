view: status_code_dim {
  sql_table_name: `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_status_code_dim`
    ;;

  dimension: is_walkable {
    type: yesno
    sql: ${TABLE}.is_walkable ;;
  }

  dimension: row_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.row_id ;;
  }

  dimension: status_code_desc {
    type: string
    sql: ${TABLE}.status_code_desc ;;
  }

  dimension: status_code_id {
    type: string
    sql: ${TABLE}.status_code_id ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }

  measure: count_walkable {
    type: count
    filters: [is_walkable: "Yes"]
  }
}
