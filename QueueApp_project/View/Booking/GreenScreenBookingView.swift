//
//  GreenScreenBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//


import SwiftUI

// MARK: - 1. GreenScreenBookingView
struct GreenScreenBookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState // 👈 รับ "สมอง"
    @Environment(\.dismiss) var dismiss
    let service: LibraryService
    
    // Layouts
    let roomColumns = [GridItem(.flexible()), GridItem(.flexible())] // 2 ห้อง
    let slotColumns = [GridItem(.flexible()), GridItem(.flexible())] // รอบเวลา
    
    // MARK: - State
    @State private var mockEquipment = ["Camera (Sony A7)", "Tripod", "LED Light Panel", "Microphone (Rode)"]
    @State private var bookedRooms: Set<Int> = [2] // (จำลอง)
    @State private var timeSlots: [TimeSlot] = []
    
    @State private var selectedRoom: Int? = nil
    @State private var selectedSlot: TimeSlot? = nil
    @State private var selectedEquipment: Set<String> = []
    
    // เช็กว่าพร้อมจองไหม (แค่ห้อง + เวลา)
    var isSelectionValid: Bool {
        selectedRoom != nil && selectedSlot != nil
    }

    // MARK: - Body
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    
                    // --- 1. เลือกห้อง ---
                    Text("1. Select a Room")
                        .font(.title2).fontWeight(.bold).padding([.top, .horizontal])
                    LegendView(service: service).padding(.horizontal)
                    LazyVGrid(columns: roomColumns, spacing: 10) {
                        ForEach(1...2, id: \.self) { roomNum in
                            GreenScreenRoomView(roomNumber: roomNum, selectedRoom: $selectedRoom, bookedRooms: bookedRooms, themeColor: service.themeColor)
                        }
                    }
                    .padding(.horizontal)

                    Divider().padding()

                    // --- 2. เลือกรอบเวลา ---
                    Text("2. Select a Time Slot")
                        .font(.title2).fontWeight(.bold).padding(.horizontal)
                    LazyVGrid(columns: slotColumns, spacing: 10) {
                        ForEach(timeSlots) { slot in
                            // ⭐️ ใช้ TimeSlotView (จาก BookingSharedViews.swift)
                            TimeSlotView(slot: slot, selectedSlot: $selectedSlot, themeColor: service.themeColor)
                        }
                    }
                    .padding(.horizontal)

                    Divider().padding()

                    // --- 3. เลือกอุปกรณ์ (Optional) ---
                    Text("3. Select Equipment (Optional)")
                        .font(.title2).fontWeight(.bold).padding(.horizontal)
                    Text("Selected: \(selectedEquipment.count)")
                        .font(.caption).padding(.horizontal)
                    List(mockEquipment, id: \.self) { item in
                        HStack {
                            Image(systemName: selectedEquipment.contains(item) ? "checkmark.square.fill" : "square")
                                .foregroundColor(service.themeColor)
                            Text(item)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Logic เลือก/ยกเลิก (ไม่จำกัดจำนวน)
                            if selectedEquipment.contains(item) {
                                selectedEquipment.remove(item)
                            } else {
                                selectedEquipment.insert(item)
                            }
                        }
                    }
                    .frame(height: 250)
                    .listStyle(.plain)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            } // End ScrollView
            
            Spacer()
            
            // MARK: - Action Button
            Button(action: {
                guard let room = selectedRoom, let slot = selectedSlot else { return }
                
                // สร้างรายละเอียดการจอง (รวมอุปกรณ์)
                let details = "Room \(room) @ \(slot.time) (\(selectedEquipment.count) items)"
                
                // ⭐️ สั่ง AppState ให้สร้างการจอง
                appState.createReservation(service: service, details: details)
                dismiss() // ปิดหน้า
                
            }) {
                Text("Confirm Booking")
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(isSelectionValid ? Color.green : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!isSelectionValid) // ⭐️ เช็กแค่ ห้อง + เวลา
            .padding()
        }
        .navigationTitle(service.name)
        .onAppear { loadMockTimeSlots() }
    }
    
    // MARK: - Helper Functions
    // (จำลองการโหลดรอบเวลา)
    func loadMockTimeSlots() {
        self.timeSlots = [
            TimeSlot(time: "10:00 - 12:00", isBooked: false),
            TimeSlot(time: "12:00 - 14:00", isBooked: false),
            TimeSlot(time: "14:00 - 16:00", isBooked: false),
            TimeSlot(time: "16:00 - 18:00", isBooked: true)
        ]
    }
}

// MARK: - 2. GreenScreenRoomView
// (ปุ่ม "ห้อง Green-Screen")
struct GreenScreenRoomView: View {
    let roomNumber: Int
    @Binding var selectedRoom: Int?
    let bookedRooms: Set<Int>
    let themeColor: Color // สีเขียว
    
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
                Image(systemName: "camera.fill") // ⭐️ ไอคอนกล้อง
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