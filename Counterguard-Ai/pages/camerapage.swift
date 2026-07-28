import SwiftUI
import AVFoundation
import AVKit

// MARK: - Capture Mode Enum
enum CameraCaptureMode {
    case photo, video
}

// MARK: - Main Camera Page View
struct CameraPage: View {
    @StateObject private var cameraManager = CameraManger()
    @State private var captureMode: CameraCaptureMode = .video
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background fallback while camera loads or if access is denied
            BackgroundView(imageName: "background_splash")
            
            if cameraManager.authorizationStatus == .authorized {
                CameraPreview(session: cameraManager.session)
                    .ignoresSafeArea()
                
                VStack {
                    // MARK: - Top Navigation
                    HStack {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    Spacer()
                    
                    // MARK: - Bottom Controls
                    VStack(spacing: 16) {
                        // Floating Recording Indicator
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.red)
                                .frame(width: 10, height: 10)
                            
                            Text("Recording")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .opacity(cameraManager.isRecording ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: cameraManager.isRecording)
                        
                        // Mode Switcher (Photo / Video Segmented Control)
                        Picker("Mode", selection: $captureMode) {
                            Text("Photo").tag(CameraCaptureMode.photo)
                            Text("Video").tag(CameraCaptureMode.video)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                        
                        // Shutter / Capture Buttons
                        if captureMode == .photo {
                            Button {
                                cameraManager.capturePhoto()
                            } label: {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 3)
                                    .frame(width: 70, height: 70)
                                    .overlay {
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 60, height: 60)
                                    }
                            }
                        } else {
                            // Video Shutter Button
                            Button {
                                if cameraManager.isRecording {
                                    cameraManager.stopRecoding()
                                } else {
                                    cameraManager.startRecording()
                                }
                            } label: {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 3)
                                    .frame(width: 70, height: 70)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: cameraManager.isRecording ? 6 : 30)
                                            .fill(.red)
                                            .frame(
                                                width: cameraManager.isRecording ? 30 : 60,
                                                height: cameraManager.isRecording ? 30 : 60
                                            )
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: cameraManager.isRecording)
                                    }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .sheet(item: $cameraManager.capturedImage) { image in
                    PhotoPreviewView(item: image, onDismiss: { cameraManager.capturedImage = nil })
                }
                .sheet(item: Binding(
                    get: { cameraManager.recordedVideoURL.map { IdentifiableURL(url: $0) } },
                    set: { cameraManager.recordedVideoURL = $0?.url }
                )) { item in
                    VideoPreview(videoURL: item.url)
                }
                
            } else {
                // UI when camera access is missing/denied
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .padding(.bottom, 5)
                    
                    Text("Camera Access Required")
                        .foregroundColor(.white)
                    
                    if cameraManager.authorizationStatus == .denied {
                        Text("Please Allow Camera Access in Settings")
                            .foregroundColor(.white)
                            .padding(.bottom)
                        
                        Button("Open Settings") {
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(15)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            cameraManager.checkAuthrization()
        }
    }
}

// MARK: - Identifiable URL Helper
struct IdentifiableURL: Identifiable {
    var id = UUID()
    let url: URL
}
