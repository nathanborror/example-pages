#!/bin/bash

#
# Generate RSA certificate and key
#

PASSWORD=`LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1`
HOST="localhost"
PREFIX="server/dev"

echo "Generating certificates..."
openssl genrsa -passout pass:${PASSWORD} -des3 -out "${PREFIX}.key" 4096 > /dev/null
openssl req -passin pass:${PASSWORD} -new -x509 -days 3650 -key "${PREFIX}.key" -out "${PREFIX}.crt" -subj '/C=US/ST=CA/L=PaloAlto/O=MyApp/CN='${HOST}'/emailAddress=nathan@nathanborror.com' > /dev/null
openssl rsa -passin pass:${PASSWORD} -in "${PREFIX}.key" -out "${PREFIX}.key" > /dev/null
cp ${PREFIX}.crt clients/cmd

echo "Downloading grpc..."
go get google.golang.org/grpc

echo "Downloading protobuf..."
go get -u github.com/golang/protobuf/{proto,protoc-gen-go}

echo "Downloading swift-protobuf..."
git clone -q https://github.com/apple/swift-protobuf.git /tmp/swift-protobuf
cd /tmp/swift-protobuf

echo "Building swift-protobuf..."
swift build > /dev/null

echo "Copying protoc-gen-swift to /usr/local/bin..."
cp /tmp/swift-protobuf/.build/debug/protoc-gen-swift /usr/local/bin/

echo "Downloading grpc-gateway..."
go get -u github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway
