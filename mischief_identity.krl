ruleset identify_me {
        rule mischief_identity {
        select when mischief identity
        event:send(
          	{ 	"eci": wrangler:parent_eci(), "eid": "mischief-identity",
          	  	"domain": "mischief", "type": "who",
          	  	"attrs": { "eci": wrangler:myself(){"eci"} } 
    		} 
    	)
    }
}


