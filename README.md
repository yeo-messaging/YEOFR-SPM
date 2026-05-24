# YEOFR

iOS Swift Package for face recognition + liveness, distributed as a binary
xcframework.

As of **0.5.0**, liveness has been merged into YEOFR. A consumer adopts a
single SPM product — `YEOFR` — and gets all of:

- **Face recognition** — 1:1 verify and 1:N identify.
- **Liveness CNN** — passive anti-spoof on the face crop.
- **Multi-signal anti-spoof** — texture / temporal / flicker on the full frame.
- **TrueDepth fusion** (recommended on capable devices) — 3D-vs-flat verdicts
  that act as rescue evidence when the CNN false-positives a real user.
- **Per-frame fusion pipeline** — `FaceTrustSession` runs all of the above and
  emits a single fused trust verdict.

The previous `YEOLivenessSPM` package is **deprecated**. Do not add it
alongside YEOFR — the same symbols now live in this package.

---

## Requirements

| | |
|---|---|
| iOS | 17.0+ |
| Swift | 5.9+ |
| Devices | **Real iPhone only** — the xcframework has no simulator slice |
| Camera | Front camera required; **TrueDepth strongly recommended** — see [Why TrueDepth matters](#why-truedepth-matters) |

The simulator restriction surfaces as a linker error if you try to run on the
simulator anyway:

```
ld: building for 'iOS-simulator', but linking in object file
(.../libfsdk-static.a[arm64]...) built for 'iOS'
```

---

## Install

### Xcode UI

`File ▸ Add Package Dependencies…` and paste:

```
https://github.com/YEOMessaging/YEOFR-SPM
```

Pin to the current stable tag — `0.5.4`. The `0.6.x` line is currently
published as **pre-release** while we stabilise it; see
[Pre-release: 0.6.x](#pre-release-06x) below to opt in. Full release list
lives on [Releases](https://github.com/YEOMessaging/YEOFR-SPM/releases).

> Use the **HTTPS** URL, not SSH. Xcode's Add-Package dialog uses libgit2,
> which does not pick up the system SSH agent and will fail to resolve SSH
> URLs.

### `Package.swift`

```swift
dependencies: [
  // `.upToNextMinor` keeps you on the 0.5.x stable line. Plain
  // `from: "0.5.4"` would still resolve to 0.6.2 — SwiftPM ignores
  // GitHub's pre-release flag and treats every 0.x bump as in-range
  // until 1.0.0.
  .package(
    url: "https://github.com/YEOMessaging/YEOFR-SPM",
    .upToNextMinor(from: "0.5.4")
  )
],
targets: [
  .target(
    name: "YourApp",
    dependencies: [.product(name: "YEOFR", package: "YEOFR-SPM")]
  )
]
```

Your target's iOS deployment target must be `17.0` or higher — the xcframework
ships with `MinimumOSVersion = 17.0` and a lower platform floor will trigger a
graph-register failure when Xcode resolves the package.

---

## Pre-release: 0.6.x

The `0.6.x` line (`0.6.0`, `0.6.1`, `0.6.2`) is published as **pre-release**
while the new SDK surface stabilises. Default consumers should stay on
`0.5.4`. Note that SwiftPM does **not** honor GitHub's pre-release flag, so
you must use `exact:` or a bounded range to opt in or out deliberately —
plain `from:` will pull `0.6.2`.

What's in the 0.6.x line (covered by the rest of this README):

- **0.6.0** — pilot unlock code is passed on every designated initialiser;
  no more static `activate(...)`; no `YEOFRSDK.shared` singleton.
- **0.6.1** — throwing `init(useCase:pilotUnlockCode:encryption:)` and the
  `YEOEncryption` selector (plaintext / AES-GCM / AES-CBC+HMAC / custom).
- **0.6.2** — single-arg `FaceTrustSession(sdk:)`; the three-arg form is
  removed.

To opt in, pin exactly:

```swift
dependencies: [
  .package(
    url: "https://github.com/YEOMessaging/YEOFR-SPM",
    exact: "0.6.2"
  )
]
```

> The hello-world, the cryptor section, and the API table below all
> document the 0.6.x surface. If you're on `0.5.4`, treat those snippets
> as forward-looking — the older API (static `activate`, three-arg
> `FaceTrustSession`, no encryption selector) is what compiles against
> 0.5.x.

---

## Info.plist keys

```xml
<key>NSCameraUsageDescription</key>
<string>Used to verify your identity with face recognition.</string>
```

`NSFaceIDUsageDescription` is **not** required by YEOFR — only add it if your
app uses Apple's Face ID separately.

If you drive Info.plist via build settings (`GENERATE_INFOPLIST_FILE = YES`):

```
INFOPLIST_KEY_NSCameraUsageDescription = Used to verify your identity with face recognition.
```

---

## Pilot access for non-YEO bundle IDs

YEOFR is gated to YEO-owned bundle IDs by default — non-YEO bundle
IDs abort the moment a `YEOFRSDK` instance is constructed, with a
printed contact hint.

For evaluation customers, we issue a **temporary unlock code** that
bypasses the bundle gate during a fixed pilot window. Email
**christo@yeomessaging.com** to request one.

As of **0.6.0** the unlock code is passed directly to the SDK's
designated initialisers — there is no longer a separate static
`activate(...)` call, and there is no `YEOFRSDK.shared` singleton.
Every public initialiser requires the code:

```swift
import YEOFR

let sdk = YEOFRSDK(
    useCase: .authentication,
    pilotUnlockCode: "<contact-us-for-pilot-code>"
)

let faceTrust = FaceTrustSession(sdk: sdk)
```

If your app is YEO-owned, pass any non-empty string — the gate
passes natively on a YEO bundle ID regardless of the value.

The code has a **hard expiry baked into the SDK build**. Once expired,
no code unlocks the gate regardless of value — request a fresh build
from us. This is a stop-gap measure for the 0.x cycle; the
forward-looking licensing scheme is tracked under CSI-384.

---

## Why TrueDepth matters

`FaceTrustSession` produces a trust verdict by fusing four signals:

1. The liveness CNN (`SpoofVerdict`).
2. Multi-signal anti-spoof (texture / temporal / flicker on the full frame).
3. TrueDepth depth verdict (`YEOFRDepthVerdict.threeD` / `.flat`).
4. The face-recognition match.

Signals (1) and (4) are easy to wire — a video buffer is enough.

In practice the CNN **will** false-positive real users in adverse conditions
(notably people wearing glasses, or under poor exposure). The fusion engine
has a *rescue evidence* path (`LivenessService.swift`) that overrides a
suspicious CNN score when **depth = 3D** and the multi-signal anti-spoof
combined score is healthy. Without TrueDepth wiring, that path can never
fire — `depthValue` stays at `.notDetermined`, and the CNN false-positive
becomes the verdict.

Conclusion: if your target device has a TrueDepth front camera (iPhone X
and later), wire the depth pipeline. The
[hello world](#5-minute-hello-world) below adopts `YEOFRTrueDepthHandling`
and is what `CFRDemo` and `iosclient` both ship in production. Treat the
RGB-only path as a *fallback for non-TrueDepth devices*, not a default.

---

## 5-minute hello world

A self-contained SwiftUI sample. Three files: a permission gate, an
`AVCaptureVideoPreviewLayer` wrapper, and a view model that does the FR +
liveness + TrueDepth wiring. Drop these into a fresh SwiftUI project,
set `NSCameraUsageDescription`, push to a real iPhone, and you're
integrated. This is the same shape `CFRDemo` ships in.

The view model picks `.builtInTrueDepthCamera` when available and falls
back to `.builtInWideAngleCamera` on devices without TrueDepth. Camera
tuning (HDR + continuous AE/AWB/AF + 20 fps cap) and the in-flight gate
are both wired in.

```swift
// FaceTrustViewModel.swift
import AVFoundation
import Foundation
import Observation
import SwiftUI
import YEOFR

@Observable
final class FaceTrustViewModel:
    NSObject,
    YEOFRTrueDepthHandling,
    AVCaptureDataOutputSynchronizerDelegate
{
    /// Replace with the unlock code we issued you. Any non-empty string
    /// works on YEO-owned bundle IDs; non-YEO bundles need the real
    /// pilot code (see *Pilot access for non-YEO bundle IDs* above).
    private let pilotUnlockCode = "<contact-us-for-pilot-code>"

    let session = AVCaptureSession()

    /// Construct both at init time. Every public init requires
    /// `useCase` + `pilotUnlockCode`; `FaceTrustSession` reads both
    /// off the SDK instance so the fusion actor and the FR engine
    /// share state. There is no `.shared` singleton — instances are
    /// per camera-lifecycle and are not safe to reuse across
    /// reconfigurations.
    private let sdk: YEOFRSDK
    private let faceTrust: FaceTrustSession

    nonisolated private let captureQueue = DispatchQueue(label: "yeofr.capture")

    // YEOFRTrueDepthHandling requirements. videoOutput / depthDataOutput
    // are `var` per the protocol; the SDK's default
    // `handleDataOutputSynchronizer(_:didOutput:)` reads them via getter.
    var videoOutput = AVCaptureVideoDataOutput()
    var depthDataOutput = AVCaptureDepthDataOutput()
    var trueDepthState = YEOFRTrueDepthState()
    var trueDepthConsoleLog = false
    var faceLivenessDetector: YEOFaceLivenessDetector
    private(set) var depthEnabled = false

    override init() {
        // `.continuous` favours slow-revoke fusion — appropriate for
        // an ongoing trust check that should not flap on transient
        // dips. Use `.onboarding` for first-shot enrolment, or
        // `.authentication` for a discrete login event.
        let useCase: YEOUseCase = .continuous
        let sdk = YEOFRSDK(useCase: useCase, pilotUnlockCode: pilotUnlockCode)
        self.sdk = sdk
        self.faceTrust = FaceTrustSession(sdk: sdk)
        self.faceLivenessDetector = YEOFaceLivenessDetector(useCase: useCase)
        super.init()
    }

    /// Held strongly so the AVFoundation delegate weak-ref sticks.
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?

    var latestDetection: SDKFaceRecognitionResult?
    var latestEvaluation: FaceEvaluationResult?

    private var trustStreamTask: Task<Void, Never>?

    /// In-flight gate. Without it, 20+ fps spawns 20+ Tasks/sec each
    /// pinning a frame buffer; long sits OOM the process and CNN
    /// throughput collapses below frame rate (which suppresses the very
    /// liveness verdicts trust depends on). MainActor-only.
    /// Mirrors iosclient's FRSDKWrapper YWLI-1142 pattern.
    private var processing = false

    func start() async {
        guard await AVCaptureDevice.requestAccess(for: .video) else { return }

        depthEnabled = canUseTrueDepthCamera()  // protocol helper
        let deviceType: AVCaptureDevice.DeviceType =
            depthEnabled ? .builtInTrueDepthCamera : .builtInWideAngleCamera

        guard
            let camera = AVCaptureDevice.default(deviceType, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: camera)
        else { return }

        session.beginConfiguration()
        if session.canSetSessionPreset(.photo) { session.sessionPreset = .photo }
        configureForFaceCapture(camera)
        if session.canAddInput(input) { session.addInput(input) }

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCMPixelFormat_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        videoOutput.connection(with: .video)?.videoOrientation = .portrait

        if depthEnabled, session.canAddOutput(depthDataOutput) {
            session.addOutput(depthDataOutput)
            depthDataOutput.isFilteringEnabled = false
            if let conn = depthDataOutput.connection(with: .depthData) {
                conn.videoOrientation = .portrait
                conn.isEnabled = true
            }
            // Synchronise RGB + depth so the SDK's protocol extension
            // can analyse both for each frame.
            let sync = AVCaptureDataOutputSynchronizer(
                dataOutputs: [videoOutput, depthDataOutput]
            )
            sync.setDelegate(self, queue: captureQueue)
            outputSynchronizer = sync
        } else {
            depthEnabled = false  // depth refused — RGB-only fallback
        }

        session.commitConfiguration()

        // startRunning blocks; hop off main so SwiftUI stays responsive.
        let captureSession = session
        await Task.detached { captureSession.startRunning() }.value

        subscribeToTrustStream()
    }

    func stop() {
        trustStreamTask?.cancel()
        let captureSession = session
        Task.detached { captureSession.stopRunning() }
    }

    /// Synchronizer delegate — routes the synced video frame through the
    /// protocol's default impl, which calls captureOutput(...) below and
    /// analyses the depth map (eventually firing onDepthVerdict).
    nonisolated func dataOutputSynchronizer(
        _ synchronizer: AVCaptureDataOutputSynchronizer,
        didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection
    ) {
        handleDataOutputSynchronizer(synchronizer, didOutput: synchronizedDataCollection)
    }

    /// Forward depth verdicts into the trust session so the rescue
    /// evidence path can fire.
    nonisolated func onDepthVerdict(value: YEOFRDepthVerdict) {
        Task { [faceTrust] in await faceTrust.recordDepth(value) }
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        Task { @MainActor [weak self, faceTrust] in
            guard let self, !self.processing else { return }
            self.processing = true
            defer { self.processing = false }
            let frame = await faceTrust.processFrame(buffer: buffer)
            // `frame.detection` is the synchronous FR pass for this frame:
            //   .faceState / .detectedCount / .faceIDs / .faceRects / .framing
            // `frame.evaluation` is the latest fused trust state:
            //   .trusted / .livenessValue / .depthValue / .fusedConfidence
            self.latestDetection = frame.detection
            self.latestEvaluation = frame.evaluation
        }
    }

    private func subscribeToTrustStream() {
        trustStreamTask?.cancel()
        let stream = faceTrust
        trustStreamTask = Task { @MainActor [weak self] in
            for await result in await stream.faceTrustStream() {
                self?.latestEvaluation = result
            }
        }
    }

    /// Camera tuning. The CNN is tuned against this exact config; running
    /// with default-mode camera settings under-exposes faces enough that
    /// real users score below the spoof threshold (especially with
    /// glasses).
    private func configureForFaceCapture(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            // 20 fps cap. Matches iosclient and prevents the in-flight
            // gate from drowning at higher rates.
            let frameDuration = CMTime(value: 1, timescale: 20)
            device.activeVideoMinFrameDuration = frameDuration
            device.activeVideoMaxFrameDuration = frameDuration

            // HDR keeps detail in highlights/shadows so the CNN sees a
            // properly-exposed face.
            if device.activeFormat.isVideoHDRSupported {
                device.automaticallyAdjustsVideoHDREnabled = false
                device.isVideoHDREnabled = true
            }
            // Continuous AE/AWB/AF — the CNN was trained against streams
            // that re-meter as the user moves.
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
        } catch {
            // Lock failed — proceed with default device settings. CNN
            // behaviour will be degraded; surface this in your telemetry.
        }
    }
}
```

```swift
// CameraPreview.swift
import AVFoundation
import SwiftUI
import UIKit

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
```

```swift
// ContentView.swift — permission gate + minimal trust UI
import AVFoundation
import SwiftUI

struct ContentView: View {
    @State private var status = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        switch status {
        case .authorized:
            LiveTrustView()
        case .notDetermined:
            Button("Grant camera access") {
                Task {
                    _ = await AVCaptureDevice.requestAccess(for: .video)
                    status = AVCaptureDevice.authorizationStatus(for: .video)
                }
            }
            .buttonStyle(.borderedProminent)
        default:
            Text("Camera access denied — enable Camera in Settings.")
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

private struct LiveTrustView: View {
    @State private var viewModel = FaceTrustViewModel()

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.session).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                Text(viewModel.latestEvaluation?.trusted == true ? "TRUSTED" : "—")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(viewModel.latestEvaluation?.trusted == true ? .green : .red)
                Text(String(format: "fused %.2f", viewModel.latestEvaluation?.fusedConfidence ?? 0))
                Text("liveness: \(String(describing: viewModel.latestEvaluation?.livenessValue))")
                Text("depth: \(String(describing: viewModel.latestEvaluation?.depthValue))")
            }
            .font(.system(.footnote, design: .monospaced))
            .foregroundStyle(.white)
            .padding()
            .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            .padding()
        }
        .task { await viewModel.start() }
        .onDisappear { viewModel.stop() }
    }
}
```

Once the camera is up, point it at your face — `latestEvaluation.trusted`
flips true once FR finds an enrolled face, the liveness CNN scores it
genuine, and (on TrueDepth devices) the depth verdict is `.threeD`. See
[Enrolment and tracker persistence](#enrolment-and-tracker-persistence)
below for how to register a face so the FR side has something to match
against. For a worked enrolment-first sample with a guided UI, see
`CFRDemo` and iosclient's `YeoCameraViewController`.

> **Why all the wiring?** The view model is doing more than `processFrame`
> for a reason. `YEOFRTrueDepthHandling` adoption + the synchronizer
> unlock the rescue-evidence path so real users with glasses still verify
> as `trusted` (see [Why TrueDepth matters](#why-truedepth-matters)).
> `configureForFaceCapture` matches the camera config the CNN is tuned
> against — without it, real users get scored as spoof under default
> exposure. The `processing` in-flight gate prevents 20+ fps from piling
> tasks on the actor and starving the CNN. None of these are optional in
> practice.

---

## Enrolment and tracker persistence

YEOFR holds the enrolled face database in an internal *tracker*. Enrol
once, serialise the tracker, store it, and reload it on next launch.

```swift
// `sdk` is the YEOFRSDK instance you constructed at init time —
// e.g. the `sdk` property on FaceTrustViewModel from the hello-world
// above. There is no `.shared` singleton; every call goes through
// the instance you own.

// Enrol the currently-detected face under a stable face ID + name.
sdk.enroll(faceID: 1, name: "Alice", learnFromCurrentFrame: true)

// Plaintext path — useful for tests/demos.
let raw = sdk.faceRecognitionTrackerData()

// Encrypted path — recommended for at-rest storage. Routes through
// the cryptor the SDK was built with (`.plaintext` by default; pass
// a `YEOEncryption` value to the SDK init to pick AES-GCM or
// AES-CBC+HMAC). Returns a versioned blob ready to serialise.
let blob = try sdk.encryptedFaceRecognitionTrackerData()
try blob?.serialized().write(to: trackerURL, options: .atomic)

// Reload on next launch — replaces the in-memory tracker entirely.
// The SDK that performs the decrypt must hold the matching cryptor;
// peek at the blob's `algorithmID` before building the SDK if you
// want to support multiple modes side-by-side.
let parsed = try EncryptedBlob.parse(Data(contentsOf: trackerURL))
let rc = try sdk.loadTracker(from: parsed)
```

### Choosing a cryptor

Encryption mode is picked at SDK construction via the
`YEOEncryption` enum (`0.6.1+`). Three built-in modes plus a
`.custom` escape hatch:

| Mode | Algorithm ID | When to pick |
|---|---|---|
| `.plaintext` | `0x00` | Tests, demos, on-device-only material. Biometric data goes out as plaintext — this is a security choice. |
| `.aesGCM(keychainTag:)` | `0x01` | Greenfield consumers. CryptoKit AES-256-GCM keyed from a Keychain-resident 256-bit key generated on first use. Hardware AES on Apple Silicon; nonce is regenerated per encrypt. |
| `.aesCBCHMAC(aesKey:hmacKey:)` | `0x02` | Consumers that already speak AES-256-CBC + HMAC-SHA256 (Encrypt-then-MAC). Bit-compatible with iosclient's existing `Data.encryptAES_AE`. |
| `.custom(any Cryptor)` | consumer-defined (`≥ 0x80`) | HSM-backed cryptor, hybrid key sources, anything not covered by the built-ins. |

Pass the chosen mode to the throwing init:

```swift
// AES-256-GCM, Keychain-resident key (the recommended production path).
let sdk = try YEOFRSDK(
    useCase: .authentication,
    pilotUnlockCode: "...",
    encryption: .aesGCM(keychainTag: "com.example.app.frsdk.gcm")
)
```

For the CBC + HMAC variant you supply two raw 32-byte keys (typically
both minted via `KeychainKeyStore`):

```swift
let store = KeychainKeyStore()
let aes  = try store.loadOrGenerate(tag: "com.example.app.frsdk.cbc.aes",  sizeBytes: 32)
let hmac = try store.loadOrGenerate(tag: "com.example.app.frsdk.cbc.hmac", sizeBytes: 32)
let sdk = try YEOFRSDK(
    useCase: .authentication,
    pilotUnlockCode: "...",
    encryption: .aesCBCHMAC(aesKey: aes, hmacKey: hmac)
)
```

The existing non-throwing `init(useCase:pilotUnlockCode:)` is unchanged
— it stays as a zero-config plaintext path. Opt into encryption only
when you're ready to handle the throw.

### Wire format

`EncryptedBlob.serialized()` produces `[version(1)] [algorithmID(1)]
[payload…]`. The two-byte header is stable across cryptors so a reader
can route a blob to the right decrypt path *before* touching the
payload — useful when consumers migrate from one cryptor to another
and need the old data to keep loading. `EncryptedBlob.AlgorithmID`
exposes the reserved IDs (`0x00`/`0x01`/`0x02`) plus a
`customRangeStart = 0x80` boundary for consumer-defined cryptors.

### Compatibility code — persist this with every enrolment

```swift
let compat = YEOFRSDK.compatabilityCode  // e.g. "A"
```

Store `compat` next to the tracker blob. After a YEOFR upgrade, compare
the stored value to `YEOFRSDK.compatabilityCode` before calling
`loadTracker`. If the code has changed, the underlying recognition
vendor or template format has changed too — you must force the user to
re-enrol. Loading a tracker with a mismatched compatibility code will
produce undefined matching behaviour.

A complete load-with-recheck pattern using the encrypted path:

```swift
func loadTrackerIfPresent() {
    guard
        let savedCompat = try? String(contentsOf: compatURL, encoding: .utf8),
        let raw = try? Data(contentsOf: trackerURL)
    else { return }

    guard savedCompat == YEOFRSDK.compatabilityCode else {
        // Vendor / format changed since enrolment — wipe and force re-enrol.
        try? FileManager.default.removeItem(at: trackerURL)
        try? FileManager.default.removeItem(at: compatURL)
        return
    }

    do {
        let blob = try EncryptedBlob.parse(raw)
        _ = try sdk.loadTracker(from: blob)
    } catch {
        // Bad key, tampered ciphertext, or unknown version — treat as
        // unrecoverable and force re-enrol.
        try? FileManager.default.removeItem(at: trackerURL)
        try? FileManager.default.removeItem(at: compatURL)
    }
}
```

---

## Public API at a glance

| Symbol | Role |
|---|---|
| `YEOFRSDK(useCase:pilotUnlockCode:)` | FR engine entry point. Constructs a per-instance SDK; no shared singleton. Methods: `enroll(...)`, `detectFaces(...)`, tracker (de)serialisation, `compatabilityCode`. Throws form `init(useCase:pilotUnlockCode:encryption:)` adds encryption selection (0.6.1+). |
| `FaceTrustSession(sdk:)` | Per-camera-lifecycle fusion actor. Takes the `YEOFRSDK` you built; reads `useCase` + pilot code off it so they share FR state. `processFrame(buffer:)` per frame; `faceTrustStream()` for verdicts; `recordDepth(_:)` to feed depth verdicts. *(One-arg form since `0.6.2`; the prior three-arg `init(useCase:pilotUnlockCode:sdk:)` is removed.)* |
| `YEOFRTrueDepthHandling` | Protocol — adopt on your camera owner to opt in to TrueDepth depth fusion. Provides `handleDataOutputSynchronizer(...)` default impl + `canUseTrueDepthCamera()` helper. |
| `YEOFaceLivenessDetector(useCase:)` | Vision-based depth analyser used by the TrueDepth pipeline. Hand to `faceLivenessDetector` on the protocol. |
| `YEOUseCase` | Enum tuning the SDK for `.onboarding` (fast accept), `.authentication` (balanced), or `.continuous` (slow revoke). Required on every public init. |
| `SDKFaceRecognitionResult` | Per-frame FR output: `faceIDs`, `faceRects`, `framing`, `confidence`, `detectedCount`. |
| `FaceEvaluationResult` | Fused trust verdict: `trusted`, `livenessValue`, `depthValue`, `fusedConfidence`, `fusionTrace`. |
| `SpoofVerdict` | `.genuine(confidence: Float)`, `.spoof(confidence: Float, type: SpoofType)`, `.invalid(reason: InvalidFrameReason)`. |
| `SpoofType` | Spoof classification carried by `SpoofVerdict.spoof`: `.photo`, `.screen`, `.video`, `.mask`, `.unknown`. |
| `YEOFRDepthVerdict` | `.threeD(detail)`, `.flat(detail)`, `.notDetermined(reason, detail)`. |
| `Cryptor` / `EncryptedBlob` / `CryptorError` | Authenticated-encryption protocol + versioned envelope used by `encryptedFaceRecognitionTrackerData()` and `loadTracker(from: EncryptedBlob)`. |
| `PassthroughCryptor`, `AESGCMCryptor`, `AESCBCHMACCryptor` | Built-in cryptors. `AESGCMCryptor.withKeychainKey(tag:)` mints + persists a 32-byte key on first call. |
| `KeychainKeyStore` | `loadOrGenerate(tag:sizeBytes:)` — hybrid key vault used by the AES cryptors. |
| `YEOEncryption` | Public selector passed to `YEOFRSDK(useCase:pilotUnlockCode:encryption:)`. Cases: `.plaintext`, `.aesGCM(keychainTag:)`, `.aesCBCHMAC(aesKey:hmacKey:)`, `.custom(any Cryptor)`. |

For full reference, see the DocC archive in the YEOFRSDK source repo.

> **Caveat — face counts.** `FaceEvaluationResult` ships with `numFacesSeen`
> and `numFacesRecognised` fields, but `FaceTrustSession.processFrame` does
> not currently populate them — they read 0 forever. For per-frame face
> counts, read `frame.detection.faceRects.count` (seen) and the count of
> non-nil values in `frame.detection.faceIDs` (recognised) instead.

