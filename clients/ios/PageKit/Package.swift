import PackageDescription

let package = Package(
    name: "PageKit",
    dependencies: [
        .Package(url: "https://github.com/nathanborror/swift-protobuf.git", Version(0, 9, 25)),
        .Package(url: "https://github.com/nathanborror/swift-grpc.git", Version(0, 1, 11)),
    ]
)
