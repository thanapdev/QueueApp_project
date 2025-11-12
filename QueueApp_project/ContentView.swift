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
        if let user = appState.currentUser {
            if user.role == .organization {
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
            NavigationStack {
                ServiceView()
                    .environmentObject(appState)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

