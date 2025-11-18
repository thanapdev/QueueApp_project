import SwiftUI

struct AdminBookingView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 1. คิว (Board Game)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active Queues").font(.title2).fontWeight(.bold).padding(.horizontal)
                    let queues = appState.allAdminBookings.filter { $0.data.bookingType == "Queue" }
                    if queues.isEmpty {
                        Text("No active queues.").foregroundColor(.gray).padding(.horizontal)
                    } else {
                        ForEach(queues, id: \.docID) { booking in
                            BookingAdminCard(booking: booking.data, docID: booking.docID)
                        }
                    }
                }
                
                Divider()
                
                // 2. การจอง (Reservation) - รวมถึงที่กำลังใช้งาน (In-Use)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active Reservations / In-Use").font(.title2).fontWeight(.bold).padding(.horizontal)
                    let reservations = appState.allAdminBookings.filter { $0.data.bookingType == "Reservation" }
                    if reservations.isEmpty {
                        Text("No active reservations.").foregroundColor(.gray).padding(.horizontal)
                    } else {
                        ForEach(reservations, id: \.docID) { booking in
                            BookingAdminCard(booking: booking.data, docID: booking.docID)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Admin Panel")
        .onAppear { appState.listenToAdminBookings() }
        .onDisappear { appState.stopListeningToAdminBookings() }
    }
}

struct BookingAdminCard: View {
    @EnvironmentObject var appState: AppState
    let booking: AppState.Booking
    let docID: String
    
    // คำนวณเวลาที่เหลือ (สำหรับ Admin ดู)
    var timeRemainingString: String {
        let end = booking.endTime?.dateValue() ?? Date()
        let remaining = end.timeIntervalSince(Date())
        if remaining <= 0 { return "Expired" }
        let m = Int(remaining) / 60
        return "\(m) mins left"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(booking.serviceName).font(.headline)
                Spacer()
                Text(booking.status).font(.caption).fontWeight(.bold).padding(.horizontal, 8).padding(.vertical, 4)
                    .background(statusColor.opacity(0.2)).foregroundColor(statusColor).cornerRadius(8)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.details).font(.subheadline).fontWeight(.semibold)
                    Text("User: \(booking.userID)").font(.caption).foregroundColor(.gray)
                    if booking.status == "In-Use" {
                        Text(timeRemainingString).font(.caption).foregroundColor(.red)
                    }
                }
                Spacer()
                
                // ⭐️⭐️⭐️ Admin Controls ⭐️⭐️⭐️
                VStack(spacing: 8) {
                    
                    // 1. ปุ่ม Check-In (แสดงเมื่อยังไม่เข้าใช้)
                    if booking.status == "Queued" || booking.status == "Booked" {
                        Button(action: { withAnimation { appState.checkInBooking(docID: docID) } }) {
                            Label("Check-In", systemImage: "checkmark.circle").font(.caption).fontWeight(.bold)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color.blue).foregroundColor(.white).cornerRadius(8)
                        }
                    }
                    
                    // 2. ปุ่ม Skip Time & Finish (แสดงเมื่อ In-Use)
                    if booking.status == "In-Use" {
                        HStack {
                            // ปุ่ม Skip Time (วาร์ปไป 10 นาทีสุดท้าย)
                            Button(action: { withAnimation { appState.adminSkipTime(docID: docID) } }) {
                                Image(systemName: "goforward.plus")
                                    .padding(8).background(Color.orange).foregroundColor(.white).clipShape(Circle())
                            }
                            
                            // ปุ่ม Finish
                            Button(action: { withAnimation { appState.finishBooking(docID: docID) } }) {
                                Label("Finish", systemImage: "flag.checkered").font(.caption).fontWeight(.bold)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(Color.green).foregroundColor(.white).cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .padding().background(Color.white).cornerRadius(12).shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1).padding(.horizontal)
        .id(booking.status) // Refresh UI on status change
    }
    
    var statusColor: Color {
        switch booking.status {
        case "Booked", "Queued": return .orange
        case "In-Use": return .blue
        case "Finished": return .green
        default: return .gray
        }
    }
}   
