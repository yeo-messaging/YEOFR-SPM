# YEOFR

On-device face recognition with fused liveness and TrueDepth anti-spoofing for
iOS, distributed as a binary xcframework.

Add one SPM product — `YEOFR` — and get:

- **Face recognition** — recognise an enrolled user, reject everyone else.
- **Liveness CNN** — passive anti-spoof on the face crop.
- **TrueDepth fusion** — 3D-vs-flat verdicts on capable devices.
- **`FaceTrustService`** — a turnkey object that owns the camera, runs the
  fused pipeline, manages the identity gate, and persists enrolment, exposing
  the whole thing as two `AsyncStream`s.

> **0.5.x is the supported line.** The older `0.6.x` pre-release line is
> retired — do not pin to it.

---

## Requirements

| | |
|---|---|
| iOS | 17.0+ |
| Swift | 5.9+ |
| Devices | **Real iPhone only** — the xcframework has no simulator slice |
| Camera | Front camera required; **TrueDepth recommended** for depth anti-spoof |

Linking on the simulator fails with `building for 'iOS-simulator', but linking
in object file … built for 'iOS'` — build and run on a device.

---

## Install

`File ▸ Add Package Dependencies…` and paste (use the **HTTPS** URL — Xcode's
dialog can't resolve SSH):

```
https://github.com/YEOMessaging/YEOFR-SPM
```

Or in `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/YEOMessaging/YEOFR-SPM", from: "0.5.6")
],
targets: [
  .target(name: "YourApp",
          dependencies: [.product(name: "YEOFR", package: "YEOFR-SPM")])
]
```

Your target's iOS deployment floor must be **17.0** or higher, or package
resolution fails. Add the camera-usage key:

```xml
<key>NSCameraUsageDescription</key>
<string>Used to verify your identity with face recognition.</string>
```

---

## Pilot access for non-YEO bundle IDs

YEOFR is gated to YEO-owned bundle IDs — constructing the SDK on a non-YEO
bundle id aborts unless you pass a valid **pilot unlock code** (issued for a
fixed evaluation window). Email **christo@yeomessaging.com** to request one.
On a `com.youreyeonly.*` bundle id the gate passes natively and the code is
ignored. The code has a hard expiry baked into the build; once expired, request
a fresh one.

---

## Quickstart

`FaceTrustService` is the whole integration — it owns the engine, the camera,
the fused-trust pipeline, the identity gate, and tracker persistence.

```swift
import YEOFR

let service = FaceTrustService(pilotUnlockCode: "YOUR-PILOT-CODE")
// Attach service.previewSession to an AVCaptureVideoPreviewLayer.
try await service.start()

// Enrol once — a short guided capture, persisted + gated automatically:
for await step in service.enroll(name: "Alice") {
    // step.phase: .capturing (show step.prompt / step.poseProgress) → .completed
}

// Live recognition:
for await update in service.updates() {
    // update.status: .noFace / .badFraming / .notTrusted / .trusted
    // update.matchedName, update.livenessGenuine, update.depthIsThreeD
}
```

`update.status == .trusted` already fuses face recognition, liveness, and
TrueDepth, with framing applied — you never pick a similarity threshold, never
touch the identity gate, and never manage the tracker file. The enrolment is
restored across launches; `service.enrolledName` reflects who is enrolled.

A single front pose separates the enrolled user from other people. For better
recall as the user turns their head, pass
`poses: PoseTarget.lightingAwareGallerySequence` to `enroll`.

---

## Example app

A complete, runnable SwiftUI app is in **[`Examples/FRPilot`](Examples/FRPilot)**
— enrol a face, then run live TRUSTED / NOT TRUSTED recognition. It references
this package by relative path, so it builds against the package it ships with.
Read it as the canonical integration reference.

---

## Advanced: encrypted tracker storage

`FaceTrustService` persists the tracker as plaintext in the app container. For
encrypted at-rest storage, build a `YEOFRSDK` with an encryption mode and hand
it to the bring-your-own-engine initializer:

```swift
let sdk = try YEOFRSDK(
    pilotUnlockCode: "YOUR-PILOT-CODE",
    encryption: .aesGCM(keychainTag: "com.example.app.frsdk")     // or .aesCBCHMAC / .custom
)
let service = FaceTrustService(sdk: sdk)
```

See `YEOEncryption`, `EncryptedBlob`, and `KeychainKeyStore` in the API
reference.

---

## Documentation

Full API reference and the latest quickstart:
<https://yeomessaging.github.io/YEOFRSDK-docs/documentation/yeofr/quickstart>.
