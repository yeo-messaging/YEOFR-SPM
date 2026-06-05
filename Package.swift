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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.6.6/YEOFR.xcframework.zip",
      checksum: "e6096e224f06c85031eb70a945db5ade88451691f932a30e7ae06de01b24d9fc"
    )
  ]
)
