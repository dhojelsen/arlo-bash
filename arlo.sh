#!/bin/bash

# cd to dir
#cd $(dirname -- "$0")

# check for bin
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but it's not installed.  Aborting."; exit 1; }
command -v expect >/dev/null 2>&1 || { echo >&2 "ecpect is required but it's not installed.  Aborting."; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo >&2 "openssl is required but it's not installed.  Aborting."; exit 1; }

# check for conf
[ -f ./arlo.conf ] || { echo >&2 "A file called arlo.conf is required.  Aborting."; exit 1; }

# loading credintials
source ./arlo.conf

# define global variables
ARLO_EXPIRY="0"
ARLO_MFATOKEN=""
ARLO_USERID=""
ARLO_MFATOKEN_B64=""
ARLO_FACTORID=""
ARLO_FACTORCODE=""
ARLO_PIN=""
ARLO_TOKEN=""

# load session if it exists
source ./session.txt 2> /dev/null

# if empty
if [ -z $ARLO_EXPIRY ]; then
	ARLO_EXPIRY="0"
fi

# defining functions
function waitForPin() {

expect -c '

log_user 0

spawn openssl s_client -crlf -quiet -connect '$IMAP_HOST':993
expect "* OK"

send "tag login '$IMAP_USER' '$IMAP_PWD'\r"
expect "tag OK"

send "tag SELECT INBOX\r"
expect "tag OK"

# get number of messages
set buffer_to_parse $expect_out(buffer)
regexp {([0-9]+) EXISTS} $buffer_to_parse -> msgs
set new_msgs $msgs

# monitor mailbox for new messages
while {$msgs == $new_msgs} {
        send "tag SELECT INBOX\r"
	expect "tag OK"

	set buffer_to_parse $expect_out(buffer)
	regexp {([0-9]+) EXISTS} $buffer_to_parse -> new_msgs
	sleep 1
}

# fetch the full mail and flush buffer when full
send "tag FETCH $new_msgs BODY\[text\]\r"
expect {
    full_buffer {puts $expect_out(buffer); exp_continue}
    "tag OK"
}
puts $expect_out(buffer)
' | sed -n '/\s\+[0-9]\{6\}/p' | tr -dc "0-9"

}

function auth() {
	
	# base64 password
	ARLO_PWD_B64="$(echo -n $ARLO_PWD | openssl enc -A -base64)"	
	
 	bin/curl_chrome110 -s -H 'content-type: application/json; charset=UTF-8' \
		-H 'origin: https://my.arlo.com' \
		-H 'referer: https://my.arlo.com/' \
		https://ocapi-app.arlo.com/api/auth \
		-d '{"email": "'$ARLO_USER'", "password": "'$ARLO_PWD_B64'" }' \
		| jq -rc '[.data.token, .data.userId] | @tsv'
		

}


function getFactor() {

	bin/curl_chrome110 -s -H 'content-type: application/json; charset=UTF-8' \
     -H 'origin: https://my.arlo.com' \
     -H 'referer: https://my.arlo.com/' \
     -H "authorization: $ARLO_MFATOKEN_B64" \
     https://ocapi-app.arlo.com/api/getFactors\?data=$(date +%s) \
     | jq -r '.data.items[] | select(.factorType=="EMAIL") | .factorId'

}

function startAuth() {
	
	bin/curl_chrome110 -s -H 'content-type: application/json; charset=UTF-8' \
     -H 'origin: https://my.arlo.com' \
     -H 'referer: https://my.arlo.com/' \
     -H "authorization: $ARLO_MFATOKEN_B64" \
     https://ocapi-app.arlo.com/api/startAuth \
     -d '{"factorId": "'$ARLO_FACTORID'", "factorType": "", "userId": "'$ARLO_USERID'" }' \
     | jq -r '.data.factorAuthCode'
}

function finishAuth() {
	
	bin/curl_chrome110 -s -H 'content-type: application/json; charset=UTF-8' \
     -H 'origin: https://my.arlo.com' \
     -H 'referer: https://my.arlo.com/' \
     -H "authorization: $ARLO_MFATOKEN_B64" \
     https://ocapi-app.arlo.com/api/finishAuth \
     -d '{"factorAuthCode": "'$ARLO_FACTORCODE'", "isBrowserTrusted": true, "otp": "'$ARLO_PIN'" }' \
	 | jq -r '[.data.token, .data.expiresIn, .data.userId] | @tsv'

}

function mfaLogin() {
	
	# call auth and set variables
	read ARLO_MFATOKEN ARLO_USERID < <(auth)

	# encode token
	ARLO_MFATOKEN_B64="$(echo -n $ARLO_MFATOKEN | openssl enc -A -base64)"	

	read ARLO_FACTORID < <(getFactor)
	>&2 echo "Got ARLO_FACTORID $ARLO_FACTORID"
	read ARLO_FACTORCODE < <(startAuth)
	>&2 echo "Got ARLO_FACTORCODE $ARLO_FACTORCODE"
	read ARLO_PIN < <(waitForPin)
	>&2 echo "Got ARLO_PIN $ARLO_PIN"
	read ARLO_TOKEN AUTH_EXPIRY ARLO_USERID < <(finishAuth)
	>&2 echo "Got ARLO_TOKEN $ARLO_TOKEN"

	# store in session
	echo "ARLO_TOKEN=$ARLO_TOKEN" > ./session.txt
	echo "ARLO_USERID=$ARLO_USERID" >> ./session.txt
	echo "ARLO_EXPIRY=$AUTH_EXPIRY" >> ./session.txt
}

function call() {

	ARGS=()

	# post json if supplied
	if [ $# -eq 2 ]; then
		ARGS+="-d ""$2"""
	fi 

	bin/curl_chrome110 -s \
		 -H 'content-type: application/json; charset=UTF-8' \
     	 -H 'origin: https://my.arlo.com' \
     	 -H 'referer: https://my.arlo.com/' \
     	 -H 'auth-version: 2' \
	 	 -H 'schemaversion: 1' \
      	 -H "authorization: $ARLO_TOKEN" \
     	"https://myapi.arlo.com$1" \
		"${ARGS[@]}"

} 

# is session expired
if [ $ARLO_EXPIRY -lt $(date +%s) ]; then
	mfaLogin
fi
