//
//  AdminBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol.
//

import SwiftUI

// MARK: - Admin Booking View
// หน้าจัดการการจองสำหรับ Admin
// ทำหน้าที่:
// 1. แสดงรายการจองทั้งหมด
// 2. ยกเลิกการจอง
struct AdminBookingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Background
                DynamicBackground(style: .random)
                
                VStack(spacing: 0) {
                    // --- Header ---
                    VStack(alignment: .leading, spacing: 10) {
                        // Back Button
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                        }
                        .padding(.top, 50)
                        
                        // Title
                        Text("Booking Management")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        Text("จัดการการจองและการใช้งานสถานที่")
                            .font(.body)
                            .foregroundColor(Color.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                    
                    // --- Content Area (White Sheet) ---
                    ZStack {
                        Color.Theme.white
                            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            
                            // Filter / Header Title
                            HStack {
                                Text("Active Reservations")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.Theme.textDark)
                                
                                Spacer()
                                
                                // Count Badge
                                Text("\(appState.allAdminBookings.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                            .padding(.top, 30)
                            .padding(.horizontal, 30)
                            
                            // Booking List
                            if appState.allAdminBookings.isEmpty {
                                // Empty State
                                VStack(spacing: 15) {
                                    Spacer()
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray.opacity(0.3))
                                    Text("No active bookings found")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                // List of Bookings
                                ScrollView(showsIndicators: false) {
                                    LazyVStack(spacing: 16) {
                                        // Loop แสดงรายการจอง
                                        ForEach(appState.allAdminBookings, id: \.docID) { bookingTuple in
                                            BookingAdminCard(booking: bookingTuple.data, docID: bookingTuple.docID)
                                        }
                                    }
                                    .padding(.horizontal, 20) // ขอบซ้ายขวา
                                    .padding(.bottom, 50)
                                }
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .navigationBarHidden(true)
        }
        .onAppear { appState.listenToAdminBookings() } // เริ่มฟังข้อมูล Real-time
        .onDisappear { appState.stopListeningToAdminBookings() } // หยุดฟังเมื่อออก
    }
}

// MARK: - Booking Admin Card Component
// การ์ดแสดงรายละเอียดการจองแต่ละรายการสำหรับ Admin
struct BookingAdminCard: View {
    @EnvironmentObject var appState: AppState
    let booking: AppState.Booking
    let docID: String
    
    // คำนวณเวลาที่เหลือ (สำหรับสถานะ In-Use)
    var timeRemainingString: String {
        guard let end = booking.endTime?.dateValue() else { return "Waiting..." }
        let remaining = end.timeIntervalSince(Date())
        
        if remaining <= 0 { return "Expired" }
        let h = Int(remaining) / 3600
        let m = (Int(remaining) % 3600) / 60
        
        if h > 0 { return "\(h)h \(m)m left" }
        else { return "\(m) mins left" }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1. Header Row (Service Name & Status)
            HStack {
                HStack(spacing: 8) {
                    // Service Icon (Optional logic to choose icon)
                    Image(systemName: "calendar")
                        .foregroundColor(Color.Theme.primary)
                    
                    Text(booking.serviceName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.Theme.textDark)
                }
                
                Spacer()
                
                // Status Badge
                Text(booking.status)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }
            
            Divider()
            
            // 2. Detail Row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    // Detail Info (e.g., Room Name, Time)
                    Text(booking.details)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    // User ID
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                        Text(booking.userID)
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                    
                    // Time Remaining (Show only if In-Use)
                    if booking.status == "In-Use" {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                            Text(timeRemainingString)
                        }
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                // 3. Admin Action Buttons
                VStack(spacing: 8) {
                    
                    // Case A: Waiting for Check-in (Queued/Booked)
                    if booking.status == "Queued" || booking.status == "Booked" {
                        Button(action: { withAnimation { appState.checkInBooking(docID: docID) } }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Check-In")
                            }
                            .font(.caption).fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Case B: In-Use Actions (Skip Time / Finish)
                    if booking.status == "In-Use" {
                        HStack(spacing: 8) {
                            // Skip Time Button (Warp to last 10 mins - For Testing/Demo)
                            Button(action: { withAnimation { appState.adminSkipTime(docID: docID) } }) {
                                Image(systemName: "goforward.plus")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundColor(.orange)
                                    .clipShape(Circle())
                            }
                            
                            // Finish Button (End Session)
                            Button(action: { withAnimation { appState.finishBooking(docID: docID) } }) {
                                Text("Finish")
                                    .font(.caption).fontWeight(.bold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.Theme.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Helper: Status Color
    var statusColor: Color {
        switch booking.status {
        case "Booked", "Queued": return .orange
        case "In-Use": return .blue
        case "Finished": return .green
        case "Cancelled": return .red
        default: return .gray
        }
    }
}

// Preview
struct AdminBookingView_Previews: PreviewProvider {
    static var previews: some View {
        AdminBookingView()
            .environmentObject(AppState())
    }
}
