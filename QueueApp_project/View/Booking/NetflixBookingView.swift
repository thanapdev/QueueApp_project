//
//  NetflixBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

// MARK: - 1. NetflixBookingView
struct NetflixBookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let service: LibraryService
    
    // Layouts
    let roomColumns = [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)]
    let slotColumns = [GridItem(.flexible()), GridItem(.flexible())]
    
    // MARK: - State
    @State private var timeSlots: [TimeSlot] = [] // (ข้อมูลรอบเวลา)
    @State private var selectedRoom: Int? = nil
    @State private var selectedSlot: TimeSlot? = nil
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. Background
            DynamicBackground(style: .random)
            
            VStack(spacing: 0) {
                // --- HEADER ---
                VStack(alignment: .leading, spacing: 10) {
                    // Back Button
                    Button(action: {
                        dismiss()
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
                    Text(service.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    Text("จองห้องดูหนังส่วนตัว")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                
                // --- CONTENT (White Sheet) ---
                ZStack {
                    Color.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    VStack {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 25) {
                                
                                // --- 1. เลือกรอบเวลา ---
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("1. Select a Time Slot")
                                        .font(.title3).fontWeight(.bold)
                                        .foregroundColor(Color.Theme.textDark)
                                    
                                    LazyVGrid(columns: slotColumns, spacing: 10) {
                                        ForEach(timeSlots) { slot in
                                            TimeSlotView(slot: slot, selectedSlot: $selectedSlot, themeColor: service.themeColor)
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                // --- 2. เลือกห้อง ---
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("2. Select a Room")
                                        .font(.title3).fontWeight(.bold)
                                        .foregroundColor(Color.Theme.textDark)
                                        .opacity(selectedSlot == nil ? 0.5 : 1.0)
                                    
                                    LegendView(service: service)
                                        .opacity(selectedSlot == nil ? 0.5 : 1.0)
                                    
                                    LazyVGrid(columns: roomColumns, spacing: 15) {
                                        ForEach(1...6, id: \.self) { roomNumber in
                                            NetflixRoomView(
                                                roomNumber: roomNumber,
                                                selectedRoom: $selectedRoom,
                                                bookedSlots: appState.currentServiceBookedSlots, // (R1)
                                                themeColor: service.themeColor
                                            )
                                        }
                                    }
                                    .disabled(selectedSlot == nil) // (Disabled ถ้ายังไม่เลือกเวลา)
                                    .opacity(selectedSlot == nil ? 0.5 : 1.0)
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 30)
                            .padding(.bottom, 100) // เว้นที่ให้ปุ่มด้านล่าง
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            
            // --- Floating Action Button ---
            VStack {
                Spacer()
                Button(action: {
                    if let room = selectedRoom, let slot = selectedSlot {
                        let slotID = "Room \(room)"
                        // สั่ง AppState ให้สร้างการจอง (Logic เดิม)
                        appState.createReservation(
                            service: service,
                            slotID: slotID,
                            timeSlot: slot.time,
                            items: nil
                        )
                        dismiss()
                    }
                }) {
                    Text("Confirm Booking")
                        .font(.headline).fontWeight(.bold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(selectedRoom == nil || selectedSlot == nil ? Color.gray : Color.green)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .disabled(selectedRoom == nil || selectedSlot == nil)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadMockTimeSlots() }
        .onDisappear {
            // หยุด Listener เมื่อออกจากหน้า
            appState.stopListeningToServiceBookings()
        }
        // เมื่อ "รอบเวลา" เปลี่ยน ให้เริ่ม Listener ใหม่ (Logic เดิม)
        .onChange(of: selectedSlot) { newSlot in
            if let slot = newSlot {
                selectedRoom = nil // ล้างค่าห้องเดิม
                appState.listenToServiceBookings(service: service.name, timeSlot: slot.time)
            } else {
                appState.stopListeningToServiceBookings()
            }
        }
    }
    
    // (จำลองการโหลดรอบเวลา)
    func loadMockTimeSlots() {
        self.timeSlots = [
            TimeSlot(time: "10:00 - 12:00", isBooked: false),
            TimeSlot(time: "12:00 - 14:00", isBooked: false),
            TimeSlot(time: "14:00 - 16:00", isBooked: false),
            TimeSlot(time: "16:00 - 18:00", isBooked: false)
        ]
    }
}

// MARK: - 2. NetflixRoomView (Component)
struct NetflixRoomView: View {
    let roomNumber: Int
    @Binding var selectedRoom: Int?
    let bookedSlots: Set<String> // (R1) รับ Set<String> จาก AppState
    let themeColor: Color
    
    private var slotID: String { "Room \(roomNumber)" }
    
    // (R1) Logic เช็คสถานะห้อง
    var isBooked: Bool { bookedSlots.contains(slotID) }
    var isSelected: Bool { selectedRoom == roomNumber }
    
    var bg: Color {
        if isBooked { return .gray.opacity(0.3) }
        if isSelected { return .green }
        return themeColor.opacity(0.1)
    }
    
    var fg: Color {
        if isBooked { return .gray }
        if isSelected { return .white }
        return themeColor
    }
    
    var body: some View {
        Button(action: { selectedRoom = roomNumber }) {
            VStack {
                Image(systemName: "play.tv.fill")
                    .font(.title2)
                Text(slotID)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(bg)
            .foregroundColor(fg)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? .green : (isBooked ? .clear : themeColor.opacity(0.3)), lineWidth: 2)
            )
        }
        .disabled(isBooked)
    }
}
