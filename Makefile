all:
	make protobuf
	make web

protobuf:
	protoc -I . -I ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis --swift_out=clients/ios/PageKit/Sources --go_out=Mgoogle/api/annotations.proto=github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis/google/api,plugins=grpc:pages --grpc-gateway_out=logtostderr=true:pages *.proto

web:
	cd clients/web && elm-make Main.elm --output elm.js
