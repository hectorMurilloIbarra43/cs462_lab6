ruleset identify_me {
   meta {
        shares  __testing // for events
               
            
            
         use module io.picolabs.wrangler alias Wrangler
         use module io.picolabs.subscription alias subscription
        
    }
    global{
        __testing = { "events":  [ 
                                    { "domain": "mischief", "type": "identity", 
                                      "attrs": [ "manager_eci","name","host","connecting_to" ] }
                                  ]
        }
    }
  
        rule mischief_identity {
        select when mischief identity
        pre{
            manager_eci = event:attr("manager_eci")
            
            manager_name = event:attr("name")
            host = event:attr("host")
            connecting_to = event:attr("connecting_to")
        }
        event:send(
          	{ 	"eci": manager_eci, "eid": "mischief-identity",
          	  	"domain": "mischief", "type": "who",
          	  	"attrs": { "eci"  : Wrangler:myself(){"eci"}, 
          	  	           "name" : manager_name,
          	  	           "host":host,
          	  	           "connecting_to":connecting_to} 
    		} 
    	)
    }
}



