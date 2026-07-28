//
//  BackgroundView.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-20.
//


import SwiftUI

struct BackgroundView: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable() //
            .aspectRatio(contentMode: .fill) //
            .ignoresSafeArea() //
    }
}

