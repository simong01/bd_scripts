#!/bin/sh

i2cbus=`ls /sys/bus/i2c/devices | grep i2c | sed "s/i2c-//" | sort -n`
for item in $i2cbus; do echo -n "$item - "; cat /sys/bus/i2c/devices/i2c-${item}/uevent | grep OF_FULLNAME;echo; done
