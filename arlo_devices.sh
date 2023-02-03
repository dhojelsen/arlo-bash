#!/bin/bash

# cd to dir
cd $(dirname -- "$0")

source ./arlo.sh

# call get devices
call /hmsweb/v2/users/devices