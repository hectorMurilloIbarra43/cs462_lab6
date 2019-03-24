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
        use module io.picolabs.subscription alias subscription
    }

    global{
          __testing = { "events":  [ 
                                      { "domain": "wovyn", 
                                      "type": "new_temperature_reading", 
                                      "attrs": [ 
                                                  "temperature",
                                                  "timestamp"
                                                  ] },
                                        {"domain":"sensor",
                                          "type":"generate_report",
                                          "attrs":[
                                                "report_id"
                                            ]
                                        }
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
        // event:send({"eci":eci, //child eci
        //             "eid": "whatevs",
        //             "domain": "sensor", 
        //             "type": "profile_updated",
        //             "attrs":  {
        //                           "name" :name,
        //                           "to_number": 7633505859,
        //                           "temp_threshold": temp_threshold,
        //                           "location": "room"
        //                       }
        // })    
        // children_temperatures2 = function(x){
        //     sensor_subscriptions = subscription:established().filter(function(y){
        //         y["Tx_role"] == "sensor"
        //     });
                    
    rule generate_report {
        select when sensor generate_report
            foreach subscription:established().filter(function(x){
                                                  x["Tx_role"] == "manager"
                                              }) setting (y)
                                              
            pre{
                report_id = event:attr("report_id")
            }
            event:send(
                    {
                        "eci" : y["Tx"],
                        "domain" :"manager",
                        "type": "collect_reports",
                        "attrs": {
                            "temps":ent:all_temps.klog("all temps being returnedddddddd"),
                            "report_id":report_id
                        }
                    }    
                )
            always{
            }
                
    }
}





