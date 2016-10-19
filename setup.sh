#!/bin/bash

#
# Generate RSA certificate and key
#
# The 'host' is the host on which the server is listening and 'prefix' is just
# used to prefix the output files.
#
# $ gen.sh <host> <prefix>
#
# Based on: https://blog.justonepixel.com/geek/2016/03/20/grpc-certificate
#

PASSWORD=`LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1`
HOST="localhost"
PREFIX="server/dev"

openssl genrsa -passout pass:${PASSWORD} -des3 -out "${PREFIX}.key" 4096
openssl req -passin pass:${PASSWORD} -new -x509 -days 3650 -key "${PREFIX}.key" -out "${PREFIX}.crt" -subj '/C=US/ST=CA/L=PaloAlto/O=MyApp/CN='${HOST}'/emailAddress=nathan@nathanborror.com'
openssl rsa -passin pass:${PASSWORD} -in "${PREFIX}.key" -out "${PREFIX}.key"
cp ${PREFIX}.crt clients/cmd
