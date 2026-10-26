// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "YEOFR",
  platforms: [.iOS(.v17), .macOS("26.0")],
  products: [
    .library(name: "YEOFR", targets: ["YEOFR"])
  ],
  targets: [
    .binaryTarget(
      name: "YEOFR",
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.11.2/YEOFR.xcframework.zip",
      checksum: "7318143c7e2a9496604740304f71cb0abf768c46bd24b6a77048125cfd18347f"
    )
  ]
)
