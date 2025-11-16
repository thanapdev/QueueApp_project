//
//  AppState.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        if appState.isLoggedIn {
            if let user = appState.currentUser {
                if user.role == .admin {
                    NavigationStack {
                        ActivityListView()
                            .environmentObject(appState)
                    }
                } else {
                    NavigationStack {
                        StudentActivityListView()
                            .environmentObject(appState)
                    }
                }
            } else {
                // Handle the case where isLoggedIn is true but currentUser is nil
                Text("Error: No user data found.") // Show an error message
            }
        } else {
            NavigationStack {
                ServiceView()
                    .environmentObject(appState)
            }
        }
    }
}
