//
//  BreakdownView.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-21.
//

//this is a culimination of the apps moving parts - no logic actually exists here

// For notes, heades into notes manger
// for recommendations, heading into recommendation manger 

import SwiftUI
import AVKit
import Vision

struct BreakdownView: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss

    // video state plater
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0.001
    @State private var timeObserverToken: Any?
    
    // Pose Processing & Overlay Toggle
    @State private var poseViewModel = PoseEstimationViewModel()
    @State private var showPoseOverlay: Bool = true
    
    // Timeline Scroll Physics
    @State private var isScrubbing = false
    @State private var lastDragTranslation: CGFloat = 0
    private let pointsPerSecond: CGFloat = 60.0

    // Bottom Sheet Tab Selection: 0 = Notes, 1 = Analysis, 2 = Recommendations
    @State private var selectedTab: Int = 0

    // Notes Manager
    @StateObject private var notesManager = NotesManager()
    
    // Session Manager & Persistence
    @StateObject private var sessionStore = SessionStore()
    @State private var isSaved: Bool = false

    var body: some View {
        ZStack {
            // load the backgroun image if there is not background
            BackgroundView(imageName: "background_splash")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - 1. Video Player Container with Pose Overlay
                ZStack(alignment: .bottom) {
                    ZStack {
                        if let player = player {
                            VideoPlayerView(player: player)
                                .frame(maxWidth: .infinity)
                                .frame(height: 280)
                                .clipped()
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        } else {
                            Rectangle()
                                .fill(Color.black.opacity(0.5))
                                .background(.ultraThinMaterial)
                                .frame(height: 280)
                                .overlay(ProgressView().tint(.white))
                        }

                    
                        if showPoseOverlay, let activeJoints = poseViewModel.pose(at: currentTime) {
                            PoseOverlayView(
                                joints: activeJoints,
                                connections: poseViewModel.bodyConnections
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                            .allowsHitTesting(false)
                        }

                        // Vision Processing Loader Overlay
                        if poseViewModel.isProcessing {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .tint(.white)
                                Text("Analyzing Pose Keyframes...")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }

                    /// Video Hud Overlay
                    HStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Button {
                                togglePlayPause()
                            } label: {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            Text("\(formatTimecode(currentTime))/\(formatTimecode(duration))")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)

                        Spacer()

                        // Save Session Button
                        Button {
                            let mappedNotes = notesManager.notes.map { note in
                                SavedNote(timestamp: note.timestamp, text: note.text)
                            }
                            
                            sessionStore.saveSession(
                                from: videoURL,
                                actionTitle: poseViewModel.predictedAction,
                                confidence: poseViewModel.actionConfidence,
                                notes: mappedNotes
                            )
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isSaved = true
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text(isSaved ? "Saved" : "Save")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(isSaved ? .green : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                        .disabled(isSaved)

                        // Viewfinder Button
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPoseOverlay.toggle()
                            }
                        } label: {
                            Image(systemName: showPoseOverlay ? "viewfinder.circle.fill" : "viewfinder")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(showPoseOverlay ? .green : .white)
                                .frame(width: 34, height: 34)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(12)
                }

                /// Scrollabele Ttile text
                GeometryReader { geometry in
                    let centerAnchor = geometry.size.width / 2
                    let totalTimelineWidth = max(geometry.size.width, CGFloat(duration) * pointsPerSecond)
                    let currentOffset = centerAnchor - (CGFloat(currentTime) * pointsPerSecond)

                    ZStack(alignment: .leading) {
                        // Glassy track background
                        Rectangle()
                            .fill(.ultraThinMaterial)

                        // Layout Sandbox: Overlay prevents totalTimelineWidth from causing horizontal frame expansion
                        Color.clear
                            .overlay(
                                HStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 1.0, green: 0.5, blue: 0.55).opacity(0.8))
                                        .frame(width: totalTimelineWidth * 0.20)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 0.35, green: 0.65, blue: 0.95).opacity(0.8))
                                        .frame(width: totalTimelineWidth * 0.42)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.4))
                                        .frame(width: totalTimelineWidth * 0.10)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 1.0, green: 0.5, blue: 0.55).opacity(0.8))
                                        .frame(width: totalTimelineWidth * 0.22)
                                }
                                .padding(.vertical, 6)
                                .frame(width: totalTimelineWidth, alignment: .leading)
                                .offset(x: currentOffset),
                                alignment: .leading
                            )
                            .clipped()

                        // Playhead indicator
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white)
                            .frame(width: 4, height: 46)
                            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 0)
                            .position(x: centerAnchor, y: 26)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                if !isScrubbing {
                                    isScrubbing = true
                                    player?.pause()
                                    isPlaying = false
                                    lastDragTranslation = value.translation.width
                                }

                                let deltaX = value.translation.width - lastDragTranslation
                                lastDragTranslation = value.translation.width

                                let deltaTime = -Double(deltaX / pointsPerSecond)
                                let newTime = min(max(currentTime + deltaTime, 0), duration)
                                
                                currentTime = newTime
                                seekToTime(newTime)
                            }
                            .onEnded { _ in
                                isScrubbing = false
                                lastDragTranslation = 0
                            }
                    )
                }
                .frame(height: 52)
                .overlay(
                    Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.1)), alignment: .top
                )

                // MARK: - 3. Bottom Sheet & Controls Area
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ActionButton(icon: "pencil", isSelected: selectedTab == 0) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 0 }
                        }

                        ActionButton(icon: "cylinder.split.1x2", isSelected: selectedTab == 1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 1 }
                        }

                        ActionButton(icon: "arrow.right.square", isSelected: selectedTab == 2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = 2 }
                        }
                    }
                    .padding(.top, 20)

                    // Glassy Inner Content Container
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tabTitle(for: selectedTab))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        ScrollView(.vertical, showsIndicators: false) {
                            tabContentView(for: selectedTab)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32))
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupPlayer()
            Task {
                await poseViewModel.processRecordedVideo(at: videoURL)
            }
        }
        .onDisappear {
            cleanUpPlayer()
        }
    }

    // MARK: - AVPlayer Controls
    private func setupPlayer() {
        guard player == nil else { return }
        let newPlayer = AVPlayer(url: videoURL)
        self.player = newPlayer

        Task {
            if let item = newPlayer.currentItem {
                do {
                    let durationTime = try await item.asset.load(.duration)
                    let totalSeconds = CMTimeGetSeconds(durationTime)
                    if !totalSeconds.isNaN && totalSeconds > 0 {
                        await MainActor.run {
                            self.duration = totalSeconds
                        }
                    }
                } catch {
                    print("Error loading video duration: \(error)")
                }
            }
        }

        let interval = CMTime(value: 1, timescale: 30)
        timeObserverToken = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            guard !isScrubbing else { return }
            let seconds = CMTimeGetSeconds(time)
            if !seconds.isNaN {
                self.currentTime = seconds
            }

            if seconds >= self.duration - 0.05 && self.duration > 0.1 {
                self.isPlaying = false
                self.player?.pause()
            }
        }
    }

    private func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            if currentTime >= duration - 0.05 {
                seekToTime(0)
            }
            player.play()
            isPlaying = true
        }
    }

    private func seekToTime(_ seconds: Double) {
        guard let player = player else { return }
        let targetCMTime = CMTime(seconds: seconds, preferredTimescale: 600)
        player.seek(to: targetCMTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func cleanUpPlayer() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        player?.pause()
        player = nil
    }

    private func formatTimecode(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    // MARK: - Dynamic UI Helpers

    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Notes"
        case 1: return "AI Analysis"
        case 2: return "Recommendations"
        default: return ""
        }
    }

    @ViewBuilder
    private func tabContentView(for index: Int) -> some View {
        switch index {
        case 0:
            NotesTabView(
                notesManager: notesManager,
                currentTime: currentTime,
                seekToTime: { targetTime in
                    currentTime = targetTime
                    seekToTime(targetTime)
                }
            )
                
        case 1:
            if poseViewModel.isProcessing {
                HStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text("Processing model inference...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(poseViewModel.predictedAction)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(actionColor)
                    
                    Text(String(format: "Confidence: %.1f%%", poseViewModel.actionConfidence * 100))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 4)
            }
            
        case 2:
            RecommendationsTabView()
                
        default:
            EmptyView()
        }
    }
    
    private var actionColor: Color {
        if poseViewModel.actionConfidence > 0.80 {
            return .green
        } else if poseViewModel.actionConfidence > 0.50 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Action Button Component
private struct ActionButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.white : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? .white.opacity(0.2) : .clear, radius: 8, x: 0, y: 0)
        }
    }
}

// MARK: - UIViewRepresentable Video Layer
struct VideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }

    class PlayerUIView: UIView {
        override class var layerClass: AnyClass {
            AVPlayerLayer.self
        }

        var playerLayer: AVPlayerLayer {
            return layer as! AVPlayerLayer
        }
    }
}
