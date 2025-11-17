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
    @EnvironmentObject var appState: AppState // 👈 รับ "สมอง"
    @Environment(\.dismiss) var dismiss
    let service: LibraryService
    
    // Layouts
    let roomColumns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    let slotColumns = [GridItem(.flexible()), GridItem(.flexible())]
    
    // MARK: - State
    @State private var bookedRooms: Set<Int> = [3] // (จำลอง)
    @State private var timeSlots: [TimeSlot] = [] // (ข้อมูลรอบเวลา)
    @State private var selectedRoom: Int? = nil
    @State private var selectedSlot: TimeSlot? = nil
    
    // MARK: - Body
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    // --- 1. เลือกห้อง ---
                    Text("1. Select a Room").font(.title2).fontWeight(.bold).padding(.top)
                    LegendView(service: service).padding(.bottom, 5)
                    LazyVGrid(columns: roomColumns, spacing: 15) {
                        ForEach(1...6, id: \.self) { roomNumber in
                            NetflixRoomView(roomNumber: roomNumber, selectedRoom: $selectedRoom, bookedRooms: bookedRooms, themeColor: service.themeColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider().padding()
                    
                    // --- 2. เลือกรอบเวลา ---
                    Text("2. Select a Time Slot").font(.title2).fontWeight(.bold)
                    LazyVGrid(columns: slotColumns, spacing: 10) {
                        ForEach(timeSlots) { slot in
                            // ⭐️ ใช้ TimeSlotView (จาก BookingSharedViews.swift)
                            TimeSlotView(slot: slot, selectedSlot: $selectedSlot, themeColor: service.themeColor)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            Spacer()
            
            // MARK: - Action Button
            Button(action: {
                if let room = selectedRoom, let slot = selectedSlot {
                    // ⭐️ สั่ง AppState ให้สร้างการจอง
                    appState.createReservation(service: service, details: "Room \(room) @ \(slot.time)")
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
        .onAppear { loadMockTimeSlots() } // 👈 โหลดรอบเวลา (จำลอง)
    }
    
    // MARK: - Helper Functions
    // (จำลองการโหลดรอบเวลา)
    func loadMockTimeSlots() {
        self.timeSlots = [
            TimeSlot(time: "10:00 - 12:00", isBooked: false),
            TimeSlot(time: "12:00 - 14:00", isBooked: false),
            TimeSlot(time: "14:00 - 16:00", isBooked: false),
            TimeSlot(time: "16:00 - 18:00", isBooked: true) // 4 โมงเต็ม
        ]
    }
}

// MARK: - 2. NetflixRoomView
// (ปุ่ม "ห้องดูหนัง" ที่ใช้เฉพาะใน Netflix)
struct NetflixRoomView: View {
    let roomNumber: Int
    @Binding var selectedRoom: Int?
    let bookedRooms: Set<Int>
    let themeColor: Color
    
    var isBooked: Bool { bookedRooms.contains(roomNumber) }
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
                Text("Room \(roomNumber)")
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