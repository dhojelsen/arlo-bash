#!/bin/bash

# cd to dir
cd $(dirname -- "$0")

source ./arlo.sh

# disarm device
call /hmsweb/users/devices/automation/active "$(cat <<JSON
{"activeAutomations": [
     {
          "deviceId": "$1",
          "timestamp": $(date +%s),
          "activeModes": ["mode0"],
          "activeSchedules": []
     }
     ]
}
JSON
)"
