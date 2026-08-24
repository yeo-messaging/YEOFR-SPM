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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.7.8/YEOFR.xcframework.zip",
      checksum: "00bab59d46e3729c6f13280af72e89b64942f6e49244d94385c23ea6a899ee8d"
    )
  ]
)
