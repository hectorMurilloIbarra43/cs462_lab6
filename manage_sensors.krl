ruleset manage_sensors{
    meta {
        shares  __testing, // for events
                sensors,
                children_temperatures,
                children_temperatures2,
                children_temperatures3,
                generate_temp_report,
                clear_reports
            
            
         use module io.picolabs.wrangler alias Wrangler
         use module io.picolabs.subscription alias subscription
        
    }
    global{
        __testing = { "events":  [ 
                                    { "domain": "sensor", "type": "new_sensor", 
                                      "attrs": [ "sensor_name" ] },
                                    {"domain": "sensor", "type": "unneeded_sensor", 
                                      "attrs": ["sensor_name"] },
                                    {"domain": "sensor", "type": "del_names"},
                                    {"domain":"manager", "type":"report_needed"},
                                    {"domain":"manager","type":"clear_reports"}
                                    
                                  ],
                      "queries": [  { "name": "__testing" },
                                    { "name": "sensors" },
                                    {"name": "children_temperatures"},
                                    {"name": "children_temperatures2"},
                                    {"name": "children_temperatures3"},
                                    {"name": "generate_temp_report"},                                    
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
            
            sensor_subscriptions.map(function(y){
                something =  http:get("http://localhost:8080/sky/cloud/" + 
                y["Tx"] + "/temperature_store/temperatures")["content"].decode().klog();
                {}.put(y["Tx_role"],something)
            });
        }
        
// a = {"a": 3, "b": 4, "c": 5};
// c = a.filter(function(v,k){v < 5})    // c = {"a": 3, "b": 4}
// d = a.filter(function(v,k){k == "a"}) // d = {"a": 3}        
        children_temperatures3 = function(x){
            total_reports = ent:report.length();
            num_subscriptions = subscription:established().filter(function(y){
                y["Tx_role"] == "sensor"
            }).length();
            report_len = total_reports/num_subscriptions;
            report_len.klog("report_len");
            
            
            temperatures = {};
            ent:report.filter(function(y){
              // y.klog("yyyyyyyyyyyyyyyyy");
              y.filter(function(v,k){
                  k > (report_len - 6);
                  // k.klog("kkkkkkkkkkkkkkkkkk");
                  // v.klog("vvvvvvvvvvvvvvvvv")
                  temperatures.append(v).klog("temperatures")
                  
              }).klog("yyyyyyyyyyyyyy")
              
            });
            
            temperatures = temperatures.put("temperature_sensors",num_subscriptions);
            temperatures = temperatures.put("responding", num_subscriptions);
            temperatures = temperatures.put("temperatures", ent:report.filter(function(y){
                le_keys = y.keys().klog("le keysssssssssssssssssss");
                le_keys[0] > (report_len - 6)
            }));
            temperatures
        }
        
// a = [3, 4, 5];
// c = a.filter(function(x){x<5}) // c = [3, 4]
        generate_temp_report = function(x){
            ent:reports.filter(function(y){
                 y["report_id"]
            })   
        }
        
        generate_all_temps_report = function(x){
            ent:reports.map(function(y)
            {
              // z = (x > y) => y | x
                generate_temp_report(y)
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
            clear ent:sensors;
            //clear ent:report_id
            
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
    
    rule report_needed {
        select when manager report_needed
            foreach subscription:established().filter(function(x){
                                                          x["Tx_role"] == "sensor"
                                                      }) setting (y)
                event:send(
                    {
                        "eci" : y["Tx"],
                        "domain" :"sensor",
                        "type": "generate_report",
                        "attrs": {
                            "report_id": ent:report_id.defaultsTo(0).klog("bob")
                            
                        }
                    }    
                )
                always{
                    ent:report_id := ent:report_id.defaultsTo(0) + 1 on final 
                    
                }
                
                
         
                //             "report_id":ent:report_id.defaultsTo([0]).tail().klg,
                // always{
                //     ent:report_id := ent:report_id.append(ent:report_id.tail()+1) on final 
                
                
    }
    
    rule clear_reports{
        select when manager clear_reports
        always{
            clear ent:report;
            clear ent:report_id;
        }
    }
    //     rule clear_temeratures {
    //     select when sensor reading_reset
      
    //     always{
    //       clear ent:all_violations;
    //       clear ent:all_temps 
          
    //     }
    // }
    
    rule collect_reports {
        select when manager collect_reports
        pre{
            num_responses = subscription:established().filter(function(x){
                                                          x["Tx_role"] == "sensor"
                                                      }).length();
                                                      
            report_id = event:attr("report_id").klog("report id")
            child_report = event:attr("temps").klog("children report")
            report = {}.put(report_id,child_report).klog("incoming report")
            
            // child_temperatures = {}.put(report_id, report)
        }
        always{
            ent:report := ent:report.defaultsTo([]).append(report);
            ent:report.klog("report finished")
            
        }
    }
}






