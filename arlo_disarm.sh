#!/bin/bash

# cd to dir
cd $(dirname -- "$0")

source ./arlo.sh

# disarm device
call /hmsweb/users/devices/automation/active "$(cat <<JSON
{"activeAutomations": [
     {
          "deviceId": "$1",
          "timestamp": $(date +%s)324,
          "activeModes": ["mode0"],
          "activeSchedules": []
     }
     ]
}
JSON
)"
