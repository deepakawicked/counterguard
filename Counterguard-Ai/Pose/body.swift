//
//  body.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-20.
//

import SwiftUI
import Vision
import AVFoundation
import Observation


//draws a stick figure skeleton otop of the video feed 
struct BodyConnection: Identifiable {
    let id = UUID()
    let from: VNHumanBodyPoseObservation.JointName
    let to: VNHumanBodyPoseObservation.JointName
}

/// Holds raw Vision joint data extracted from a single video frame
struct FramePoseData: Identifiable {
    let id = UUID()
    let timeStamp: CMTime
    let joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
}
