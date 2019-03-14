ruleset manager_profile{
        rule send_sms{
        select when something something 
        event:send(
          	{ 	"eci": wrangler:parent_eci(), "eid": "mischief-identity",
          	  	"domain": "mischief", "type": "who",
          	  	"attrs": { "eci": wrangler:myself(){"eci"} } 
    		} 
    	)
    }
}


