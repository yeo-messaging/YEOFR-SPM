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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.7.1/YEOFR.xcframework.zip",
      checksum: "908be763dc990fb09419eb7b069ef68b9485e7ffa0f33b151e7cb92baf888af4"
    )
  ]
)
