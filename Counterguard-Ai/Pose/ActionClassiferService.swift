//
//  ActionClassiferService.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-22.
//


import Foundation
import CoreML

//ML model (poseClasificer) only speaks in the 57 point array system, aka math
// The service here takes the path, takes the model and feeds into clasfifcaiton model
// returns the string into the UI

//this file does not call the vision 

struct ClassificationResult { // this is the service returns for classfication
    let label: String
    let confidence: Double
}

actor ActionClassifierService {
    // Automatically generated Swift class from your PoseClassifier.mlmodel
    private let model: PoseClassifier?
    
    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        self.model = try? PoseClassifier(configuration: config)
    }
    
    /// Classifies a single frame of 57 features
    private func classifyFrame(features: [Float]) throws -> ClassificationResult? {
        guard let model = model else { return nil }
        
        let poseFeature = PoseFeature()
        let inputMultiArray = try poseFeature.createSingleFrameMultiArray(from: features)
        
        // Input matching python `input_features="pose_features"`
        let input = PoseClassifierInput(pose_features: inputMultiArray)
        let output = try model.prediction(input: input)
        //this is where we acthally contact thd file
        let label = output.label
        // Double-check if your model output dictionary is named classProbability or labelProbability
        let confidence = output.classProbability[label] ?? 0.0
        
        return ClassificationResult(label: label, confidence: confidence)
    }
    
    /// Classifies the entire video sequence frame-by-frame and returns the majority vote
    func classifyVideo(sequence: [[Float]]) throws -> ClassificationResult? {
        var counts: [String: Int] = [:]
        var totalConfidence: [String: Double] = [:]
        
        for frameFeatures in sequence {
            if let result = try classifyFrame(features: frameFeatures) {
                counts[result.label, default: 0] += 1
                totalConfidence[result.label, default: 0.0] += result.confidence
            }
        }
        
        // Find the most frequent label across all frames
        guard let bestLabel = counts.max(by: { $0.value < $1.value })?.key,
              let maxCount = counts[bestLabel],
              let confSum = totalConfidence[bestLabel] else {
            return nil
        }
        
        let averageConfidence = confSum / Double(maxCount)
        return ClassificationResult(label: bestLabel, confidence: averageConfidence)
    }
}
