#!/bin/bash

# cd to dir
cd $(dirname -- "$0")

source ./arlo.sh

# disarm device
call /hmsweb/users/library "$(cat <<JSON
{
     "dateFrom":"$1",
     "dateTo":"$2" 
}
JSON)"