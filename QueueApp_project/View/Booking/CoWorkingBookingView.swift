//
//  CoWorkingBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//

import SwiftUI

// MARK: - Co-Working Booking View
// หน้าจองพื้นที่ Co-Working Space
// ทำหน้าที่:
// 1. เลือกรอบเวลา (Time Slot)
// 2. เลือกโต๊ะ (Table 1-12)
// 3. ตรวจสอบสถานะว่างและยืนยันการจอง
struct CoWorkingBookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState       // Global state
    @Environment(\.dismiss) var dismiss             // ใช้สำหรับปิดหน้านี้
    let service: LibraryService                     // ข้อมูลบริการที่เลือก
    
    let columns = [                                 // Grid 3 คอลัมน์สำหรับแสดงโต๊ะ
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    // MARK: - State
    @State private var selectedSeat: Int? = nil     // โต๊ะที่เลือก (1-12)
    @State private var selectedSlot: TimeSlot? = nil // รอบเวลาที่เลือก
    @State private var timeSlots: [TimeSlot] = []   // รายการรอบเวลาทั้งหมด
    
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
                    
                    Text("เลือกที่นั่งที่คุณต้องการ")
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
                            VStack(alignment: .leading, spacing: 20) {
                                
                                // Title & Legend
                                HStack {
                                    Text("Select a Seat")
                                        .font(.title3).fontWeight(.bold)
                                        .foregroundColor(Color.Theme.textDark)
                                    Spacer()
                                }
                                .padding(.top, 30)
                                
                                LegendView(service: service)
                                    .padding(.bottom, 10)
                                
                                // Seat Grid
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(1...15, id: \.self) { seatNumber in
                                        SeatView(
                                            seatNumber: seatNumber,
                                            selectedSeat: $selectedSeat,
                                            bookedSlots: appState.currentServiceBookedSlots,
                                            themeColor: service.themeColor
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 30)
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
                    if let seat = selectedSeat {
                        let slotID = "Slot \(seat)"
                        // สั่ง AppState ให้สร้างการจอง
                        appState.createReservation(
                            service: service,
                            slotID: slotID,
                            timeSlot: nil,
                            items: nil
                        )
                        dismiss()
                    }
                }) {
                    Text("Confirm Booking")
                        .font(.headline).fontWeight(.bold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding()
                        .background(selectedSeat == nil ? Color.gray : Color.green)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .disabled(selectedSeat == nil)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // เริ่มฟังข้อมูลการจองที่นั่ง
            appState.listenToServiceBookings(service: service.name, timeSlot: nil)
        }
        .onDisappear {
            // หยุดฟังข้อมูลเมื่อออกจากหน้า
            appState.stopListeningToServiceBookings()
        }
    }
}

// MARK: - Seat View Component
// คอมโพเนนต์แสดงปุ่มเลือกที่นั่ง
struct SeatView: View {
    let seatNumber: Int
    @Binding var selectedSeat: Int?
    let bookedSlots: Set<String>
    let themeColor: Color
    
    private var slotID: String { "Slot \(seatNumber)" }
    
    var isBooked: Bool { bookedSlots.contains(slotID) }
    var isSelected: Bool { selectedSeat == seatNumber }
    
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
        Button(action: {
            if isSelected { selectedSeat = nil } else { selectedSeat = seatNumber }
        }) {
            VStack(spacing: 5) {
                Image(systemName: "chair.lounge.fill")
                    .font(.title2)
                Text("\(seatNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
            }
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
