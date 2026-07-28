//
//  splashscreen.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-14.
//


//this is the splashscreen
import SwiftUI

struct SplashScreen: View {
    @State private var navigateToHome = false
    var body: some View {
        NavigationStack {
            
            
            ZStack {
                Image("background_splash")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .scaleEffect(1.60)
                    .offset(x: 40, y: 200)
                
                VStack {
                    Spacer()
                    
                    Text("Precision \nTraining, \nAccelerated")
                        .font(.system(size:60, weight:.bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                    //just get thtat nice movement there
                        .padding(-4)
                    
                    HStack {
                        Button ("Sign Up") {
                            
                        }
                        .buttonStyle((CustomButtonStyle(color: .gray)))
                        
                        Button("Sign in" ) {
                            
                        }
                        .buttonStyle((CustomButtonStyle(color: .red)))
                        
                    }
                    .padding(5)
                    Button("Try for Free") {
                        navigateToHome = true
                    }
                    
                    .font(.title)
                    //the blue background
                    .frame(width: 350, height: 60)
                    .background(Color.blue)
                    .foregroundColor(Color.white)
                    .cornerRadius(60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.blue)
                    )
                }
                .padding()
            }
            .navigationDestination(isPresented: $navigateToHome) {
                mainPage()
            }
        }
    }
}

struct CustomButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            
            .frame(width:175, height:70)
            .background(color)
            .cornerRadius(25)
    }
}
