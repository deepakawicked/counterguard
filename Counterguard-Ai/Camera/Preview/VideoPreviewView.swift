//
//  VideoPreviewView.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-20.
//

import SwiftUI
import AVKit

struct VideoPreview: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    
    @State private var player: AVPlayer?
    @State private var navigateToBreakdown = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Video Player
                if let player = player {
                    VideoPlayer(player: player)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else {
                    ProgressView("Loading Video...")
                }

                // Action Controls
                HStack(spacing: 16) {
                    Button(role: .destructive) {
                        dismiss() // Retake / Back to Camera
                    } label: {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        // Pause current preview before pushing to BreakdownView
                        player?.pause()
                        navigateToBreakdown = true
                    } label: {
                        Label("Analyze", systemImage: "bolt.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if player == nil {
                    player = AVPlayer(url: videoURL)
                }
            }
            .navigationDestination(isPresented: $navigateToBreakdown) {
                BreakdownView(videoURL: videoURL)
            }
        }
    }
}
