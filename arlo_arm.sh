#!/bin/bash

# cd to dir
cd $(dirname -- "$0")

source ./arlo.sh

# arm device
call /hmsweb/users/devices/automation/active "$(cat <<JSON
{"activeAutomations": [
     {
          "deviceId": "$1",
          "timestamp": $(date +%s)234,
          "activeModes": ["mode1"],
          "activeSchedules": []
     }
     ]
}
JSON
)"
