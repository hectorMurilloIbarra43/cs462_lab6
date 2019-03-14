ruleset temperature_store{
    meta {
        shares __testing, 
        temperatures,
        threshold_violations, 
        inrange_temperatures,
        get_current_temp
      
        provides 
            temperatures,
            threshold_violations, 
            inrange_temperatures,
            get_current_temp
          
        use module sensor_profile            
    }

    global{
          __testing = { "events":  [ 
                                      { "domain": "wovyn", 
                                      "type": "new_temperature_reading", 
                                      "attrs": [ 
                                                  "temperature",
                                                  "timestamp"
                                                  ] }
                                        ],
            
                        "queries": [ { "name": "__testing" },
                                     { "name": "temperatures" },
                                     { "name": "threshold_violations" },
                                     {"name":"inrange_temperatures"},
                                     {"name":"get_current_temp"}
                                    ]
          }
          
        get_current_temp = function(){
          ent:all_temps[ent:all_temps.length()-1]["temp"]
        }
        
        temperatures = function(){
            ent:all_temps
        };
        threshold_violations = function(){
            ent:all_violations;
            //c = a.filter(function(x){x<5})
            ent:all_temps.filter(function(x){x["temp"] > sensor_profile:get_temp_threshold()})
            
        }
        
        inrange_temperatures = function(){
          // difference (A/B). The set of all members of A that are not members of B
            //ent:all_temps.difference(ent:all_violations)
             ent:all_temps.filter(function(x){x["temp"] <= sensor_profile:get_temp_threshold()})
            
        }
        
    }

    rule collect_temperatures{
        select when wovyn new_temperature_reading
        pre{
            timestamp = event:attr("timestamp")
            temp = event:attr("temperature")
        }
        
        always{
            ent:all_temps := ent:all_temps.defaultsTo([]).append([{"temp":temp,"timestamp":timestamp}]);
        }
    }
    
    rule collect_threshold_violations{
      select when wovyn threshold_violation
      pre{
            timestamp = event:attr("timestamp")
            temp = event:attr("temperature")
        }
        always{
           ent:all_violations := ent:all_violations.defaultsTo([]).append([{"temp":temp,"timestamp":timestamp}]);
        }
    }
    
    rule clear_temeratures {
        select when sensor reading_reset
      
        always{
          clear ent:all_violations;
          clear ent:all_temps 
          
        }
    }
}



