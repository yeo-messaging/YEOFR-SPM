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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.11.3/YEOFR.xcframework.zip",
      checksum: "e75a00074022be291a9f64ca67e55fd7b7b40d875016b76da42b1160ef475e1b"
    )
  ]
)
