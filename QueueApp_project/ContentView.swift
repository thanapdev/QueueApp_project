//
//  ContentView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 10/11/2568 BE.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var appState = AppState()
    var body: some View {
        if appState.currentUser?.role == .organization {
                        NavigationStack {
                            ActivityListView()
                                .environmentObject(appState)
                        }
                    } else {
            NavigationStack {
                RoleSelectionView()
                    .environmentObject(appState)
            }
        }
    }
}
