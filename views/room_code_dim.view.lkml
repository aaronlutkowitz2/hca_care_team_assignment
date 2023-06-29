view: room_code_dim {
  sql_table_name: `hca-sandbox-aaron-argolis.care_team_assignment.synthetic_data_room_code_dim`
    ;;

  dimension: room_code_desc {
    type: string
    ## temporary just call elevator the supply closet
    sql: case when ${TABLE}.room_code_desc = 'elevator' then 'supply closet' else ${TABLE}.room_code_desc end ;;
  }

  dimension: room_code_id {
    type: string
    sql: ${TABLE}.room_code_id ;;
  }

  dimension: row_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.row_id ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }

  measure: avg_row_id {
    type: average
    sql: ${row_id} ;;
  }
}
