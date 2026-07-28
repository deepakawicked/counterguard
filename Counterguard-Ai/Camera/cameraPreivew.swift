//
//  cameraPreivew.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-19.
//


import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable { // needs build functon
    
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView { //creates the intial view
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        
        context.coordinator.previewLayer = previewLayer
        
        return view
        
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { //update when the swift ui changes 
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
                
            }
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer : AVCaptureVideoPreviewLayer?
    }
}
