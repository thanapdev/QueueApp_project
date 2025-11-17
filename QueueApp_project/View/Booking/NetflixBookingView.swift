//
//  NetflixBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//


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
    let roomColumns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    let slotColumns = [GridItem(.flexible()), GridItem(.flexible())]
    
    // MARK: - State
    @State private var timeSlots: [TimeSlot] = [] // (ข้อมูลรอบเวลา)
    @State private var selectedRoom: Int? = nil
    @State private var selectedSlot: TimeSlot? = nil
    
    // MARK: - Body
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    // --- 1. เลือกรอบเวลา (ย้ายมาไว้ข้างบน) ---
                    Text("1. Select a Time Slot").font(.title2).fontWeight(.bold).padding(.top)
                    LazyVGrid(columns: slotColumns, spacing: 10) {
                        ForEach(timeSlots) { slot in
                            TimeSlotView(slot: slot, selectedSlot: $selectedSlot, themeColor: service.themeColor)
                        }
                    }
                    .padding(.horizontal)
                        
                    Divider().padding()
                        
                    // --- 2. เลือกห้อง (จะแสดงเมื่อเลือกรอบเวลาแล้ว) ---
                    // ⭐️⭐️⭐️ (จุดแก้ไข) ⭐️⭐️⭐️
                    // (เปลี่ยนจาก if selectedSlot != nil เป็น .disabled)
                    VStack {
                        Text("2. Select a Room").font(.title2).fontWeight(.bold)
                        LegendView(service: service).padding(.bottom, 5)
                        LazyVGrid(columns: roomColumns, spacing: 15) {
                            ForEach(1...6, id: \.self) { roomNumber in
                                NetflixRoomView(
                                    roomNumber: roomNumber,
                                    selectedRoom: $selectedRoom,
                                    // (R1) ส่ง Set ของช่องที่จองแล้ว (จาก AppState)
                                    bookedSlots: appState.currentServiceBookedSlots,
                                    themeColor: service.themeColor
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .opacity(selectedSlot == nil ? 0.5 : 1.0) // 👈 1. ทำให้จางลง
                    .disabled(selectedSlot == nil) // 👈 2. ทำให้กดไม่ได้
                    // ⭐️⭐️⭐️ (จบจุดแก้ไข) ⭐️⭐️⭐️
                }
            }
            Spacer()
            
            // MARK: - Action Button
            Button(action: {
                if let room = selectedRoom, let slot = selectedSlot {
                    let slotID = "Room \(room)"
                    // (R1) สั่ง AppState ให้สร้างการจอง
                    appState.createReservation(
                        service: service,
                        slotID: slotID, // 👈 ส่ง slotID
                        timeSlot: slot.time, // 👈 ส่ง timeSlot
                        items: nil
                    )
                    dismiss()
                }
            }) {
                Text("Confirm Booking")
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(selectedRoom == nil || selectedSlot == nil ? Color.gray : Color.green)
                    .cornerRadius(12)
            }
            .disabled(selectedRoom == nil || selectedSlot == nil)
            .padding()
        }
        .navigationTitle(service.name)
        .onAppear { loadMockTimeSlots() }
        .onDisappear {
            // (R1) หยุด Listener เมื่อออกจากหน้า
            appState.stopListeningToServiceBookings()
        }
        // (R1) เมื่อ "รอบเวลา" เปลี่ยน ให้เริ่ม Listener ใหม่
        .onChange(of: selectedSlot) { newSlot in
            if let slot = newSlot {
                // (ล้างค่าห้องที่เลือกไว้)
                selectedRoom = nil
                // (เริ่ม Listener ใหม่สำหรับรอบเวลานี้)
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
            TimeSlot(time: "16:00 - 18:00", isBooked: false) // (isBooked นี้แค่ทำให้ปุ่มเทา แต่ R1 จะกันจองซ้ำ)
        ]
    }
}

// MARK: - 2. NetflixRoomView
struct NetflixRoomView: View {
    let roomNumber: Int
    @Binding var selectedRoom: Int?
    let bookedSlots: Set<String> // 👈 (R1) รับ Set<String> จาก AppState
    let themeColor: Color
    
    private var slotID: String { "Room \(roomNumber)" } // 👈 (R1)
    
    // (R1) แก้ Logic isBooked
    var isBooked: Bool { bookedSlots.contains(slotID) }
    var isSelected: Bool { selectedRoom == roomNumber }
    
    var seatColor: Color {
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
        Button(action: { selectedRoom = roomNumber }) {
            VStack {
                Image(systemName: "play.tv.fill")
                Text(slotID)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(seatColor)
            .foregroundColor(textColor)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? .green : Color.clear, lineWidth: 2))
        }
        .disabled(isBooked)
    }
}
