//
//  BookingDetailView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//


import SwiftUI

struct BookingDetailView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState // 👈 รับ "สมอง"
    let service: LibraryService
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background (เหมือนหน้าหลัก)
            LinearGradient(gradient: Gradient(colors: [Color(red: 150/255, green: 150/255, blue: 150/255).opacity(0.3), Color(red: 190/255, green: 50/255, blue: 50/255).opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            // MARK: - 1. Check for Active Booking (R3)
            // ⭐️ ถ้า AppState บอกว่าจองอยู่ (ไม่ว่าจะเป็น Reservation หรือ Queue)
            if appState.hasActiveBooking {
                // ให้แสดงหน้า "จองแล้ว" บังไว้
                AlreadyBookedView()
                    .environmentObject(appState) // 👈 ส่ง AppState ไปให้ปุ่ม Cancel
            } else {
                
                // MARK: - 2. Show Correct Booking Page
                // ⭐️ ถ้ายังไม่จอง ให้เลือกหน้าจอตาม Service ที่กดเข้ามา
                switch service.name {
                case "Co-working Space":
                    CoWorkingBookingView(service: service)
                        .environmentObject(appState) // 👈 ส่ง AppState
                case "Netflix & Chill":
                    NetflixBookingView(service: service)
                        .environmentObject(appState) // 👈 ส่ง AppState
                case "Board Game":
                    BoardGameBookingView(service: service)
                        .environmentObject(appState) // 👈 ส่ง AppState
                case "Green-Screen Room":
                    GreenScreenBookingView(service: service)
                        .environmentObject(appState) // 👈 ส่ง AppState
                default:
                    // (เผื่อไว้ถ้ามี Service อื่นๆ)
                    Text("หน้าสำหรับจอง: \(service.name)")
                        .font(.title)
                        .navigationTitle(service.name)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}