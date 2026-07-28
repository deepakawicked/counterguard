//
//  PoseEstimationViewModel.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-22.
//


//connects ever sngle piece together - takes the raw ivdoe url, reads it frame by frames and prepares the output so it can run over time
import SwiftUI
import Vision
import AVFoundation
import Observation

@Observable
class PoseEstimationViewModel {
    var isProcessing: Bool = false
    var recordedFramePoses: [FramePoseData] = []
    var keyFrameJoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    var bodyConnections: [BodyConnection] = []
    
    // Core ML Outputs
    var predictedAction: String = "Analyzing..."
    var actionConfidence: Double = 0.0
    
    private let featureExtractor = PoseFeature()
    private let classifier = ActionClassifierService()
    
    init() {
        setupBodyConnections()
    }
    
    private func setupBodyConnections() { //setup the body connections, to draw a peerosn over
        bodyConnections = [
            BodyConnection(from: .nose, to: .neck),
            BodyConnection(from: .neck, to: .rightShoulder),
            BodyConnection(from: .neck, to: .leftShoulder),
            BodyConnection(from: .rightShoulder, to: .rightHip),
            BodyConnection(from: .leftShoulder, to: .leftHip),
            BodyConnection(from: .rightHip, to: .leftHip),
            BodyConnection(from: .rightShoulder, to: .rightElbow),
            BodyConnection(from: .rightElbow, to: .rightWrist),
            BodyConnection(from: .leftShoulder, to: .leftElbow),
            BodyConnection(from: .leftElbow, to: .leftWrist),
            BodyConnection(from: .rightHip, to: .rightKnee),
            BodyConnection(from: .rightKnee, to: .rightAnkle),
            BodyConnection(from: .leftHip, to: .leftKnee),
            BodyConnection(from: .leftKnee, to: .leftAnkle)
        ]
    }
    
    func processRecordedVideo(at videoURL: URL) async {
        await MainActor.run {
            self.isProcessing = true
            self.recordedFramePoses.removeAll()
            self.keyFrameJoints.removeAll()
            self.predictedAction = "Analyzing..."
            self.actionConfidence = 0.0
        }
        
        //uses avasset reader to rip the video into frames and use is as raw pixel buffers 
        let asset = AVAsset(url: videoURL)
        guard let track = try? await asset.loadTracks(withMediaType: .video).first,
              let reader = try? AVAssetReader(asset: asset) else {
            await MainActor.run { self.isProcessing = false }
            return
        }
        
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        reader.add(trackOutput)
        reader.startReading()
        
        //the vision pose library
        let poseRequest = VNDetectHumanBodyPoseRequest()
        var extractedPoses: [FramePoseData] = []
        
        while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
            let timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            
            do {
                try handler.perform([poseRequest])
                if let observation = poseRequest.results?.first {
                    let recognizedPoints = try observation.recognizedPoints(.all) // try to recognzie points
                    extractedPoses.append(FramePoseData(timeStamp: timeStamp, joints: recognizedPoints)) //extend poses into a timestamp so they can be played back
                }
            } catch {
                print("Vision extraction error: \(error.localizedDescription)")
            }
        }
        
        // Extract 57 normalized features per frame
        let featureSequence = featureExtractor.extractSequence(from: extractedPoses, normalized: true)
        
        // Pass sequence to Core ML ActionClassifierService
        let classificationResult = try? await classifier.classifyVideo(sequence: featureSequence)
        
        await MainActor.run {
            self.recordedFramePoses = extractedPoses
            
            if let bestFrame = extractedPoses.first(where: { $0.joints.count >= 10 }) {
                var previewPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
                for (joint, point) in bestFrame.joints where point.confidence > 0.3 {
                    previewPoints[joint] = point.location
                }
                self.keyFrameJoints = previewPoints
            }
            
            if let result = classificationResult {
                self.predictedAction = result.label
                self.actionConfidence = result.confidence
            } else {
                self.predictedAction = "No Action Detected"
                self.actionConfidence = 0.0
            }
            
            self.isProcessing = false
        }
    }
}

extension PoseEstimationViewModel {
    /// Retrieves the pose joints closest to the given video time (in seconds)
    func pose(at currentTimeSeconds: Double) -> [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]? {
        guard !recordedFramePoses.isEmpty else { return nil }
        
        // Find the frame closest to the requested timestamp
        let closestFrame = recordedFramePoses.min(by: {
            abs($0.timeStamp.seconds - currentTimeSeconds) < abs($1.timeStamp.seconds - currentTimeSeconds)
        })
        
        // Return joints if the frame is within 0.2s of current playback
        if let frame = closestFrame, abs(frame.timeStamp.seconds - currentTimeSeconds) < 0.2 {
            return frame.joints
        }
        
        return nil
    }
}
