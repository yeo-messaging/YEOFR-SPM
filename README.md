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
- **Image reference enrolment** — enrol a reference face from a still image
  (no camera) and run offline 1:1 matching against it.

> **0.11.0 is the current release.** Upgrading from an earlier release? See
> [Upgrading to 0.11.0](#upgrading-to-0110). The older `0.6.x` pre-release
> line is retired — do not pin to it.

---

## Requirements

| | |
|---|---|
| iOS | 17.0+ |
| Swift | 5.9+ |
| Devices | Builds for device and simulator; **recognition needs a real iPhone** |
| Camera | Front camera required; **TrueDepth recommended** for depth anti-spoof |

The xcframework ships an Apple-silicon simulator slice (`arm64`), so your app
and its unit tests compile and run in the simulator. The recognition engine is inert there —
every frame reports no face. Anything that must actually recognise a face has to
run on a device.

---

## Install

`File ▸ Add Package Dependencies…` and paste (use the **HTTPS** URL — Xcode's
dialog can't resolve SSH):

```
https://github.com/yeo-messaging/YEOFR-SPM
```

Or in `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/yeo-messaging/YEOFR-SPM", from: "0.11.0")
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

## Licensing for non-YEO bundle IDs

YEOFR is gated to YEO-owned bundle IDs. On a non-YEO bundle id you need one of
two credentials — email **christo@yeomessaging.com** for either. On a YEO-owned
bundle id the gate passes natively and both are ignored.

**Signed license file (preferred, 0.7.6+).** You get a `.yeolicense` file
issued for your bundle id and validity window. Bundle it with the app and pass
its bytes to the initializer:

```swift
let license = try Data(contentsOf: Bundle.main.url(forResource: "MyApp",
                                                   withExtension: "yeolicense")!)
let sdk = try YEOFRSDK(license: license)
let service = FaceTrustService(sdk: sdk)
```

A bad license throws `YEOLicenseError` — `.malformed`, `.invalidSignature`,
`.notYetValid`, `.expired`, `.bundleIDMismatch`, `.unsupportedVersion` — so you
can show your own "unlicensed" screen instead of crashing. `sdk.licenseClaims`
reports the granted bundle ids, validity window, and features. See
`Examples/FRPilot` for a complete implementation of both paths.

**Pilot unlock code (legacy).** A time-limited code string passed as
`FaceTrustService(pilotUnlockCode:)` / `YEOFRSDK(pilotUnlockCode:)`. Unlike a
license file, an invalid or expired code **aborts the process** — it is a hard
gate you cannot catch. Prefer a license file for anything shipping to users.

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
    // step.phase: .capturing (show step.prompt) → .completed / .failed
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

A single capture separates the enrolled user from other people. For better
recall as the user turns their head, call `enroll(name:)` again under other
angles and lighting, enrol from photos you already hold with
`enroll(name:images:)`, or drive the guided five-pose walk with
`PoseWalkEnrollment` from your own camera loop.

---

## Upgrading to 0.11.0

From 0.9.1 (the previous public release):

- **One built-in liveness model.** The fused pipeline always runs it; there is
  no model to choose. `YEOPADModel` has a single case, and
  `LivenessFusionConfig` no longer takes `padModel:` or `padFusion:`.
- **Removed API:** `YEOPADFusion`, `YEOLivenessCalibration` and the
  `FaceTrustSession` calibration methods, the `ObservedSignalRates`
  `padFusion` / `padWindowSpan` members, and `YEOPADModel.isSingleFrame` /
  `combinesTwoModels`. Code that set a model, a fusion rule or a per-user
  calibration can simply drop it.
- **Now `async`:** `YEOFRSDK.detectFaces(params:needFaceRect:)`,
  `imageMatchScore(_:)`, `imageMatchesTracker(_:)`, `enrollReference(from:name:)`
  and `FaceTrustSession.stillPADResult(image:faceRect:)`. Call them with
  `await`.
- **Re-enrol after upgrading.** The recognition model changed, and a gallery
  saved by an earlier release is refused rather than loaded: `loadTracker`
  returns an error code and leaves the current state untouched. Ask users to
  enrol again.
- **Liveness verdict from `detectFaces`.** `SDKFaceRecognitionResult.confidence`
  is now the liveness *verdict* for the face in view, built up over recent
  frames, not one frame's score. It is `0` until there is a verdict (under a
  second of a steady face) and whenever framing is invalid. `isConfident()`
  now defaults to `0.5`, the same bar as the Android SDK. Treat a face as
  live when `faceState == .detected && result.isConfident()`, and drop any
  hard-coded threshold such as `0.71`. `FaceTrustService` users need no change:
  `update.status` already applies the full liveness rule.

---

## Example app

A complete, runnable SwiftUI app is in **[`Examples/FRPilot`](Examples/FRPilot)**
— enrol a face, then run live TRUSTED / NOT TRUSTED recognition. It references
this package by relative path, so it builds against the package it ships with.
Read it as the canonical integration reference.

---

## Advanced: encrypted tracker storage

`FaceTrustService` persists the tracker as **plaintext** in the app container
(it uses the SDK's raw tracker APIs), so configuring an encryption mode and
handing the SDK to `FaceTrustService(sdk:)` does **not**, on its own, encrypt the
saved file.

The SDK offers two encryption modes — `.plaintext` and `.custom` (bring your own
`Cryptor`, e.g. a CryptoKit AEAD). The cryptor is applied by the SDK's
`encrypted*` tracker APIs, so for encrypted-at-rest storage you own persistence:

```swift
// A custom Cryptor — see Examples/FRPilot/ChaChaPolyCryptor.swift (ChaChaPoly).
let sdk = try YEOFRSDK(pilotUnlockCode: "YOUR-PILOT-CODE",
                       encryption: .custom(MyCryptor()))

// Save — serialize the tracker through the configured cryptor:
if let blob = try sdk.encryptedFaceRecognitionTrackerData() {
    try blob.serialized().write(to: url, options: .atomic)
}

// Load — parse + decrypt through the cryptor:
try sdk.loadTracker(from: EncryptedBlob.parse(Data(contentsOf: url)))
```

A complete worked example — plaintext vs ChaChaPoly-encrypted enrolment wrapped
around `FaceTrustService` — lives in `Examples/FRPilot`.

See `YEOEncryption`, `Cryptor`, `EncryptedBlob`, and `KeychainKeyStore` in the
API reference.

---

## Documentation

Full API reference and the latest quickstart:
<https://yeomessaging.github.io/YEOFRSDK-docs/documentation/yeofr/quickstart>.
