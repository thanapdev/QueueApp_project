import SwiftUI

struct BoardGameBookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let service: LibraryService
    
    let tableColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    // MARK: - State
    @State private var mockGames = [
        "Catan", "Monopoly", "Clue", "Risk", "Uno", "Jenga", "Exploding Kittens",
        "Ticket to Ride", "Carcassonne", "Pandemic", "Scythe", "Terraforming Mars",
        "Wingspan", "Chess", "Cards Against Humanity", "What Do You Meme?"
    ]
    
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
                    
                    // --- 1. เลือกโต๊ะ ---
                    Text("1. Select a Table (1)").font(.title2).fontWeight(.bold).padding([.top, .horizontal])
                    LazyVGrid(columns: tableColumns, spacing: 10) {
                        ForEach(1...6, id: \.self) { tableNum in
                            BoardGameTableView(
                                tableNumber: tableNum,
                                selectedTable: $selectedTable,
                                bookedSlots: appState.currentServiceBookedSlots,
                                themeColor: service.themeColor
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider().padding()
                    
                    // --- 2. เลือกเกม ---
                    Text("2. Select Games (1-3)").font(.title2).fontWeight(.bold).padding(.horizontal)
                    Text("Selected: \(selectedGames.count)").font(.caption).padding(.horizontal)
                    
                    List(mockGames, id: \.self) { game in
                        let isGameBooked = appState.currentBookedGames.contains(game)
                        
                        HStack {
                            Image(systemName: selectedGames.contains(game) ? "checkmark.square.fill" : (isGameBooked ? "x.square.fill" : "square"))
                                .foregroundColor(selectedGames.contains(game) ? .green : (isGameBooked ? .gray : service.themeColor))
                            
                            Text(game)
                                .strikethrough(isGameBooked)
                                .foregroundColor(isGameBooked ? .gray : .primary)
                            
                            Spacer()
                            
                            if isGameBooked {
                                Text("In Use")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !isGameBooked else { return }
                            
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
                
                // ⭐️⭐️⭐️ จุดที่แก้ไข ⭐️⭐️⭐️
                // เปลี่ยนจาก joinQueue เป็น createReservation
                appState.createReservation(
                    service: service,
                    slotID: slotID,
                    timeSlot: nil, // ไม่มีรอบเวลา (Walk-in)
                    items: games
                )
                dismiss()
            }) {
                // เปลี่ยนข้อความปุ่ม
                Text("Confirm Booking (2 Hrs)")
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(isSelectionValid ? Color.green : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!isSelectionValid)
            .padding()
        }
        .navigationTitle(service.name)
        .onAppear {
            appState.listenToServiceBookings(service: service.name, timeSlot: nil)
            appState.listenToBookedGames()
        }
        .onDisappear {
            appState.stopListeningToServiceBookings()
            appState.stopListeningToBookedGames()
        }
    }
}

// (ส่วน BoardGameTableView ด้านล่างเหมือนเดิมครับ ไม่ต้องแก้)
struct BoardGameTableView: View {
    let tableNumber: Int
    @Binding var selectedTable: Int?
    let bookedSlots: Set<String>
    let themeColor: Color
    
    private var slotID: String { "Table \(tableNumber)" }
    
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
