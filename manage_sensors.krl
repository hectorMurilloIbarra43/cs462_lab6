ruleset manage_sensors{
    meta {
        shares  __testing, // for events
                sensors,
                children_temperatures
            
            
         use module io.picolabs.wrangler alias Wrangler
        
    }
    global{
        __testing = { "events":  [ 
                                    { "domain": "sensor", "type": "new_sensor", "attrs": [ "sensor_name" ] },
                                    {"domain": "sensor", "type": "unneeded_sensor", "attrs": ["sensor_name"] },
                                    {"domain": "sensor", "type": "del_names"}
                                    
                                  ],
                      "queries": [  { "name": "__testing" },
                                    { "name": "sensors" },
                                    {"name": "children_temperatures"}
                                  ]
        }
        temp_threshold = 90
        
        
         sensors = function(){
            ent:sensors.defaultsTo({})
        }
                
        // a = [3, 4, 5];
        // c = a.map(function(x) {x+2}) // c = [5, 6, 7]              
// rule r2 {
  // select when web pageview url re#/archives/#
  // http:post("https://example.com/printenv.pl",
  //   body =
  //               << <?xml encoding='UTF-8'?>
  //                 <feed version='0.3'>
  //                 </feed> >>,
  //   headers = {"content-type": "application/xml"});
// }
        children_temperatures = function(x){
            Wrangler:children().map(function(y){ 
                something = http:get("http://localhost:8080/sky/cloud/" + 
                    y["eci"]+ "/temperature_store/temperatures")["content"].decode().klog();
                    {}.put(y{"name"}, something)
            })
        }
    }
    
    rule create_sensor {
        select when sensor new_sensor
        pre {
            sensor_name = event:attr("sensor_name");
            sensor_eci = meta:eci
            exists = ent:sensors >< sensor_name
        }
        if exists then
            send_directive("sensor_ready", {"sensor_name":sensor_name})
        notfired{
            //new_child = {sensor_name:""};
            ent:sensors := ent:sensors.defaultsTo({}).put(sensor_name,"");
            raise wrangler event "child_creation"
                attributes {"name":sensor_name, 
                            "color":"#ffff00",
                            "rids": ["temperature_store",
                                      "wovyn_base",
                                      "sensor_profile"]
                }
        }
    }   
    
    rule del_sensor {
        select when sensor unneeded_sensor
        pre{
            sensor_name = event:attr("sensor_name");
            exists = ent:sensors >< sensor_name
        }
        if exists then
            send_directive("sensor_deleted", {"sensor_name":sensor_name})
        fired{
            ent:sensors := ent:sensors.delete(sensor_name);
            raise wrangler event "child_deletion"
                attributes {"name":sensor_name}
        }
    }
    
    rule child_initalized_listener {
        select when wrangler child_initialized
        pre{
            name = event:attr("name").klog();
            eci = event:attr("eci").klog();
        }
        event:send({"eci":eci, 
                    "eid": "whatevs",
                    "domain": "sensor", 
                    "type": "profile_updated",
                    "attrs":  {
                                  "name" :name,
                                  "to_number": 7633505859,
                                  "temp_threshold": temp_threshold,
                                  "location": "room"
                              }
        })
        
        always{
            ent:sensors := ent:sensors.set([name],eci);
        }
    }
    
    rule clear_sensor_names {
        select when sensor del_names
        
        always{
            clear ent:sensors
        }
    }
}







