//
//  AdminBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//


import SwiftUI

struct AdminBookingView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            List {
                // 1. คิว (Board Game)
                Section(header: Text("Active Queues (\(queues.count))")) {
                    if queues.isEmpty { Text("No active queues.") }
                    ForEach(queues, id: \.data.id) { booking in
                        BookingAdminRow(booking: booking.data, docID: booking.docID)
                    }
                }
                
                // 2. การจอง (Co-work, Netflix, Green)
                Section(header: Text("Active Reservations (\(reservations.count))")) {
                    if reservations.isEmpty { Text("No active reservations.") }
                    ForEach(reservations, id: \.data.id) { booking in
                        BookingAdminRow(booking: booking.data, docID: booking.docID)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Admin Panel")
        .onAppear {
            appState.listenToAdminBookings() // ⭐️ เริ่ม Listener
        }
        .onDisappear {
            appState.stopListeningToAdminBookings() // ⭐️ หยุด Listener
        }
    }
    
    // MARK: - Computed Properties
    // (แยก List ที่ดึงมาจาก AppState)
    private var queues: [(docID: String, data: AppState.Booking)] {
        appState.allAdminBookings.filter { $0.data.bookingType == "Queue" }
    }
    
    private var reservations: [(docID: String, data: AppState.Booking)] {
        appState.allAdminBookings.filter { $0.data.bookingType == "Reservation" }
    }
}

// MARK: - Subview (แถวใน List)
struct BookingAdminRow: View {
    @EnvironmentObject var appState: AppState
    let booking: AppState.Booking
    let docID: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(booking.serviceName)
                .font(.headline)
            Text(booking.details)
                .font(.subheadline)
            Text("User: \(booking.userID)")
                .font(.caption).foregroundColor(.gray)
            
            // ⭐️ (R2) แสดงปุ่มตามสถานะ
            HStack {
                Spacer()
                if booking.status == "Queued" || booking.status == "Booked" {
                    // ถ้ายังไม่ Check-in
                    Button("Check-In") {
                        appState.checkInBooking(docID: docID) // 👈 เรียก AppState
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                } else if booking.status == "In-Use" {
                    // ถ้า Check-in แล้ว
                    Button("Finish") {
                        appState.finishBooking(docID: docID) // 👈 เรียก AppState
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
        }
        .padding(.vertical, 5)
    }
}

#Preview {
    NavigationStack {
        AdminBookingView()
            .environmentObject(AppState())
    }
}