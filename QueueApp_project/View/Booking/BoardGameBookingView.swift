//
//  BoardGameBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//


import SwiftUI

struct BoardGameBookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let service: LibraryService
    
    let tableColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    // MARK: - State
    @State private var mockGames = ["Catan", "Monopoly", "Clue", "Risk", "Uno", "Jenga", "Exploding Kittens"]
    // ⭐️ (R1) ลบ @State private var bookedTables ทิ้ง
    @State private var selectedTable: Int? = nil
    @State private var selectedGames: Set<String> = []
    
    var isSelectionValid: Bool {
        selectedTable != nil && (1...3).contains(selectedGames.count)
    }

    // MARK: - Body
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("1. Select a Table (1)").font(.title2).fontWeight(.bold).padding([.top, .horizontal])
                    LazyVGrid(columns: tableColumns, spacing: 10) {
                        ForEach(1...6, id: \.self) { tableNum in
                            BoardGameTableView(
                                tableNumber: tableNum,
                                selectedTable: $selectedTable,
                                // ⭐️ (R1) ส่ง Set ของช่องที่จองแล้ว (จาก AppState)
                                bookedSlots: appState.currentServiceBookedSlots,
                                themeColor: service.themeColor
                            )
                        }
                    }
                    .padding(.horizontal)
                    Divider().padding()
                    Text("2. Select Games (1-3)").font(.title2).fontWeight(.bold).padding(.horizontal)
                    Text("Selected: \(selectedGames.count)").font(.caption).padding(.horizontal)
                    List(mockGames, id: \.self) { game in
                        HStack {
                            Image(systemName: selectedGames.contains(game) ? "checkmark.square.fill" : "square")
                                .foregroundColor(service.themeColor)
                            Text(game)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedGames.contains(game) {
                                selectedGames.remove(game)
                            } else if selectedGames.count < 3 {
                                selectedGames.insert(game)
                            }
                        }
                    }
                    .frame(height: 300)
                    .listStyle(.plain)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            Spacer()
            
            // MARK: - Action Button
            Button(action: {
                guard let table = selectedTable else { return }
                let slotID = "Table \(table)"
                let games = Array(selectedGames)
                
                // ⭐️ (R1) สั่ง AppState ให้ "เข้าคิว"
                appState.joinQueue(
                    service: service,
                    slotID: slotID, // 👈 ส่ง slotID
                    items: games    // 👈 ส่ง games
                )
                dismiss()
            }) {
                Text("Join Queue")
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(isSelectionValid ? Color.green : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!isSelectionValid)
            .padding()
        }
        .navigationTitle(service.name)
        // ⭐️ (R1) เริ่ม/หยุด Listener ส่วนรวม
        .onAppear {
            appState.listenToServiceBookings(service: service.name, timeSlot: nil)
        }
        .onDisappear {
            appState.stopListeningToServiceBookings()
        }
    }
}

struct BoardGameTableView: View {
    let tableNumber: Int
    @Binding var selectedTable: Int?
    let bookedSlots: Set<String> // 👈 (R1) รับ Set<String>
    let themeColor: Color
    
    private var slotID: String { "Table \(tableNumber)" } // 👈 (R1)
    
    // ⭐️ (R1) แก้ Logic isBooked
    var isBooked: Bool { bookedSlots.contains(slotID) }
    var isSelected: Bool { selectedTable == tableNumber }
    
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
        Button(action: { selectedTable = tableNumber }) {
            VStack {
                Image(systemName: "gamecontroller.fill")
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
