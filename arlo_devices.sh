#!/bin/bash

# cd to dir
cd $(dirname -- "$0")

source ./arlo.sh

# curl to api
curl -s -H 'content-type: application/json; charset=UTF-8' \
     -H 'origin: https://my.arlo.com' \
     -H 'referer: https://my.arlo.com/' \
     -H 'auth-version: 2' \
	 -H 'schemaversion: 1' \
     -H "authorization: $ARLO_TOKEN" \
     https://myapi.arlo.com/hmsweb/v2/users/devices