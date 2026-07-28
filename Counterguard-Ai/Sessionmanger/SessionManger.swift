//
//  SessionManger.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-22.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Session Model
struct SavedNote: Codable, Identifiable { // gives what a piece of data looks like
    //codable can save into a jason, indeifiyables gives a uid
    var id = UUID()
    let timestamp: Double
    let text: String
}

struct SessionItem: Codable, Identifiable {
    let id: UUID
    let date: Date
    let actionTitle: String
    let confidence: Double
    let relativeVideoPath: String // Relative filename inside Documents
    var notes: [SavedNote]
    
    
    //get our notes
    // Absolute URL for playing the video on device
    var videoURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(relativeVideoPath)
    }
}

// MARK: - Session Manager
class SessionStore: ObservableObject { //setups a singal for the main page/
    @Published var sessions: [SessionItem] = []
    private let saveKey = "Counterguard_SavedSessions"

    init() {
        loadSessions()
    }

    func loadSessions() { //checki if data exisa
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([SessionItem].self, from: data) else {
            return //if it fails quietly exist, can put some logic here
        }
        self.sessions = decoded
    }

    func saveSession(from tempURL: URL, actionTitle: String, confidence: Double, notes: [SavedNote]) {
        let sessionID = UUID()
        let fileName = "\(sessionID.uuidString).mp4"
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = docsURL.appendingPathComponent(fileName)

        // Move video file to permanent local storage
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: tempURL, to: destinationURL)
        } catch {
            print("Failed to save video file: \(error)")
            return
        }

        // Save Metadata --> Brekdownview --> Sessions
        let newSession = SessionItem(
            id: sessionID,
            date: Date(),
            actionTitle: actionTitle,
            confidence: confidence,
            relativeVideoPath: fileName,
            notes: notes
        )

        sessions.insert(newSession, at: 0)
        persistToUserDefaults()
    }
    
    //remove the sessions
    func deleteSession(at indexSet: IndexSet) {
        for index in indexSet {
            let session = sessions[index]
            try? FileManager.default.removeItem(at: session.videoURL)
        }
        sessions.remove(atOffsets: indexSet)
        persistToUserDefaults()
    }
    
    
    //decodes into raw jason deafult and soles in userdefaults, making sure it stays in hard drive 
    private func persistToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}
