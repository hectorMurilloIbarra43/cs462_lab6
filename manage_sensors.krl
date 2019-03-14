ruleset manage_sensors{
    meta {
        shares  __testing, // for events
                sensors,
                children_temperatures,
                children_temperatures2
            
            
         use module io.picolabs.wrangler alias Wrangler
         use module io.picolabs.subscription alias subscription
        
    }
    global{
        __testing = { "events":  [ 
                                    { "domain": "sensor", "type": "new_sensor", 
                                      "attrs": [ "sensor_name" ] },
                                    {"domain": "sensor", "type": "unneeded_sensor", 
                                      "attrs": ["sensor_name"] },
                                    {"domain": "sensor", "type": "del_names"}
                                    
                                  ],
                      "queries": [  { "name": "__testing" },
                                    { "name": "sensors" },
                                    {"name": "children_temperatures"},
                                    {"name": "children_temperatures2"}
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
        children_temperatures2 = function(x){
            sensor_subscriptions = subscription:established().filter(function(y){
                y["Tx_role"] == "sensor"
            });
            //sensor_subscriptions.length().klog("the length");
            //sensor_subscriptions[0]["Tx_role"].klog("WHAT IS Tx_role");
            
            sensor_subscriptions.map(function(y){
                something =  http:get("http://localhost:8080/sky/cloud/" + 
                y["Tx"] + "/temperature_store/temperatures")["content"].decode().klog();
                {}.put(y["Tx_role"],something)
            });
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
                                      "sensor_profile",
                                      "io.picolabs.subscription"]
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
        event:send({"eci":eci, //child eci
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
            raise wrangler event "subscription"
                attributes { "name": name,
                                   "Rx_role": "manager",
                                   "Tx_role": "sensor",
                                   "channel_type": "subscription",
                                   "wellKnown_Tx": eci }
                
            
        }
    }
    
    rule clear_sensor_names {
        select when sensor del_names
        
        always{
            clear ent:sensors
        }
    }
    
    rule mischief_who {
        select when mischief who
        pre {
            mischief = event:attr("eci")
            mischief_name = event:attr("name")
            
            le_host = event:attr("host")
            connecting_to = event:attr("connecting_to")
        }
        event:send(
        { "eci": mischief, "eid": "subscription",
            "domain": "wrangler", "type": "subscription",
            "attrs": { "name": "thing" + (index.as("Number")+1),
                      "Rx_role":mischief_name,
                      "Tx_role": "sensor",
                      "channel_type": "subscription",
                      "wellKnown_Tx": connecting_to } }, host = le_host )
        always {
            //ent:mischief := mischief;
            //ent:mischief_name := mischief_name;
        }
    }
    // rule mischief_subscriptions {
    //     select when mischief subscriptions
    //         // introduce mischief pico to thing[index] pico
    //         event:send(
    //             { "eci": ent:mischief, "eid": "subscription",
    //                 "domain": "wrangler", "type": "subscription",
    //                 "attrs": { "name": "thing" + (index.as("Number")+1),
    //                           "Rx_role":ent:mischief_name,
    //                           "Tx_role": "sensor",
    //                           "channel_type": "subscription",
    //                           "wellKnown_Tx": thing } }, host = "" )
    //     }
}






