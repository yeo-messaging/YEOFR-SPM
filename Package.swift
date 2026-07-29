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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.7.6/YEOFR.xcframework.zip",
      checksum: "77e3d3803aa466c82561ba518e45930ead2c3e5c7bab96637655a63e05ba8dc6"
    )
  ]
)
