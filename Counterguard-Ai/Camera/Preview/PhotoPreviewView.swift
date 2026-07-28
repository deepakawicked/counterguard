//
//  PhotoPreviewView.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-19.
//

import SwiftUI
import AVFoundation

struct PhotoPreviewView: View {
    
    let item: IdentifiableImage
    
    let onDismiss: () -> Void
    var body: some View {
        VStack {
            HStack{
                Button("Retake") {
                    onDismiss()
                }
                .padding()
                
                Spacer()
                
                Button("Save") {
                    UIImageWriteToSavedPhotosAlbum(item.image, nil, nil, nil)
                    onDismiss()
                }
            }
            .background(.ultraThinMaterial)
            
            Image(uiImage: item.image)
                .resizable()
                .scaledToFit()
            
            Spacer()
        }
    }
}
