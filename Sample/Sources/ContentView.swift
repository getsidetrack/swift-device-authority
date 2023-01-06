//
// ContentView.swift
//
// Copyright 2023 • Sidetrack Tech Limited
//

import DeviceAuthority
import SwiftUI

struct ContentView: View {
    @State private var isSecureDevice: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: isSecureDevice ? "lock.open.fill" : "lock.fill")
                Text(isSecureDevice ? "Unlocked" : "Locked")
                    .fontWeight(.semibold)
            }
            .font(.largeTitle)
            .foregroundColor(.accentColor)
        }
        .multilineTextAlignment(.center)
        .padding()
        .onAppear {
            let api = 0
            let authority = DeviceAuthority(name: "DebugModeLeaf")
            
            switch api {
            case 0: // Swift Concurrency
                Task {
                    do {
                        try await authority.determineAuthorisationStatus()
                        isSecureDevice = true
                    } catch {
                        print(error)
                    }
                }
                
            case 1: // Async Callback
                authority.determineAuthorisationStatus { result in
                    switch result {
                    case .failure(let error):
                        print(error)
                        
                    case .success:
                        isSecureDevice = true
                    }
                }
                
            case 2: // Sync
                DispatchQueue.global(qos: .userInteractive).async {
                    do {
                        try authority.determineAuthorisationStatusSync()
                        
                        DispatchQueue.main.async {
                            self.isSecureDevice = true
                        }
                    } catch {
                        print(error)
                    }
                }
                
            default: // Unknown
                print("🔴 Unknown API has been specified, human error.")
            }
        }
    }
}
