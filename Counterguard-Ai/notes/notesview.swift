//
//  NotesView.swift
//  Counterguard-Ai
//

import SwiftUI
import Combine

//the struct that loads the note
//takes user input, and binds notes manger ninto it
struct NotesTabView: View {
    @ObservedObject var notesManager: NotesManager //whenever notes manger changes, complely rebuild the strucut
    let currentTime: Double //we have no currentime
    let seekToTime: (Double) -> Void //see a t ime

    var activeNote: NoteItem? {
        notesManager.activeNote(at: currentTime)
    } //get the current note time

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // MARK: Active Note / Empty State Section
            VStack(alignment: .leading, spacing: 10) {
                if let note = activeNote {
                    // MARK: Active Timeframe Note Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(note.formattedTime, systemImage: "clock.fill")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)

                            Spacer()

                            
                            /// Trash Button 
                            Button(role: .destructive) {
                                notesManager.deleteNote(note)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        }

                        // Editable Text Area
                        TextField("Type note here...", text: Binding(
                            get: { note.text },
                            set: { newText in
                                var updated = note
                                updated.text = newText
                                notesManager.updateNote(updated)
                            }
                        ), axis: .vertical)
                        .lineLimit(2...4)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    }
                    .padding(14)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.blue.opacity(0.25), lineWidth: 1.5)
                    )
                    // Swipe Left / Right Gesture
                    .gesture(
                        DragGesture(minimumDistance: 20, coordinateSpace: .local)
                            .onEnded { gesture in
                                if gesture.translation.width < -30 {
                                    // Swipe Left -> Go to Next Note
                                    if let next = notesManager.nextNote(after: currentTime) {
                                        seekToTime(next.timestamp)
                                    }
                                } else if gesture.translation.width > 30 {
                                    // Swipe Right -> Go to Previous Note
                                    if let prev = notesManager.previousNote(before: currentTime) {
                                        seekToTime(prev.timestamp)
                                    }
                                }
                            }
                    )

                    // Swipe Hint
                    HStack {
                        if notesManager.previousNote(before: currentTime) != nil {
                            Text("← Swipe for Prev Note")
                        }
                        Spacer()
                        if notesManager.nextNote(after: currentTime) != nil {
                            Text("Swipe for Next Note →")
                        }
                    }
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                } else {
                    // MARK: Empty State (No Note on Current Frame)
                    VStack(spacing: 12) {
                        Text("No note active at \(formatTimecode(currentTime))")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Button {
                            notesManager.addNote(at: currentTime, text: "")
                        } label: {
                            Label("Add Note at \(formatTimecode(currentTime))", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
            .frame(minHeight: 140, alignment: .top)
            .animation(.easeInOut(duration: 0.2), value: activeNote?.id)

            // MARK: Quick Navigation Pill List
            if !notesManager.notes.isEmpty {
                Divider()
                    .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Timeline Markers (\(notesManager.notes.count))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(notesManager.notes) { item in
                                Button {
                                    seekToTime(item.timestamp)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "bookmark.fill")
                                            .font(.system(size: 10))
                                        Text(item.formattedTime)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(activeNote?.id == item.id ? Color.blue : Color.gray.opacity(0.15))
                                    .foregroundColor(activeNote?.id == item.id ? .white : .primary)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16) // Fixes screen edge clipping
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatTimecode(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
