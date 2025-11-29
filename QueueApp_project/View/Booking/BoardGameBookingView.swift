//
//  BoardGameBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol.
//

import SwiftUI

// MARK: - Board Game Booking View
// หน้ายืมบอร์ดเกม (Board Game Rental)
// ทำหน้าที่:
// 1. แสดงรายการบอร์ดเกมที่มีให้ยืม
// 2. เลือกเกมและยืนยันการยืม
// 3. ตรวจสอบสถานะว่าง (ถ้าถูกยืมไปแล้ว)
struct BoardGameBookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState       // Global state
    @Environment(\.dismiss) var dismiss             // ใช้สำหรับปิดหน้านี้
    let service: LibraryService                     // ข้อมูลบริการที่เลือก
    
    let tableColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]  // Grid 3 คอลัมน์
    
    // MARK: - State
    @State private var selectedTable: Int? = nil    // โต๊ะที่เลือก
    @State private var selectedGames: [String] = [] // เกมที่เลือก (สูงสุด 3 เกม)
    @State private var availableGames: [String] = [ // รายการเกมที่มีให้ยืม
        "Catan", "Monopoly", "Uno", "Exploding Kittens",
        "Codenames", "Ticket to Ride", "Pandemic"
    ]
    
    
    // ตรวจสอบความถูกต้องของการเลือก (ต้องเลือกโต๊ะและเลือกเกม 1-3 เกม)
    var isSelectionValid: Bool {
        selectedTable != nil && (1...3).contains(selectedGames.count)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // 1. Background
            DynamicBackground(style: .random)
            
            VStack(spacing: 0) {
                // HEADER
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
                    
                    Text("เลือกโต๊ะและเกมที่ต้องการเล่น (1-3 เกม)")
                        .font(.body)
                        .foregroundColor(Color.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                
                // CONTENT (White Sheet)
                ZStack {
                    Color.Theme.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                    
                    VStack {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 25) {
                                
                                // 1. เลือกโต๊ะ
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("1. Select a Table")
                                        .font(.title3).fontWeight(.bold)
                                        .foregroundColor(Color.Theme.textDark)
                                    
                                    LazyVGrid(columns: tableColumns, spacing: 15) {
                                        ForEach(1...6, id: \.self) { tableNum in
                                            BoardGameTableView(
                                                tableNumber: tableNum,
                                                selectedTable: $selectedTable,
                                                bookedSlots: appState.currentServiceBookedSlots,
                                                themeColor: service.themeColor
                                            )
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                // 2. เลือกเกม
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("2. Select Games")
                                            .font(.title3).fontWeight(.bold)
                                            .foregroundColor(Color.Theme.textDark)
                                        Spacer()
                                        Text("\(selectedGames.count)/3 Selected")
                                            .font(.caption).fontWeight(.bold)
                                            .foregroundColor(selectedGames.count > 0 ? .green : .gray)
                                            .padding(6)
                                            .background(Color.green.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    
                                    // Custom List Row
                                    ForEach(availableGames, id: \.self) { game in
                                        let isGameBooked = appState.currentBookedGames.contains(game)
                                        let isSelected = selectedGames.contains(game)
                                        
                                        HStack {
                                            Image(systemName: isSelected ? "checkmark.square.fill" : (isGameBooked ? "x.square.fill" : "square"))
                                                .foregroundColor(isSelected ? .green : (isGameBooked ? .gray : service.themeColor))
                                                .font(.title3)
                                            
                                            Text(game)
                                                .strikethrough(isGameBooked)
                                                .foregroundColor(isGameBooked ? .gray : .primary)
                                                .fontWeight(isSelected ? .semibold : .regular)
                                            
                                            Spacer()
                                            
                                            if isGameBooked {
                                                Text("In Use")
                                                    .font(.caption)
                                                    .padding(4)
                                                    .background(Color.gray.opacity(0.2))
                                                    .cornerRadius(4)
                                                    .foregroundColor(.gray)
                                            }
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
                                            guard !isGameBooked else { return }
                                            if isSelected {
                                                selectedGames.removeAll { $0 == game }
                                            } else if selectedGames.count < 3 {
                                                selectedGames.append(game)
                                            }
                                        }
                                    }
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
            
            // Floating Action Button
            VStack {
                Spacer()
                Button(action: {
                    guard let table = selectedTable else { return }
                    let slotID = "Table \(table)"
                    let games = Array(selectedGames)
                    
                    // สั่ง AppState ให้สร้างการจอง (Logic เดิม)
                    appState.createReservation(
                        service: service,
                        slotID: slotID,
                        timeSlot: nil, // ไม่มีรอบเวลา (Walk-in)
                        items: games
                    )
                    dismiss()
                }) {
                    Text("Confirm Booking (2 Hrs)")
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
        .onAppear {
            // เริ่มฟังข้อมูลการจองโต๊ะและเกม
            appState.listenToServiceBookings(service: service.name, timeSlot: nil)
            appState.listenToBookedGames()
        }
        .onDisappear {
            // หยุดฟังข้อมูลเมื่อออกจากหน้า
            appState.stopListeningToServiceBookings()
            appState.stopListeningToBookedGames()
        }
    }
}

// MARK: - Table View Component (ปรับแต่งเล็กน้อย)
// คอมโพเนนต์แสดงปุ่มเลือกโต๊ะ
struct BoardGameTableView: View {
    let tableNumber: Int
    @Binding var selectedTable: Int?
    let bookedSlots: Set<String>
    let themeColor: Color
    
    private var slotID: String { "Table \(tableNumber)" }
    
    var isBooked: Bool { bookedSlots.contains(slotID) }
    var isSelected: Bool { selectedTable == tableNumber }
    
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
        Button(action: { selectedTable = tableNumber }) {
            VStack {
                Image(systemName: "gamecontroller.fill")
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
