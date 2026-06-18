# FRPilot — minimal YEOFR consumer tutorial

The smallest working example of the YEOFR happy path: **enrol one face, then run
live recognition that shows TRUSTED / NOT TRUSTED.** It is a deliberately tiny
counterpart to the full `CFRDemo` — read it to learn the API, then build the
features you need.

## The happy path

The whole integration is the SDK's `FaceTrustService` — a turnkey object that
owns the engine, the camera, the fused-trust pipeline (face recognition +
liveness CNN + TrueDepth), tracker persistence, and the identity gate. You wire
two streams and render them:

```swift
let service = FaceTrustService(pilotUnlockCode: "…")   // pilot code unlocks a non-YEO bundle id
// attach `service.previewSession` to an AVCaptureVideoPreviewLayer
try await service.start()                              // warm-up, restore enrolment, arm gate, start camera

for await update in service.updates() {                // live trust verdict, per frame
    // update.status        → .noFace / .badFraming / .notTrusted / .trusted
    // update.matchedName    → who the tracker named (when trusted)
    // update.livenessGenuine / .depthIsThreeD → the contributing signals
}

for await step in service.enroll(name: "Alice") {      // guided capture; persists + re-arms the gate
    // step.prompt ("Face the camera" / "Hold steady"), step.poseProgress, step.phase
}
```

The **trust decision is the SDK's** — `update.status == .trusted` already fuses
face recognition, the liveness CNN, and TrueDepth, with framing gating applied.
The consumer never picks a similarity threshold (that lives in the SDK's
recognition-floor profile) and never touches the identity gate, the camera
loops, or the tracker file — `FaceTrustService` owns all of it.

> **Why a single front pose is enough.** `enroll(name:)` defaults to a
> `[.front]` gallery walk. The walk banks several *graded* templates (unlike the
> deprecated single-shot `sdk.enroll`, which teaches one appearance and lets a
> colleague clear the gate), and the SDK's identity gate only trusts a face the
> tracker names as the enrolled identity — so one good front capture already
> separates the enrolled user from other people. Pass
> `poses: PoseTarget.lightingAwareGallerySequence` to capture off-axis poses +
> a lighting pass; that improves *recall* as the user turns, but isn't needed to
> reject a different person.

> **Why `FaceTrustService`, not the low-level `sdk.detectFaces(params:)`?** The
> raw path hands you an `ImageFrameParameters` whose pixel-buffer copy the
> *caller* must free (easy to leak — it OOMs in under a minute), and leaves you
> to wire the camera, the depth pipeline, the warm-up ordering, tracker
> persistence, and — critically — the FR **identity gate**. Forgetting the gate
> silently collapses trust to liveness + depth, so any live 3D face (a
> colleague) passes. `FaceTrustService` does all of that for you.

## Files (read in this order)

| File | What it teaches |
|------|-----------------|
| `FRPilot/PilotViewModel.swift` | The entire SDK integration: construct `FaceTrustService`, forward its `updates()` and `enroll()` streams into `@Observable` state. ~30 lines of wiring. |
| `FRPilot/TrustPolicy.swift` | The view-facing `TrustVerdict` enum — no `import YEOFR`, so the SwiftUI views stay off the device-only binary and preview on the simulator. |
| `FRPilot/CameraPreview.swift` | A 1-screen `AVCaptureVideoPreviewLayer` wrapper over `service.previewSession`. |
| `FRPilot/EnrolView.swift` / `RecogniseView.swift` | Two thin screens: enrol on a valid frame, render the live verdict + liveness/depth signals. |
| `FRPilot/ContentView.swift` | Navigation root; owns the view model and the camera lifecycle. |

## Why the display logic is decoupled

The YEOFR binary is **arm64 device-only** — anything that links it cannot run on
the simulator. So the views read a plain `TrustVerdict` (no SDK import) that
`PilotViewModel` maps from the SDK's `FaceTrustUpdate`. The framing→display
gating and the signal tri-states now live *inside the SDK* (`FaceTrustService`,
covered by the SDK's own `FaceTrustUpdateMappingTests`), so the consumer carries
no decision logic to test — keeping the app a thin, device-validated shell.

## Build & run

- **App (real device required):** select an iPhone and Run. Type a name →
  **Enrol Face** → tap **Enrol** and hold still facing the camera → **Live
  Recognition** shows **TRUSTED — \<name\>**. Relaunch: the enrolment persists.

This example lives inside the `YEOFR-SPM` repo and references the package by
relative path (`../..`), so it builds against the package it ships with. In your
own app, add the package by URL instead:
`https://github.com/YEOMessaging/YEOFR-SPM`.

## What's intentionally left out

The enrolment **verification walk** ("walk 2 of 2" — FRR measurement + gap
patching), lighting enhancement, gallery import/export, recordings, compliance
toggles, multi-identity, and encryption. (The gallery-walk enrolment, liveness,
and TrueDepth *are* included — graded multi-template capture and the fused
verdict are what make recognition work.) See `CFRDemo` for the rest.
