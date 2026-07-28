//
//  mainpage.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-14.
//

import SwiftUI

struct mainPage: View {
    // Injecting your SessionStore to pull actual saved data
    @StateObject private var sessionStore = SessionStore()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.ignoresSafeArea(edges: .all)
                
                // MARK: - Main Scroll Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header
                        Text("Your Activity")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // MARK: Recent Sessions (Jump Back In)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Jump back in")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    if sessionStore.sessions.isEmpty {
                                        // Premium Empty State / Mock Placeholder
                                        PlaceholderSessionCard()
                                    } else {
                                        // Actual Saved Sessions
                                        ForEach(sessionStore.sessions, id: \.id) { session in
                                            // Assuming your Session model has these properties.
                                            // Adjust property names (e.g., session.actionTitle) to match your actual model.
                                            SessionCard(
                                                title: session.actionTitle ?? "Sparring Session",
                                                date: session.date ?? Date(),
                                                confidence: session.confidence ?? 0.85
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // MARK: Analytics Recap
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recap")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                StatCard(title: "Sessions", value: "\(sessionStore.sessions.count)", icon: "figure.boxing", color: .blue)
                                StatCard(title: "Avg Form", value: "88%", icon: "chart.xyaxis.line", color: .green)
                                StatCard(title: "Streak", value: "3 Days", icon: "flame.fill", color: .orange)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                            .frame(height: 100) // Padding for bottom nav bar
                    }
                }
                
                // MARK: - Floating Bottom Navigation Bar
                VStack {
                    Spacer()
                    CustomBottomNavBar()
                }
            }
        }
        .onAppear {
            // Load sessions when the view appears if your store requires it
            // sessionStore.loadSessions()
        }
    }
}

// MARK: - UI Components

/// A sleek card for displaying actual saved sessions
struct SessionCard: View {
    var title: String
    var date: Date
    var confidence: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Spacer()
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                Text("AI Confidence:")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(String(format: "%.0f%%", confidence * 100))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(confidence > 0.8 ? .green : .orange)
            }
        }
        .padding()
        .frame(width: 260, height: 160)
        .background(
            LinearGradient(colors: [Color(uiColor: .darkGray).opacity(0.4), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

/// A premium placeholder card when no sessions exist
struct PlaceholderSessionCard: View {
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 40))
                .foregroundColor(.blue.opacity(0.8))
            
            Text("No Sessions Yet")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Hit the camera icon below to start analyzing your form.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .padding()
        .frame(width: 260, height: 160)
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                .foregroundColor(Color.gray.opacity(0.3))
        )
    }
}

/// Analytics stat card for the Recap section
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Spacer()
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 110)
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// The polished floating navigation bar
struct CustomBottomNavBar: View {
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            NavIcon(icon: "gearshape")
            Spacer()
            NavIcon(icon: "book.closed")
            Spacer()
            
            // Primary Action Button (Camera)
            NavigationLink(destination: CameraPage()) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                        .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .offset(y: -15) // Floats slightly above the bar
            }
            
            Spacer()
            NavIcon(icon: "folder")
            Spacer()
            NavIcon(icon: "map")
            Spacer()
        }
        .padding(.vertical, 10)
        .background(.ultraThinMaterial) // Glassmorphism effect
        .clipShape(Capsule())
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

/// Helper for standard navigation icons
struct NavIcon: View {
    let icon: String
    var body: some View {
        Button(action: {
            // Add navigation actions here later
        }) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.gray)
        }
    }
}
