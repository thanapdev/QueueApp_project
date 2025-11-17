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
        // เพิ่ม print statement ที่นี่เพื่อดูสถานะปัจจุบัน
        let _ = print("ContentView: Body re-evaluated. isLoggedIn: \(appState.isLoggedIn), isBrowsingAsGuest: \(appState.isBrowsingAsGuest)")

        if appState.isLoggedIn {
            let _ = print("ContentView: แสดง View สำหรับผู้ใช้ที่ Login แล้ว.")
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
        } else if appState.isBrowsingAsGuest {
            let _ = print("ContentView: แสดง GuestActivityListView.")
            // 👈 1. เพิ่ม NavigationStack ที่นี่เพื่อให้ GuestActivityListView มี Navigation Bar และ Title ได้
            NavigationStack { // <<< เพิ่ม NavigationStack ตรงนี้
                GuestActivityListView()
                    .environmentObject(appState)
            }
        } else {
            let _ = print("ContentView: แสดง ServiceView (หน้า Login).")
            // 👈 2. ถ้าไม่ Login และไม่ Guest = อยู่หน้า Service (Login)
            NavigationStack {
                ServiceView() // (นี่คือหน้า Login/Guest ของคุณ)
                    .environmentObject(appState)
            }
        }
    }
}

