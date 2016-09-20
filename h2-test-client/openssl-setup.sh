#!/bin/bash 
# update openssl and modify with my s_client
# Author: Matteo Varvello 

# variables 
openssl_src="openssl-1.0.2d.tar.gz"
fast=$1 

# checks on required tools
if ! hash timeout 2>/dev/null; then
    echo "!! Install <<timeout>> as it required !!"
    exit -1
fi

# check for wget 
if ! hash wget 2>/dev/null; then
	echo "!! Error <<wget>> is missing, please install !!"
fi 

# retrieve openssl if needed 
if [ ! -f $openssl_src ] 
then 
	wget --no-check-certificate http://www.openssl.org/source/openssl-1.0.2d.tar.gz
fi 

# decompress 
tar xzvf $openssl_src

# apply my "patch" to speed up s_client 
cp s_client.c ./openssl-1.0.2d/apps/

# compile and install 
cd openssl-1.0.2d
./config
sudo make
sudo make install
cd
