#!/bin/bash 
# Script to test bunch of H2-related functionalities against a target URL 
# Authors: Matteo Varvello 

# simple function for logging
myprint(){
	timestamp=`date +%s`
	if [ $DEBUG -ne 0 ]
	then
		if [ $# -eq  1 ]
		then
			echo -e "[$0][$timestamp]\t" $1
		else
			echo -e "[ERROR][$timestamp]\tMissing string to log!!!"
		fi
	fi
	}

# Function to print script usage
usage(){
    echo -e "Usage: $0 url [debug]" 
	echo -e "url    = url under test" 
	echo -e "[debug = is passed, print debugging info. Otherwise no debugging]" 
    exit -1
}

# Verify input parameters 
[[ $# -lt 1 ]] && usage

# Parameters
url=$1                       # url under test 
port=443                     # NPN port
timeout=5                    # timeout for ALPN/NPN negotiations
strALPN=""                   # output of ALPN negotation 
strNPN="NO-NPN-SUPPORT"      # output of NPN negotiation (default is no support) 
tALPN=0                      # duration of ALPN negotiation 
tNPN=0                       # duration of NPN negotiation 
DEBUG=0                      # print debugging information or not 
ip="n/a"                     # ip resolved for url 
org="n/a"                    # organization behind url  
country="n/a"                # country of ip (maxmind) 
AS="n/a"                     # AS of ip (maxmind) 

# read optional input 
[[ $# -eq 2 ]] && DEBUG=1

# checks on required tools 
if ! hash timeout 2>/dev/null; then
	echo "!! Install <<timeout>> as it required !!"
	exit -1 
fi 
if ! hash getent 2>/dev/null; then  
	echo "!! Install <<getent>> as required !!" 
	exit -1 
fi 

# whoise for organization 
ip=`getent ahostsv4 $url | head -1 | cut -f 1 -d ' '`
if exec 5<> /dev/tcp/199.212.0.46/43; then
	printf "n $ip\r\n" >&5

	# derive organization
	org=`cat <&5 | grep -m 1 OrgName: | sed "s/OrgName:\\s\+//g"`
	
	#Close fd
	exec 5>&-
fi

# derive country and AS -- maxmind 
if hash geoiplookup 2>/dev/null; then
	geoiplookup $ip > .lookup 2>&1
	failed=`cat .lookup | grep "Country" | grep "not found" | wc -l`
	if [ $failed -eq 1 ]
	then
		country="NaN"
	else
		country=`cat .lookup | grep "Country" | cut -f 1 -d "," | awk '{print $NF}'`
	fi
	failed=`cat .lookup | grep "ASNum" | grep "not found" | wc -l`
	if [ $failed -eq 1 ]
	then
		AS="NaN"
	else
		AS=`cat .lookup  | grep "ASNum"  | cut -f 4 -d " "`
	fi 
else 
	echo "command <<geoiplookup>> (maxmind) missing"
fi 

# logging 
myprint "Testing URL: $url IP: $ip Country: $country Org: $org AS: $AS"

# testing ALPN support 
if hash /usr/local/ssl/bin/openssl 2>/dev/null; then
	myprint "Testing ALPN!"
	tStart=$(($(date +%s%N)/1000000))
	strALPN=`timeout $timeout /usr/local/ssl/bin/openssl s_client -alpn 'h2,http/1.1' -servername $url -connect $url:443  2>&1 | awk '{if($1 == "ALPN") {split($0, arr, ":"); print "ALPN:"arr[2];} if($2 == "ALPN") print "NO-ALPN"; if($2=="Connection" && $3 == "refused") print "NO-TLS"; if($1=="gethostbyname" || $0=="connect: No route to host") print "DNS-FAILURE"}'`
	tEnd=$(($(date +%s%N)/1000000))
	let "tALPN = tEnd - tStart"

	# derive timeout based on measurement of ALPN duration 
	tout_est=`echo $tALPN | awk '{val=($1*2)/1000; (val==int(val)) ? val : val = int(val)+1; print val; }'`
	myprint "ALPN Result: $strALPN Duration $tALPN ms. New timeout is: $tout_est sec"

	# testing NPN support 
	if [ "$strALPN" != "NO-TLS" -a $tout_est -le $timeout ]
	then
		myprint "Testing NPN!"
		tStart=$(($(date +%s%N)/1000000))
		timeout $tout_est /usr/local/ssl/bin/openssl s_client -nextprotoneg '' -servername $url -connect $url:443  > .temp 2>&1
		tEnd=$(($(date +%s%N)/1000000))
		let "tNPN = tEnd - tStart"
		lines=`cat .temp | grep advertised | wc -l | cut -f 1 -d " "`
		if [ $lines -gt 0 ]
		then
			proto=`cat .temp | grep advertised | cut -f 2 -d ":" | sed  "s/","//g"`
			strNPN="NPN:"$proto
		else
			strNPN="NO-NPN-SUPPORT"
		fi
		myprint "NPN Result: $strNPN Duration $tNPN ms"
	else
		if [ $tout_est -ge $timeout ]
		then
			strALPN="TLS-TIMEOUT"
		fi 
	fi 
else 
	echo "<</usr/local/ssl/bin/openssl>> is missing. Please run script <<openssl-setup.sh>>"
fi 	

# test for h2c support 
myprint "Testing H2C"
h2c="n/a"
tH2C=0
if [ -f "./test-h2-clear.sh" ] 
then 
	if [ $tout_est -gt $timeout ]
	then
		tout_est=$timeout 
	fi
	tStart=$(($(date +%s%N)/1000000))
	timeout $tout_est "./test-h2-clear.sh" $url 80 > .res 2> /dev/null
	tEnd=$(($(date +%s%N)/1000000))
	let "tH2C = tEnd - tStart"
	code=`cat .res | grep h2c | wc -l`
	if [ "$code" -eq 1 ]
	then
		h2c="h2clear=SUPPORTED"
	else
		h2c="h2clear=FAILED"
	fi
	myprint "H2C Result: $h2c Duration $tH2C ms"
else 	
	echo "Script <<test-h2-clear.sh>> is missing" 
fi 

# Construct string to be reported 
echo -e $url "\t" $ip "\t" $org "\t" $country "\t" $AS "\t" $strALPN "\t" $tALPN "ms\t" $strNPN "\t" $tNPN "ms\t" $h2c "\t" $tH2C "ms"

# Report time information 
te=`date +%s`
let "tPassed = te - ts"

# cleanup 
rm -f .tmp      # skip this if you wanna get more info from openssl 
rm -f .res      # skip this if you wanna read full h2c test result
rm -f .lookup   # skip this if you wanna see full output from Maxmind lookup 

# That's all folks!
myprint "Test duration: $tPassed" 
