//
//  GreenScreenBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

struct GreenScreenBookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let service: LibraryService
    
    let roomColumns = [GridItem(.flexible()), GridItem(.flexible())]
    let slotColumns = [GridItem(.flexible()), GridItem(.flexible())]
    
    // MARK: - State
    @State private var mockEquipment = ["Camera (Sony A7)", "Tripod", "LED Light Panel", "Microphone (Rode)"]
    // ⭐️ (R1) ลบ @State private var bookedRooms ทิ้ง
    @State private var timeSlots: [TimeSlot] = []
    
    @State private var selectedRoom: Int? = nil
    @State private var selectedSlot: TimeSlot? = nil
    @State private var selectedEquipment: Set<String> = []
    
    var isSelectionValid: Bool {
        selectedRoom != nil && selectedSlot != nil
    }

    // MARK: - Body
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    
                    // --- 1. เลือกรอบเวลา (ย้ายมาไว้ข้างบน) ---
                    Text("1. Select a Time Slot")
                        .font(.title2).fontWeight(.bold).padding([.top, .horizontal])
                    LazyVGrid(columns: slotColumns, spacing: 10) {
                        ForEach(timeSlots) { slot in
                            TimeSlotView(slot: slot, selectedSlot: $selectedSlot, themeColor: service.themeColor)
                        }
                    }
                    .padding(.horizontal)

                    Divider().padding()

                    // --- 2. เลือกห้อง ---
                    if selectedSlot != nil {
                        Text("2. Select a Room")
                            .font(.title2).fontWeight(.bold).padding(.horizontal)
                        LegendView(service: service).padding(.horizontal)
                        LazyVGrid(columns: roomColumns, spacing: 10) {
                            ForEach(1...2, id: \.self) { roomNum in
                                GreenScreenRoomView(
                                    roomNumber: roomNum,
                                    selectedRoom: $selectedRoom,
                                    // ⭐️ (R1) ส่ง Set ของช่องที่จองแล้ว (จาก AppState)
                                    bookedSlots: appState.currentServiceBookedSlots,
                                    themeColor: service.themeColor
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider().padding()
                    }

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
            }
            Spacer()
            
            // MARK: - Action Button
            Button(action: {
                guard let room = selectedRoom, let slot = selectedSlot else { return }
                
                let slotID = "Room \(room)"
                let items = Array(selectedEquipment)
                
                // ⭐️ (R1) สั่ง AppState ให้สร้างการจอง
                appState.createReservation(
                    service: service,
                    slotID: slotID,   // 👈 ส่ง slotID
                    timeSlot: slot.time, // 👈 ส่ง timeSlot
                    items: items.isEmpty ? nil : items // 👈 ส่ง items
                )
                dismiss()
                
            }) {
                Text("Confirm Booking")
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(isSelectionValid ? Color.green : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!isSelectionValid)
            .padding()
        }
        .navigationTitle(service.name)
        .onAppear { loadMockTimeSlots() }
        .onDisappear {
            // ⭐️ (R1) หยุด Listener เมื่อออกจากหน้า
            appState.stopListeningToServiceBookings()
        }
        // ⭐️ (R1) เมื่อ "รอบเวลา" เปลี่ยน ให้เริ่ม Listener ใหม่
        .onChange(of: selectedSlot) { newSlot in
            if let slot = newSlot {
                selectedRoom = nil
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
            TimeSlot(time: "16:00 - 18:00", isBooked: true)
        ]
    }
}

struct GreenScreenRoomView: View {
    let roomNumber: Int
    @Binding var selectedRoom: Int?
    let bookedSlots: Set<String> // 👈 (R1) รับ Set<String>
    let themeColor: Color
    
    private var slotID: String { "Room \(roomNumber)" } // 👈 (R1)
    
    // ⭐️ (R1) แก้ Logic isBooked
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
                Image(systemName: "camera.fill")
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
