import PackageDescription

let package = Package(
    name: "PageKit",
    dependencies: [
        .Package(url: "https://github.com/apple/swift-protobuf.git", majorVersion: 0),
        .Package(url: "https://github.com/nathanborror/swift-grpc.git", majorVersion: 0),
    ]
)
