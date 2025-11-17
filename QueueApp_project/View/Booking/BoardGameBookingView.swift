//
//  BoardGameBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//


import SwiftUI

// MARK: - 1. BoardGameBookingView
struct BoardGameBookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState // 👈 รับ "สมอง"
    @Environment(\.dismiss) var dismiss
    let service: LibraryService
    
    let tableColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    // MARK: - State
    @State private var mockGames = ["Catan", "Monopoly", "Clue", "Risk", "Uno", "Jenga", "Exploding Kittens"]
    @State private var bookedTables: Set<Int> = [2, 5] // (จำลอง)
    @State private var selectedTable: Int? = nil
    @State private var selectedGames: Set<String> = []
    
    // MARK: - Computed Properties
    // R1: (1 โต๊ะ และ 1-3 เกม)
    var isSelectionValid: Bool {
        selectedTable != nil && (1...3).contains(selectedGames.count)
    }

    // MARK: - Body
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    
                    // --- 1. เลือกโต๊ะ ---
                    Text("1. Select a Table (1)").font(.title2).fontWeight(.bold).padding([.top, .horizontal])
                    LazyVGrid(columns: tableColumns, spacing: 10) {
                        ForEach(1...6, id: \.self) { tableNum in
                            BoardGameTableView(tableNumber: tableNum, selectedTable: $selectedTable, bookedTables: bookedTables, themeColor: service.themeColor)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider().padding()
                    
                    // --- 2. เลือกเกม ---
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
                            // R1: Logic เลือกได้ไม่เกิน 3 เกม
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
                // ⭐️ สั่ง AppState ให้ "เข้าคิว" (ไม่ใช่จอง)
                appState.joinQueue(service: service, table: table, games: Array(selectedGames))
                dismiss()
            }) {
                Text("Join Queue")
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(isSelectionValid ? Color.green : Color.gray) // 👈 เช็ก isSelectionValid
                    .cornerRadius(12)
            }
            .disabled(!isSelectionValid)
            .padding()
        }
        .navigationTitle(service.name)
    }
}

// MARK: - 2. BoardGameTableView
// (ปุ่ม "โต๊ะ" ที่ใช้เฉพาะใน Board Game)
struct BoardGameTableView: View {
    let tableNumber: Int
    @Binding var selectedTable: Int?
    let bookedTables: Set<Int>
    let themeColor: Color
    
    var isBooked: Bool { bookedTables.contains(tableNumber) }
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
                Text("Table \(tableNumber)")
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