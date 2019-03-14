ruleset wovyn_base {
    meta {
       shares __testing
      
        use module io.picolabs.lesson_keys
        use module io.picolabs.twilio_v2 alias twilio
            with account_sid = keys:twilio{"account_sid"}
                 auth_token  = keys:twilio{"auth_token"}
        use module sensor_profile
        use module io.picolabs.subscription alias subscription
    }
    global{
        from = 17634529729
        __testing = { "events":  [ 
                                    { "domain": "wovyn", 
                                    "type": "new_temperature_reading", 
                                    "attrs": [ 
                                                "temperature",
                                                "timestamp"
                                                ] }
                                      ]
        }        

    }
    rule hearbeat{
        select when wovyn heartbeat
        pre {
                isGenericThing = (event:attr("GenericThing") != "")
                            //if true            grab the temp
                temperature = (isGenericThing) => event:attr("temperature") | null
                //z = (x > y) => y | x
        }
        if isGenericThing then 
            every {
                send_directive("response", {"temperature": temperature})
                send_directive("response", {"isGenericThing":isGenericThing})
            }
            fired {
                now = time:now();
                raise wovyn event "new_temperature_reading"
                    attributes {"temperature": temperature, "timestamp":now}
            }
    }
    rule find_high_temps{
        select when wovyn new_temperature_reading
        foreach subscription:established("Tx_role","manager").klog("the subbbbbbbbbbbbbbbbbb") setting (subscription)
            pre{
                temperature = event:attr("temperature")
                timestamp = event:attr("timestamp")
            }
            if temperature > sensor_profile:get_temp_threshold() then
        //     event:send({"eci":eci, //child eci
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
        
            
                event:send(
                    { "eci": subscription{"Tx"}, 
                      "eid": "hat-lifted",
                      "domain": "send", 
                      "type": "threshold_violation_sms",
                      "attrs":  {
                                  "from": from,
                                  "message": "Warning: GPU temperature is" + temperature + "C: exceeding threshold of" + sensor_profile:get_temp_threshold() + "C"
                              }
                      
                    }, 
                    host=subscription["Tx_host"]
                )
            fired {
              
                // raise wovyn event "threshold_violation"
                //     attributes {"temperature":temperature, "timestamp":timestamp}
            }
        else{
            // nothing here i suppose
        }
    }
    rule threshold_notification{
        select when wovyn threshold_violation
        pre{
            temperature = event:attr("temperature")
            timestamp = event:attr("timestamp")
        }
        every{
            twilio:send_sms(sensor_profile:get_to_number(),
                            from,
                            "WARNING: GPU temperature is " + temperature + "C: exceeding threshold of " + sensor_profile:get_temp_threshold())
            send_directive("WARNING: GPU temperature is " + temperature + "C: exceeding threshold of " +sensor_profile:get_temp_threshold())
        }

    }
}



