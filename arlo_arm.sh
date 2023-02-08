#!/bin/bash

# cd to dir
cd $(dirname -- "$0")

source ./arlo.sh

# arm device
for deviceId in "$@"
do
    call /hmsweb/users/devices/automation/active "$(cat <<JSON
{"activeAutomations": [
     {
          "deviceId": "$deviceId",
          "timestamp": $(date +%s)234,
          "activeModes": ["mode1"],
          "activeSchedules": []
     }
     ]
}
JSON
)"
done

