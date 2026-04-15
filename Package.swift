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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.4.10/YEOFR.xcframework.zip",
      checksum: "503141144c7295a403800d42f7269b4cf2fee2d1b9a1b40784afd39bc79a8eb5"
    )
  ]
)
