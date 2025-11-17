//
//  CoWorkingBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//


import SwiftUI

struct CoWorkingBookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let service: LibraryService
    
    let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    
    // MARK: - State
    @State private var selectedSeat: Int? = nil
    // ⭐️ (R1) ลบ @State private var bookedSeats ทิ้ง
    
    // MARK: - Body
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Text("เลือกช่องที่ต้องการจอง").font(.title2).fontWeight(.bold).padding(.top)
                    LegendView(service: service).padding(.bottom)
                    
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(1...15, id: \.self) { seatNumber in
                            SeatView(
                                seatNumber: seatNumber,
                                selectedSeat: $selectedSeat,
                                // ⭐️ (R1) ส่ง Set ของช่องที่จองแล้ว (จาก AppState)
                                bookedSlots: appState.currentServiceBookedSlots,
                                themeColor: service.themeColor
                            )
                        }
                    }
                    .padding()
                }
            }
            Spacer()
            
            // MARK: - Action Button
            Button(action: {
                if let seat = selectedSeat {
                    let slotID = "Slot \(seat)"
                    // ⭐️ (R1) สั่ง AppState ให้สร้างการจอง (Reservation)
                    appState.createReservation(
                        service: service,
                        slotID: slotID, // 👈 ส่ง slotID
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
                    .cornerRadius(12)
            }
            .disabled(selectedSeat == nil)
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

struct SeatView: View {
    let seatNumber: Int
    @Binding var selectedSeat: Int?
    let bookedSlots: Set<String> // 👈 (R1) รับ Set<String> จาก AppState
    let themeColor: Color
    
    private var slotID: String { "Slot \(seatNumber)" } // 👈 (R1)
    
    // ⭐️ (R1) แก้ Logic isBooked
    var isBooked: Bool { bookedSlots.contains(slotID) }
    var isSelected: Bool { selectedSeat == seatNumber }
    
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
        Button(action: {
            if isSelected { selectedSeat = nil } else { selectedSeat = seatNumber }
        }) {
            VStack {
                Image(systemName: "chair.lounge.fill")
                Text(slotID) // 👈 (R1)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(seatColor)
            .foregroundColor(textColor)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? .green : Color.clear, lineWidth: 2))
        }
        .disabled(isBooked) // ⭐️ (R1) ถ้า isBooked = true จะกดไม่ได้
    }
}
