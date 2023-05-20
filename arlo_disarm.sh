#!/bin/bash

# cd to dir
cd $(dirname -- "$0")

source ./arlo.sh

# disarm device
for deviceId in "$@"
do
     call /hmsweb/users/devices/automation/active "$(cat <<JSON
{"activeAutomations": [
     {
          "deviceId": "$deviceId",
          "timestamp": $(date +%s)324,
          "activeModes": ["mode0"],
          "activeSchedules": []
     }
     ]
}
JSON
)"
done
