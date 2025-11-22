//
//  BookingSharedViews.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol.
//

import SwiftUI

// MARK: - 1. Active Booking Banner (ปรับปรุง UI ให้สวยขึ้น)
// แบนเนอร์แสดงสถานะการจองปัจจุบัน (แสดงด้านล่างของหน้าจอ)
// แสดงชื่อบริการ สถานะ เวลาที่เหลือ และปุ่มยกเลิก/ขยายเวลา
struct MyBookingBannerView: View {
    @EnvironmentObject var appState: AppState
    
    var activeBooking: AppState.Booking? {
        appState.activeReservation?.data ?? appState.activeQueue?.data
    }

    var body: some View {
        VStack(spacing: 12) {
            if let booking = activeBooking {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // Status Badge (เล็กๆ ด้านบน)
                        Text(statusText(for: booking.status))
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(for: booking.status).opacity(0.2))
                            .foregroundColor(statusColor(for: booking.status))
                            .cornerRadius(8)
                        
                        // Service Name & Detail
                        Text(booking.serviceName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(booking.details)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Timer Countdown
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            Text("Time Remaining: \(formatTime(appState.timeRemaining))")
                        }
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(appState.timeRemaining < 600 ? .red : .green) // สีแดงถ้าเหลือน้อย
                        .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    // End/Cancel Button
                    Button(action: {
                        appState.cancelActiveBooking()
                    }) {
                        VStack {
                            Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            Text("End")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Extend Button (แสดงเฉพาะตอนแจ้งเตือน)
                if appState.showExtendAlert {
                    Button(action: {
                        appState.extendBooking()
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Extend (+2 Hours)")
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .transition(.opacity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.15)) // สีเทาเข้มเกือบดำ (Modern Dark)
                .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10) // เงาลอยๆ
        )
        .alert("หมดเวลาแล้ว!", isPresented: $appState.showQueueAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("กรุณาติดต่อเจ้าหน้าที่เพื่อคืนอุปกรณ์/เช็คเอาท์")
        }
    }
    
    // Helper Functions
    func formatTime(_ totalSeconds: TimeInterval) -> String {
        let h = Int(totalSeconds) / 3600
        let m = (Int(totalSeconds) % 3600) / 60
        let s = Int(totalSeconds) % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        else { return String(format: "%02d:%02d", m, s) }
    }
    
    func statusText(for status: String) -> String {
        switch status {
        case "In-Use": return "🟢 Active Now"
        case "Queued": return "🟡 Waiting"
        case "Reserved": return "🔵 Reserved"
        default: return status
        }
    }
    
    func statusColor(for status: String) -> Color {
        switch status {
        case "In-Use": return .green
        case "Queued": return .yellow
        case "Reserved": return .blue
        default: return .gray
        }
    }
}

// MARK: - 2. Already Booked View (หน้าเต็มจอบังไว้)
// หน้าจอแจ้งเตือนเมื่อผู้ใช้พยายามจองซ้ำ
// แสดงรายละเอียดการจองปัจจุบันและปุ่มยกเลิก
struct AlreadyBookedView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss // 1. เพิ่มตัวสั่งปิดหน้า
    
    var body: some View {
        ZStack(alignment: .topLeading) { // 2. ใช้ ZStack เพื่อวางปุ่ม Back มุมซ้ายบน
            
            // --- ปุ่ม Back (กลับไปหน้าเลือกบริการ) ---
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.headline)
                .foregroundColor(.blue) // ใช้สีให้ตัดกับพื้นขาว
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
            }
            .padding(.leading, 20)
            .padding(.top, 50) // เผื่อพื้นที่ Safe Area ด้านบน
            .zIndex(1) // ให้ปุ่มลอยอยู่ชั้นบนสุด
            
            // --- เนื้อหาแจ้งเตือน (อยู่ตรงกลางเหมือนเดิม) ---
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text("You have an active session")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("คุณมีการจองค้างอยู่แล้ว 1 รายการ\nสามารถจองได้ทีละ 1 รายการเท่านั้น")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // แสดงรายละเอียดการจองปัจจุบัน
                if let b = appState.activeReservation?.data ?? appState.activeQueue?.data {
                    VStack(spacing: 8) {
                        Text("Current Booking:")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                        
                        Text(b.serviceName)
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text(b.details)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // ปุ่ม End Session (เผื่ออยากยกเลิกจริงๆ)
                Button(action: {
                    appState.cancelActiveBooking()
                }) {
                    Text("End Session (Cancel)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 250)
                        .background(Color.red)
                        .cornerRadius(15)
                        .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.bottom, 50)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        // .navigationBarHidden(true) // ซ่อน Bar ของระบบ (เพราะเราทำปุ่ม Back เองแล้ว)
    }
}
// MARK: - 3. Legend View (คำอธิบายสี)
// แสดงความหมายของสีในตารางจอง (Available, Selected, Booked)
struct LegendView: View {
    let service: LibraryService
    var body: some View {
        HStack(spacing: 16) {
            LegendItem(color: service.themeColor.opacity(0.3), text: "Available")
            LegendItem(color: .green, text: "Selected")
            LegendItem(color: .gray, text: "Booked")
        }
        .font(.caption)
        .padding(.vertical, 8)
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - 4. Time Slot View (ปุ่มเลือกรอบเวลา)
// ปุ่มสำหรับเลือกช่วงเวลาจอง
struct TimeSlotView: View {
    let slot: TimeSlot
    @Binding var selectedSlot: TimeSlot?
    let themeColor: Color
    
    var isBooked: Bool { slot.isBooked }
    var isSelected: Bool { selectedSlot?.id == slot.id }
    
    var slotColor: Color {
        if isBooked { return .gray.opacity(0.3) } // ปรับสีเทาให้อ่อนลงหน่อย
        else if isSelected { return .green }
        else { return themeColor.opacity(0.1) } // สีพื้นหลังอ่อนๆ ตามธีม
    }
    
    var textColor: Color {
        if isBooked { return .gray }
        else if isSelected { return .white }
        else { return themeColor }
    }
    
    var body: some View {
        Button(action: { selectedSlot = slot }) {
            Text(slot.time)
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(slotColor)
                .foregroundColor(textColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.green : (isBooked ? Color.clear : themeColor.opacity(0.3)), lineWidth: 1.5)
                )
        }
        .disabled(isBooked)
        .opacity(isBooked ? 0.6 : 1.0)
    }
}
