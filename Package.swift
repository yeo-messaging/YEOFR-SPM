// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "YEOFR",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "YEOFR", targets: ["YEOFR"])
  ],
  targets: [
    .binaryTarget(
      name: "YEOFR",
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.7.3/YEOFR.xcframework.zip",
      checksum: "8e336037642b684861a74004670af4cc10648e7fdb638369748c67a32f2752a8"
    )
  ]
)
