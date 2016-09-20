#!/bin/bash
# Script to test HTTP-2 in the clear (H2C) 
# Authors: Matteo Varvello and Kyle Schomp 

# Function to print script usage
usage(){
    echo -e "Usage: $0 hostname"
	echo -e "hostname         = target hostname"
	exit 0
}

# Function to send to a socket 
socksend ()
{
	printf "GET $file HTTP/1.1\r\n" >&5
	printf "Host: $HOSTNAME\r\n" >&5
	printf "Connection: Upgrade, HTTP2-Settings\r\n" >&5
	printf "Upgrade: h2c\r\n" >&5
	printf "HTTP2-Settings: AAMAAABkAAQAAP__\r\n" >&5
	printf "\r\n" >&5
}


# Function to read from a socket 
sockread (){
	read -r RETURN <&5
}

# function to tun a test 
runTest(){
	PORT=$1
	if ! exec 5<> /dev/tcp/$HOST/$PORT; then
	  echo "unable to connect to $HOST:$PORT"
	  exit 1
	fi

	# Ask for h2-c  
	socksend
	sockread
	echo $RETURN 
	sockread
	echo $RETURN 
	sockread
	echo $RETURN 

	# close the socket 
	exec 5>&-
}

# Check that input parameters are correct
[[ $# -lt 1 ]] && usage

# Common variables 
id=$1                                              # experiment ID
h=`hostname`                                       # machine hostname
HOSTNAME=""                                        # Hostname to be contacted 
HOST=""                                            # IP address of host to be contached
file=""                                            # file to get
IP=""                                              # Public IP of the machine 
timeout=10                                         # Timeout for an operation to complete

# derive host 
file="/"
HOSTNAME=$1
HOST=`getent hosts $HOSTNAME | cut -f 1 -d " "` 

# Run test 
runTest 80

