ruleset sensor_profile {
    meta {
      shares __testing, 
          get_location, 
          get_name, 
          get_temp_threshold, 
          get_to_number
        
        provides 
            get_location, 
            get_name, 
            get_temp_threshold, 
            get_to_number
            
    }
    global{
          __testing = { "queries": [ { "name": "__testing" },
                               { "name": "get_location" },
                               { "name": "get_name" },
                               { "name":"get_temp_threshold"},
                               {  "name":"get_to_number"}
                               ]
                      }      
        get_location = function(){
          ent:location.defaultsTo("room")
        }
        get_name = function(){
          ent:name.defaultsTo("2080ti")
        }
        get_temp_threshold = function(){
          ent:temp_threshold.defaultsTo(90)
        }
        get_to_number = function(){
          ent:to_number.defaultsTo(7633505859)
        }

    }
    rule hearbeat{
        select when sensor profile_updated
         pre {
          // name = event:attr("name") || ent:name
            // location          = (event:attr("location") != "") => event:attr("location") | ent:location 
            // name              = (event:attr("name") != "") => event:attr("name") | ent:name
            // temp_threshold    = (event:attr("temp_threshold") != "") => event:attr("temp_threshold") | ent:temp_threshold
            // to_number         = (event:attr("to_number") != "") => event:attr("to_number") | ent:to_number
            
            location          = event:attr("location") || ent:location 
            name              = event:attr("name") || ent:name
            temp_threshold    = event:attr("temp_threshold") || ent:temp_threshold
            to_number         = event:attr("to_number") || ent:to_number
            

         } 
        
        send_directive("bob")
        always{
            ent:location := location;
            ent:name := name;
            ent:temp_threshold := temp_threshold;
            ent:to_number := to_number;
        }
    }
}



