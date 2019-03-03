import urllib3
import json
import time
import random

class test_manage_sensors():
    def __init__(self):
        # for krl functions
        self.__sky_cloud_url        = "http://localhost:8080/sky/cloud/" 
        # for krl events
        self.__sky_event_url        = "http://localhost:8080/sky/event/"
        self.__manage_sensors_eci   = "2DBYvU8kjCvR43tEcapzAC" 

        '''
            Functions 
        '''
        self.__sensors = "/manage_sensors/sensors"
        '''
           events 
        '''
        self.__new_sensor        = "/sensor/new_sensor"
        self.__unneeded_sensor   = "/sensor/unneeded_sensor"
        self.__del_names         = "sensor/del_names"

    def __sky_cloud(self, function_name, eci):
        url = self.__sky_cloud_url + eci + function_name
        http = urllib3.PoolManager()
        r = http.request('GET', url)
        print(r.status)
        print( r.data)
        return r.data

    def __sky_event(self, function_name, fields, eci):
        url = self.__sky_event_url + eci + "/whatevs" + function_name
        http = urllib3.PoolManager()
        r = http.request('GET',url + "?" + fields )
        print(r.status)
        print( r.data)
        return r.data
        
    def sensors(self ):
        return json.loads(self.__sky_cloud(self.__sensors, self.__manage_sensors_eci))

    def new_sensor(self, fields):
        return json.loads(self.__sky_event(self.__new_sensor, fields,self.__manage_sensors_eci))
    
    def unneeded_sensor(self, fields):
        return json.loads(self.__sky_event(self.__unneeded_sensor, fields,self.__manage_sensors_eci))

    def sensor_profile_fun_call(self, fun, eci):
        return json.loads(self.__sky_cloud("/sensor_profile/" + fun, eci))

    def sensor_profile_event(self, fun, fields, eci):
        return json.loads(self.__sky_event("/sensor/" + fun, fields, eci))

    def temp_store_fun_call(self, fun, eci):
        return json.loads(self.__sky_cloud("/temperature_store/" + fun, eci))

    def temp_store_event(self, fun,fields, eci):
        return json.loads(self.__sky_event("/wovyn/" + fun, fields, eci))


delete_sensors = False
sensor_names = []
sensor_ecis  =[]
num_children = 7
num_temps = 5
t = test_manage_sensors()

for i in range(num_children):
    time.sleep(.1)
    sensor_names.append("sensor_name=sensor" + str(i))
    try:
        sensor_ecis.append(t.new_sensor(sensor_names[i])['directives'][0]['options']['pico']['eci'])
    except(KeyError):
        print("pico already exists")
        continue
# def sensor_profile_event(self, fun, fields, eci): print("\n\n\n len = {}".format(len(sensor_ecis))) 
if len(sensor_ecis) > 0:
    for i in range(num_children):
        time.sleep(.1)
        t.sensor_profile_event("profile_updated", "location=room" + str(i) 
                                + "&name=2080ti" + str(i)  
                                 + "&temp_threshold=8"+ str(i)  
                                + "&to_number=111111111" + str(i),
                                sensor_ecis[i])

        for j in range(num_temps):
            time.sleep(.1)
            t.temp_store_event("new_temperature_reading", "temperature=8" + str(j) 
                                + "&timestamp="+ "000000000" + str(j),
                                sensor_ecis[i]) 

    for i in range(num_children):
        name = t.sensor_profile_fun_call("get_name", sensor_ecis[i])
        location = t.sensor_profile_fun_call("get_location", sensor_ecis[i])
        temp_threshold = t.sensor_profile_fun_call("get_temp_threshold", sensor_ecis[i])
        to_number = t.sensor_profile_fun_call("get_to_number", sensor_ecis[i])
        assert(name=="2080ti"+str(i))
        assert(location=="room"+str(i))
        assert(temp_threshold=="8"+str(i))
        assert(to_number=="111111111"+str(i))

    print("\n\n\n\n")
    for i in range(num_children):
        temperatures = t.temp_store_fun_call("temperatures", sensor_ecis[i])
        threshold_violations = t.temp_store_fun_call("threshold_violations", sensor_ecis[i])
        inrange_temperatures = t.temp_store_fun_call("inrange_temperatures", sensor_ecis[i])
        get_current_temp =  t.temp_store_fun_call("get_current_temp", sensor_ecis[i])

    

if delete_sensors:
    for i in range(num_children):
        time.sleep(.1)
        t.unneeded_sensor(sensor_names[i])


#sensor1 = "sensor_name=sensor1"
#sensor2 = "sensor_name=sensor2"
#sensor3 = "sensor_name=sensor3"
#
#
#try:
#    sensor1_eci = t.new_sensor(sensor1)['directives'][0]['options']['pico']['eci']
#    time.sleep(.1)
#except(KeyError):
#    print("pico already exists")
#
#try:
#    sensor2_eci = t.new_sensor(sensor2)['directives'][0]['options']['pico']['eci']
#    time.sleep(.1)
#except(KeyError):
#    print("pico already exists")
#
#try:
#    sensor3_eci = t.new_sensor(sensor3)['directives'][0]['options']['pico']['eci']
#except(KeyError):
#    print("pico already exists")
#
#time.sleep(.1)
#t.unneeded_sensor(sensor2)
#
#
#sensor1_name = t.sensor_profile_fun_call("get_name", sensor1_eci)
#sensor1_location= t.sensor_profile_fun_call("get_location", sensor1_eci)
#sensor1_temp_threshold= t.sensor_profile_fun_call("get_temp_threshold", sensor1_eci)
#sensor1_to_number = t.sensor_profile_fun_call("get_to_number", sensor1_eci)

   
#t.sensors()
#t.new_sensor()
















