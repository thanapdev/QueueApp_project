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

        // ใช้ Group เพื่อรวม View ที่มีการแสดงผลแบบมีเงื่อนไข
        // และใช้ .animation และ .transition กับ Group นี้
        Group {
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
                NavigationStack {
                    GuestActivityListView()
                        .environmentObject(appState)
                }
            } else {
                let _ = print("ContentView: แสดง ServiceView (หน้า Login).")
                NavigationStack {
                    ServiceView()
                        .environmentObject(appState)
                }
            }
        }
        // เพิ่ม modifier .animation และ .transition ที่นี่
        // .transition(.opacity) จะทำให้ View ค่อยๆ จางหายไป/ปรากฏขึ้นมา
        // .animation จะบอกว่าให้แอนิเมตอย่างไรเมื่อค่าที่ติดตาม (value) มีการเปลี่ยนแปลง
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.4), value: appState.isLoggedIn) // แอนิเมตเมื่อ isLoggedIn เปลี่ยน
        .animation(.easeInOut(duration: 0.4), value: appState.isBrowsingAsGuest) // แอนิเมตเมื่อ isBrowsingAsGuest เปลี่ยน
    }
}
