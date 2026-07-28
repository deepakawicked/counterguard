//
//  recommendation.swift
//  Counterguard-Ai
//

import SwiftUI

struct RecommendationsTabView: View {
    
    //Array of string that holds of recommendations or focus points, given three default states just for testing
    @State private var items: [String] = [
        "Focus on keeping the rear pivot foot firmly grounded during early chamber phase to increase power transfer.",
        "3x10 Chamber Elevation Holds",
        "Guard Retention Drill (2 mins)"
    ]
    //temp holds what the user is typing
    @State private var newItemText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Input Field
            HStack { //newtext item is binded into this, newItem is text returns whatever the user puts into it
                TextField("Add practice focus item...", text: $newItemText)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done) //waits for the return key
                    .onSubmit(addItem) //triggers addItem on exit

                Button(action: addItem) { //another item that also does the additem??
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty) //checking if the thing is empty or just spacers
            }

            // MARK: - Action Items List
            
            //fallback state if there is nohing
            if items.isEmpty {
                Text("No focus items added yet.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8) //show this no focus items yet - can expand for expansions
            } else {
                VStack(spacing: 8) { //Vstack contins the rcommendations
                    ForEach(items.indices, id: \.self) { index in //iterates to build a list for each
                        
                        //each row is an hstack
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.gray)
                                .padding(.top, 2)

                            Text(items[index])
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            // Delete Button
                            Button {
                                deleteItem(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.subheadline)
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        }
                        
                        // Item --> Text --> Trash button
                        .padding(10)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(.horizontal, 16) // Fixes edge clipping
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    
    //help functions
    // MARK: - Functions
    private func addItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return } //stops excution if the text space it item
        items.append(trimmed)
        newItemText = ""
        
        //if valid, add to our lsit and ne w itme
    }

    /// Deletes an item from the focus list by index
    private func deleteItem(at index: Int) {
        guard items.indices.contains(index) else { return } //chek if it exists
        withAnimation(.easeInOut(duration: 0.2)) {
            items.remove(at: index)
            //slide the row out smoothly
        }
    }
}
