RPI TEMP
========

Access the one wire sensors attached to the device and output it via perl dancer.

http://0.0.0.0:3000/view
http://0.0.0.0:3000/json

# ls /sys/bus/w1/devices/
# hd /sys/bus/w1/devices/28-0417031131ff/id
# cat /sys/bus/w1/devices/28-0417031131ff/w1_slave
