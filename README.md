# Counterguard

**Measure the action. Master the insight.**

Counterguard is an iOS app that helps martial artists (starting with Taekwondo) understand their own sparring footage — not just what happened, but why. It pairs on-device pose tracking with a place to actually reflect on what you're seeing, instead of leaving your training videos to rot in your camera roll.

[![Counterguard demo](https://img.youtube.com/vi/0lrV_NnlVG4/maxresdefault.jpg)](https://youtube.com/shorts/0lrV_NnlVG4)

## Why

Coaches cost thousands and demand a time commitment most athletes can't afford. Existing sports AI tools (HomeCourt, SwingVision, etc.) spit out skeletal angles and counts, but nothing that helps you decipher your own positioning, timing, or guard mistakes. Counterguard fills that gap.

## How it works

- **Camera capture** — Custom low-latency capture pipeline built on `AVFoundation` (`CameraManager`)
- **Pose estimation** — Apple's Vision framework (`VNHumanBodyPoseObservation`) tracks body joints frame by frame (`PoseEstimationViewModel`, `FramePoseData`)
- **Skeleton overlay** — Real-time `Canvas`-based rendering of the tracked skeleton over the live feed (`PoseOverlayView`)
- **Feature extraction** — `PoseFeatureExtractor.swift` converts raw joint data into a numerical feature array for the ML model
- **Model** — Trained in PyTorch on martial-arts-specific datasets, exported via `coremltools` to run live, fully on-device — no server round trip

## Tech stack

- Swift / SwiftUI
- AVFoundation (camera pipeline)
- Vision framework (pose estimation)
- PyTorch → Core ML (via coremltools)

## Status

Actively in development. Core capture, pose tracking, and overlay rendering are working; feature extraction and model integration are in progress.

## Roadmap

- Finish `PoseFeatureExtractor.swift` → feed into trained Core ML model
- Timeline UI for tagging keyframes with reflection notes
- Workout planner built around video evidence
- Expand beyond Taekwondo to other striking/combat sports
