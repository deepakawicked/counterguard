import AVFoundation
import SwiftUI
import Combine

// FIX 1: Added AVCapturePhotoCaptureDelegate here so 'self' can act as the camera delegate
class CameraManger: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        if let error = error  {
            print("Video recording error \(error.localizedDescription)")
            return
        }
        
        DispatchQueue.main.async {
            [weak self] in
            self?.recordedVideoURL = outputFileURL
        }
        
        
    }
    
    
    // SwiftUI communication
    @Published var capturedImage: IdentifiableImage?
    @Published var isSessionRunning = false // Tracking if the camera is running
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined // Privacy check
    @Published var isRecording = false;
    @Published var recordedVideoURL: URL?
    
    private var outputURL: URL?
    // AVFoundation components
    let session = AVCaptureSession()
    
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureMovieFileOutput()
    private var currentInput: AVCaptureDeviceInput?
    
    private let sessionQueue = DispatchQueue(label: "com.customcamera.sessionQueue")
    
    override init() {
        super.init()
    }
    
    // Check and permissions
    func checkAuthrization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authorizationStatus = .authorized
            setupSession()
            
        case .notDetermined:
            authorizationStatus = .notDetermined
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        self?.setupSession()
                    }
                }
            }
            
        case .denied, .restricted:
            authorizationStatus = .denied
            
        @unknown default:
            authorizationStatus = .denied
        }
    }
    
    // Configuring the AVSetup
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            
            // NOTE: Changed to .builtInWideAngleCamera so it successfully runs on ALL devices and the Xcode Simulator
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                print("Failed to access camera")
                self.session.commitConfiguration()
                return
            }
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.currentInput = input
            }
            
            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                
                if let maxDimensions = camera.activeFormat.supportedMaxPhotoDimensions.last {
                    self.photoOutput.maxPhotoDimensions = maxDimensions
                }
                self.photoOutput.maxPhotoQualityPrioritization = .quality
            }
            
            //add video output
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
                
            }
            
            //microphone output for video uputp
            
            if let microphone = AVCaptureDevice.default(for: .audio), let audioInput = try? AVCaptureDeviceInput(device:microphone),
               
                self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
            }
            
            self.session.commitConfiguration() // Apply changes
            
            // Start the capture runtime
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // FIX 2: Corrected class name to AVCapturePhotoSettings
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            
            // FIX 3: Replaced the deprecated high-resolution check with modern iOS 16+ dimensions
            settings.maxPhotoDimensions = self.photoOutput.maxPhotoDimensions
            
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    // Delegate method to capture and process the image data stream
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Photo Capture Error: \(error.localizedDescription)")
            return
        }
        
        // Extract image data
        guard let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData) else {
            print("Failed to convert photo to image")
            return
        }
        
        // Update UI on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = IdentifiableImage(image: uiImage)
        }
    }
    
    func startRecording() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            
            self.outputURL = tempURL
            
            // Fix 1: Changed 'connect' to 'connection'
            if let connection = self.videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }
            
            // Fix 2: Kept inside sessionQueue.async closure so tempURL remains in scope
            self.videoOutput.startRecording(to: tempURL, recordingDelegate: self)
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
        }
    }
    
    
    func stopRecoding() {
        sessionQueue.async {
            [weak self] in
            self?.videoOutput.stopRecording()
            DispatchQueue.main.async {
                self?.isRecording = false
            }
            
        }
    }
}


struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
