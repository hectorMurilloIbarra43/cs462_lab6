ruleset manager_profile{
      meta {
        use module io.picolabs.lesson_keys
        use module io.picolabs.twilio_v2 alias twilio
            with account_sid = keys:twilio{"account_sid"}
                auth_token  = keys:twilio{"auth_token"}
        use module sensor_profile

    }
    global{
        to = 7633505859

    }
    
    rule send_sms{
        select when send threshold_violation_sms 
        twilio:send_sms(to,
                        event:attr("from"),
                        event:attr("message")
                       )
    }
}




