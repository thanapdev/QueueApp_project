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
            // 🚨 แก้ไขตรงส่วน else นี้ทั้งหมด 🚨
                    } else if appState.isBrowsingAsGuest {
                        // 👈 1. เพิ่ม else if: ถ้าดูแบบ Guest ให้ไปหน้า Guest
                        GuestActivityListView()
                            .environmentObject(appState)
                        
                    } else {
                        // 👈 2. ถ้าไม่ Login และไม่ Guest = อยู่หน้า Service (Login)
                        NavigationStack {
                            ServiceView() // (นี่คือหน้า Login/Guest ของคุณ)
                                .environmentObject(appState)
                        }
                    }
                }
            }
