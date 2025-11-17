//
//  BookingSharedViews.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

// MARK: - 1. ServiceCardView
// (การ์ด 4 ใบในหน้า BookingView)
struct ServiceCardView: View {
    let service: LibraryService
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: service.iconName)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(service.themeColor)
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(service.themeColor.opacity(0.1))
                .cornerRadius(12)
            Text(service.name)
                .font(.headline).fontWeight(.bold).foregroundColor(.black)
            Text(service.description)
                .font(.caption).foregroundColor(.gray).lineLimit(2)
            Spacer()
            Text("Book Now")
                .font(.caption).fontWeight(.bold).foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(service.themeColor).cornerRadius(20)
        }
        .padding()
        .frame(minHeight: 240)
        .background(.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 2. MyBookingBannerView
// (R3, R4) แถบ Banner ที่แสดงข้างล่าง เมื่อมีการจอง/คิว
struct MyBookingBannerView: View {
    @EnvironmentObject var appState: AppState // 👈 รับ "สมอง"
    var body: some View {
        VStack(spacing: 8) {
            
            // A. ถ้าเป็นการจอง (Co-work, Netflix, Green)
            if let reservation = appState.activeReservation {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Reservation")
                            .font(.caption).foregroundColor(.white.opacity(0.7))
                        Text("\(reservation.data.serviceName): \(reservation.data.details)")
                            .font(.headline).fontWeight(.bold)
                    }
                    Spacer()
                    Button("Cancel") { appState.cancelActiveBooking() } // 👈 เรียก AppState
                        .buttonStyle(.bordered).tint(.white.opacity(0.5))
                }
            
            // B. ถ้าเป็นการเข้าคิว (Board Game)
            } else if let queue = appState.activeQueue {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Queue: \(queue.data.serviceName)")
                            .font(.caption).foregroundColor(.white.opacity(0.7))
                        // R4: แสดงเวลานับถอยหลัง
                        Text("Your turn in: \(formatTime(appState.queueTimeRemaining))")
                            .font(.headline).fontWeight(.bold)
                    }
                    Spacer()
                    Button("Cancel") { appState.cancelActiveBooking() } // 👈 เรียก AppState
                        .buttonStyle(.bordered).tint(.white.opacity(0.5))
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom))
        
        // R5: Alert แจ้งเตือนเมื่อคิวหมดเวลา
        .alert("ถึงคิวของคุณแล้ว!", isPresented: $appState.showQueueAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("กรุณามารับ board game จากเจ้าหน้าที่")
        }
    }
    
    // R4: ฟังก์ชันแปลงวินาทีเป็น "นาที:วินาที"
    func formatTime(_ totalSeconds: TimeInterval) -> String {
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 3. AlreadyBookedView
// (R3) หน้าจอมืดๆ ที่ใช้ "บัง" เมื่อจองซ้ำ
struct AlreadyBookedView: View {
    @EnvironmentObject var appState: AppState // 👈 รับ "สมอง"
    var body: some View {
        VStack {
            Text("You already have an active booking")
                .font(.title2).fontWeight(.bold).multilineTextAlignment(.center).padding()
            
            // แสดงรายละเอียดการจอง/คิว ที่มีอยู่
            if let reservation = appState.activeReservation {
                Text("\(reservation.data.serviceName)")
                Text("\(reservation.data.details)")
            } else if let queue = appState.activeQueue {
                Text("\(queue.data.serviceName)")
                Text("\(queue.data.details)")
            }
            
            Button("Cancel Booking") {
                appState.cancelActiveBooking() // 👈 เรียก AppState
            }
            .buttonStyle(.borderedProminent).tint(.red).padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.8))
        .foregroundColor(.white)
    }
}

// MARK: - 4. LegendView
// (คำอธิบายสี: Available, Selected, Booked)
struct LegendView: View {
    let service: LibraryService
    var body: some View {
        HStack(spacing: 20) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4).fill(service.themeColor.opacity(0.3)).frame(width: 20, height: 20)
                Text("Available")
            }
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4).fill(Color.green).frame(width: 20, height: 20)
                Text("Selected")
            }
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4).fill(Color.gray).frame(width: 20, height: 20)
                Text("Booked")
            }
        }
        .font(.caption)
        .padding(.leading, 10)
    }
}

// MARK: - 5. TimeSlotView
// (ปุ่มเลือก "รอบเวลา" ที่ใช้ใน Netflix และ Green-Screen)
struct TimeSlotView: View {
    let slot: TimeSlot
    @Binding var selectedSlot: TimeSlot?
    let themeColor: Color
    var isBooked: Bool { slot.isBooked }
    var isSelected: Bool { selectedSlot?.id == slot.id }
    var slotColor: Color {
        if isBooked { return .gray }
        if isSelected { return .green }
        return themeColor.opacity(0.3)
    }
    var textColor: Color {
        if isBooked { return .white.opacity(0.7) }
        if isSelected { return .white }
        return themeColor
    }
    var body: some View {
        Button(action: { selectedSlot = slot }) {
            Text(slot.time)
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(slotColor)
                .foregroundColor(textColor)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? .green : Color.clear, lineWidth: 2))
        }
        .disabled(isBooked)
    }
}
