//
//  PoseFeature.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-22.
//

import Vision
import Foundation
import CoreML

struct PoseFeature {
    
    // Updated to perfectly match the Python training script's joint_list array order
    static let jointOrder: [VNHumanBodyPoseObservation.JointName] = [
        .nose,
        .neck,
        .rightShoulder,
        .rightElbow,
        .rightWrist,
        .leftShoulder,
        .leftElbow,
        .leftWrist,
        .rightHip,
        .rightKnee,
        .rightAnkle,
        .leftHip,
        .leftKnee,
        .leftAnkle,
        .rightEye,
        .leftEye,
        .rightEar,
        .leftEar,
        .root
    ]
    
    static let values = 3 // value per joint: x, y, confidence
    
    static var featureLength: Int {
        jointOrder.count * values
    }
    
    func extractFeatures(from frame: FramePoseData) -> [Float] {
        var features: [Float] = []
        features.reserveCapacity(Self.featureLength)
        
        for jointName in Self.jointOrder {
            if let joint = frame.joints[jointName] {
                features.append(Float(joint.location.x))
                // Invert Y axis to match MediaPipe (top-left origin)
                features.append(1.0 - Float(joint.location.y))
                features.append(Float(joint.confidence))
            } else {
                features.append(0.0)
                features.append(0.0)
                features.append(0.0)
            }
        }
        return features
    }
    
    func extractNormalizedFeatures(from frame: FramePoseData) -> [Float] {
        guard let rootPoint = frame.joints[.root] ?? frame.joints[.neck] else {
            return extractFeatures(from: frame)
        }

        let rootX = Float(rootPoint.location.x)
        // Invert Root Y axis
        let rootY = 1.0 - Float(rootPoint.location.y)

        // Torso scale reference (Left Shoulder to Right Hip)
        let bodyScale: Float = {
            guard let leftShoulder = frame.joints[.leftShoulder],
                  let rightHip = frame.joints[.rightHip] else {
                return 1.0
            }
            let dx = Float(leftShoulder.location.x) - Float(rightHip.location.x)
            // Apply Y inversion to distance calculation
            let dy = (1.0 - Float(leftShoulder.location.y)) - (1.0 - Float(rightHip.location.y))
            let distance = sqrt(dx * dx + dy * dy)
            return distance > 0.0001 ? distance : 1.0
        }()

        var features: [Float] = []
        features.reserveCapacity(Self.featureLength)

        for jointName in Self.jointOrder {
            if let joint = frame.joints[jointName] {
                // Invert Y axis to match MediaPipe (top-left origin)
                let invertedY = 1.0 - Float(joint.location.y)
                
                let normalizedX = (Float(joint.location.x) - rootX) / bodyScale
                let normalizedY = (invertedY - rootY) / bodyScale
                
                features.append(normalizedX)
                features.append(normalizedY)
                features.append(Float(joint.confidence))
            } else {
                features.append(0.0)
                features.append(0.0)
                features.append(0.0)
            }
        }

        return features
    }
    
    func extractSequence(
        from frames: [FramePoseData],
        normalized: Bool = true
    ) -> [[Float]] {
        frames.map { frame in
            normalized ? extractNormalizedFeatures(from: frame) : extractFeatures(from: frame)
        }
    }
}

extension PoseFeature {
    /// Converts a single frame's features (57 floats) into a 1D MLMultiArray.
    func createSingleFrameMultiArray(from features: [Float]) throws -> MLMultiArray {
        let multiArray = try MLMultiArray(shape: [NSNumber(value: features.count)], dataType: .double)
        
        for (index, value) in features.enumerated() {
            multiArray[index] = NSNumber(value: Double(value))
        }
        
        return multiArray
    }
}
