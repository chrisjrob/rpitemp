RPI TEMP
========


Description
-----------

Access the one wire sensors attached to the device and output it via perl dancer.


Routes
------

 * http://0.0.0.0:3000/live
 * http://0.0.0.0:3000/live/json
 * http://0.0.0.0:3000/live/text
 * http://0.0.0.0:3000/history
 * http://0.0.0.0:3000/history/json


Command line
------------

    # ls /sys/bus/w1/devices/
    # hd /sys/bus/w1/devices/28-0417031131ff/id
    # cat /sys/bus/w1/devices/28-0417031131ff/w1_slave
