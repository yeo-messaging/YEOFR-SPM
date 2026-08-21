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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.7.7/YEOFR.xcframework.zip",
      checksum: "5158739de1faa2dba92d8f7e7f20d3d75f6651bd1c93bb8a725fbad2fe3c74a2"
    )
  ]
)
