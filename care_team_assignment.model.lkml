connection: "argolis_asw"

include: "/views/*.view.lkml"                # include all views in the views/ folder in this project
# include: "/map/map_demo_test.topojson"                # include all views in the views/ folder in this project
# include: "/**/*.view.lkml"                 # include all views in this project
# include: "my_dashboard.dashboard.lookml"   # include a LookML dashboard called my_dashboard

explore: location_fact {
  join: status_code_dim {
    relationship: many_to_one
    sql_on: ${location_fact.status_code_id} = ${status_code_dim.status_code_id} ;;
  }
}

explore: room_dim {
  join: room_code_dim {
    relationship: many_to_one
    sql_on: ${room_dim.room_code_id} = ${room_code_dim.room_code_id} ;;
  }

  join: scenario_builder {
    relationship: one_to_many
    sql_on: ${room_dim.room_id} = ${scenario_builder.room_id} ;;
  }

  join: scenario_nurse_assignments {
    relationship: many_to_one
    sql_on:
        ${scenario_builder.room_id} = ${scenario_nurse_assignments.room_id}
    AND ${scenario_builder.nurse_id} = ${scenario_nurse_assignments.nurse_id}
    ;;

  }

  join: scenario_patient_intensity_dim {
    relationship: many_to_one
    sql_on: ${scenario_nurse_assignments.patient_intensity_id} = ${scenario_patient_intensity_dim.patient_intensity_id} ;;
  }


}

map_layer: hospital_floor_map_squares {
  file: "/maps/hospital_floor_map_squares.topojson"
  property_key: "location_id"
}

map_layer: hospital_floor_map_rooms {
  file: "/maps/hospital_floor_map_rooms.topojson"
  property_key: "room_id"
}
