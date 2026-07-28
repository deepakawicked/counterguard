//
//  notesmanger.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-22.
//

import SwiftUI
import Combine

// MARK: - Note Data Model
struct NoteItem: Identifiable, Codable, Equatable {
    
    // this holds the stuff in relation to the time model --> it is a "worker" of note class, as note manger itself handles
    // the snapping through the actionNote function
    
    let id: UUID
    var timestamp: Double
    var text: String

    var formattedTime: String {
        let mins = Int(timestamp) / 60
        let secs = Int(timestamp) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Notes Manager Class
class NotesManager: ObservableObject { //whenever notemanger changes, as it is an obserable object, any view calling it will automatically change t o 
    @Published var notes: [NoteItem] = [] // the total notes - stored in an array for export for a data model in teh future

    init(initialNotes: [NoteItem] = []) { //mock notes - create when the future is fire read
        // Pre-populate mock notes for product demo testing if provided - sample notes
        self.notes = initialNotes.isEmpty ? [
            NoteItem(id: UUID(), timestamp: 1.5, text: "Keep hands up during stance initialization."),
            NoteItem(id: UUID(), timestamp: 4.2, text: "Good hips extension on the jab."),
            NoteItem(id: UUID(), timestamp: 7.0, text: "Rear foot lifting off floor — stay grounded.")
        ] : initialNotes
        
        self.notes.sort { $0.timestamp < $1.timestamp }
    }

    // Finds a note active near the current time within a window (default ±0.8 seconds)
    func activeNote(at currentTime: Double, window: Double = 0.8) -> NoteItem? {
        return notes.first { abs($0.timestamp - currentTime) <= window }
    }

    
    //lets the user add a new note
    func addNote(at timestamp: Double, text: String = "") {
        let newNote = NoteItem(id: UUID(), timestamp: timestamp, text: text)
        notes.append(newNote)
        
        //sort the notes based on timestamp
        notes.sort { $0.timestamp < $1.timestamp }
    }
    //update a current note
    func updateNote(_ updatedNote: NoteItem) {
        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
            notes[index] = updatedNote
        }
    }
    
    //delelting a note, pretty simple, note (haha), $0 is a placeholdrr, alongside $1 
    func deleteNote(_ note: NoteItem) {
        notes.removeAll { $0.id == note.id } //evaluate the coditon - if the current note is equally to the note idea r emove it
    }

    //basic moving back and forth for notes
    func nextNote(after timestamp: Double) -> NoteItem? {
        return notes.first { $0.timestamp > timestamp + 0.8 }
    }

    func previousNote(before timestamp: Double) -> NoteItem? {
        return notes.last { $0.timestamp < timestamp - 0.8 }
    }
}
