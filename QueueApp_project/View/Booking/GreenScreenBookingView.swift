//
//  GreenScreenBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

// MARK: - Green Screen Booking View
// หน้าจองห้อง Green Screen
// ทำหน้าที่:
// 1. เลือกรอบเวลา (Time Slot)
// 2. เลือกห้อง (Room 1-2)
// 3. ตรวจสอบสถานะว่างและยืนยันการจอง
struct GreenScreenBookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState       // Global state
    @Environment(\.dismiss) var dismiss             // ใช้สำหรับปิดหน้านี้
    let service: LibraryService                     // ข้อมูลบริการที่เลือก
    
    let slotColumns = [GridItem(.flexible()), GridItem(.flexible())]  // Grid 2 คอลัมน์สำหรับรอบเวลา
    let roomColumns = [GridItem(.flexible()), GridItem(.flexible())]  // Grid 2 คอลัมน์สำหรับห้อง
    
    // MARK: - State
    @State private var mockEquipment = ["Camera (Sony A7)", "Tripod", "LED Light Panel", "Microphone (Rode)"] // รายการอุปกรณ์เสริมทั้งหมด
    @State private var timeSlots: [TimeSlot] = []   // รายการรอบเวลาทั้งหมด
    
    @State private var selectedRoom: Int? = nil     // ห้องที่เลือก (1-2)
    @State private var selectedSlot: TimeSlot? = nil // รอบเวลาที่เลือก
    @State private var selectedEquipment: Set<String> = [] // อุปกรณ์เสริมที่เลือก
    
    // ตรวจสอบความถูกต้อง (ต้องเลือกห้องและรอบเวลา)
    var isSelectionValid: Bool {
        selectedRoom != nil && selectedSlot != nil
    }

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
                    
                    Text("จองห้องสตูดิโอและอุปกรณ์")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                
                // --- CONTENT (White Sheet) ---
                ZStack {
                    Color.Theme.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    VStack {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 25) {
                                
                                // --- 1. เลือกรอบเวลา ---
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("1. Select Time Slot")
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
                                    Text("2. Select Room")
                                        .font(.title3).fontWeight(.bold)
                                        .foregroundColor(Color.Theme.textDark)
                                        .opacity(selectedSlot == nil ? 0.5 : 1.0)
                                    
                                    LegendView(service: service)
                                        .opacity(selectedSlot == nil ? 0.5 : 1.0)
                                    
                                    LazyVGrid(columns: roomColumns, spacing: 10) {
                                        ForEach(1...2, id: \.self) { roomNum in
                                            GreenScreenRoomView(
                                                roomNumber: roomNum,
                                                selectedRoom: $selectedRoom,
                                                bookedSlots: appState.currentServiceBookedSlots,
                                                themeColor: service.themeColor
                                            )
                                        }
                                    }
                                    .disabled(selectedSlot == nil)
                                    .opacity(selectedSlot == nil ? 0.5 : 1.0)
                                }

                                Divider()
                                
                                // --- 3. เลือกอุปกรณ์ ---
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("3. Select Equipment")
                                            .font(.title3).fontWeight(.bold)
                                            .foregroundColor(Color.Theme.textDark)
                                        Spacer()
                                        if !selectedEquipment.isEmpty {
                                            Text("\(selectedEquipment.count) Items")
                                                .font(.caption).fontWeight(.bold)
                                                .foregroundColor(.green)
                                                .padding(6)
                                                .background(Color.green.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                    
                                    // Equipment Cards
                                    ForEach(mockEquipment, id: \.self) { item in
                                        let isSelected = selectedEquipment.contains(item)
                                        
                                        HStack {
                                            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                                .foregroundColor(isSelected ? .green : service.themeColor)
                                                .font(.title3)
                                            
                                            Text(item)
                                                .fontWeight(isSelected ? .semibold : .regular)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        .background(isSelected ? Color.green.opacity(0.05) : Color.Theme.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(isSelected ? Color.green : Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if isSelected {
                                                selectedEquipment.remove(item)
                                            } else {
                                                selectedEquipment.insert(item)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 30)
                            .padding(.bottom, 100) // เว้นที่ให้ปุ่ม
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            
            // --- Floating Action Button ---
            VStack {
                Spacer()
                Button(action: {
                    guard let room = selectedRoom, let slot = selectedSlot else { return }
                    
                    let slotID = "Room \(room)"
                    let items = Array(selectedEquipment)
                    
                    // สั่ง AppState ให้สร้างการจอง (Logic เดิม)
                    appState.createReservation(
                        service: service,
                        slotID: slotID,
                        timeSlot: slot.time,
                        items: items.isEmpty ? nil : items
                    )
                    dismiss()
                }) {
                    Text("Confirm Booking")
                        .font(.headline).fontWeight(.bold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(isSelectionValid ? Color.green : Color.gray)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .disabled(!isSelectionValid)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadMockTimeSlots() }
        .onDisappear {
            appState.stopListeningToServiceBookings()
        }
        .onChange(of: selectedSlot) { newSlot in
            if let slot = newSlot {
                selectedRoom = nil
                appState.listenToServiceBookings(service: service.name, timeSlot: slot.time)
            } else {
                appState.stopListeningToServiceBookings()
            }
        }
    }
    
    func loadMockTimeSlots() {
        self.timeSlots = [
            TimeSlot(time: "10:00 - 12:00", isBooked: false),
            TimeSlot(time: "13:00 - 15:00", isBooked: false),
            TimeSlot(time: "15:00 - 17:00", isBooked: false)
        ]
    }
}

// MARK: - Room View Component
// คอมโพเนนต์แสดงปุ่มเลือกห้อง
struct GreenScreenRoomView: View {
    let roomNumber: Int
    @Binding var selectedRoom: Int?
    let bookedSlots: Set<String>
    let themeColor: Color
    
    private var slotID: String { "Room \(roomNumber)" }
    
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
                Image(systemName: "camera.fill")
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
