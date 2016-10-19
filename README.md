# Pages

An example of building a server/client relationship using [gRPC][1] and [protocol
buffers][2]. In this example the server is written in Go along with a very simple
command line client. The web client is written in [Elm][3] which uses the [gRPC
Gateway][4] interface. And finally the native client is written in Swift using
the new [swift-protobuf][5] library.

---

:warning: This is incomplete. The Swift client and server should build.

---

## Run server

    $ ./setup.sh
    $ make
    $ cd server && go run main.go

## Run iOS client

    $ open clients/ios/Pages/Pages.xcodeproj
    Product > Run (⌘R)

## Run web client

    $ cd clients/web
    $ elm-reactor

## Run command line client

    $ cd clients/cmd
    $ go run main.go

[1]:http://www.grpc.io
[2]:https://developers.google.com/protocol-buffers/
[3]:http://elm-lang.org
[4]:https://github.com/grpc-ecosystem/grpc-gateway
[5]:https://github.com/apple/swift-protobuf
