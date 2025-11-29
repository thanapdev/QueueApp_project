//
//  BookingDetailView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

// MARK: - Booking Detail View
// ตัวกลาง (Router) สำหรับนำทางไปยังหน้าจองของแต่ละบริการ
// ตรวจสอบสถานะการจองปัจจุบันก่อนแสดงผล
struct BookingDetailView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState // รับ "สมอง"
    let service: LibraryService
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. ใช้ Theme Background ใหม่ (แทน Gradient เดิม)
            DynamicBackground(style: .random)
            
            // MARK: - Check for Active Booking (R3)
            // ถ้า AppState บอกว่าจองอยู่ (ไม่ว่าจะเป็น Reservation หรือ Queue)
            if appState.hasActiveBooking {
                // ให้แสดงหน้า "จองแล้ว" บังไว้
                AlreadyBookedView()
                    .environmentObject(appState)
            } else {
                
                // MARK: - Show Correct Booking Page
                // เลือกหน้าจอตาม Service ที่กดเข้ามา
                switch service.name {
                case "Co-working Space":
                    CoWorkingBookingView(service: service)
                        .environmentObject(appState)
                case "Netflix & Chill":
                    NetflixBookingView(service: service)
                        .environmentObject(appState)
                case "Board Game":
                    BoardGameBookingView(service: service)
                        .environmentObject(appState)
                case "Green-Screen Room":
                    GreenScreenBookingView(service: service)
                        .environmentObject(appState)
                default:
                    // (เผื่อไว้ถ้ามี Service อื่น ๆ)
                    VStack {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .padding()
                        Text("Coming Soon: \(service.name)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        // ซ่อน Navbar ของระบบ เพื่อให้หน้าลูกๆ แสดง Custom Header ได้สวยงาม
        .navigationBarHidden(true)
    }
}
