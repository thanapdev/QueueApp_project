//
//  CoWorkingBookingView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 17/11/2568 BE.
//


import SwiftUI

// MARK: - 1. CoWorkingBookingView
struct CoWorkingBookingView: View {
    
    // MARK: - Properties
    @EnvironmentObject var appState: AppState // 👈 รับ "สมอง"
    @Environment(\.dismiss) var dismiss // 👈 (สำหรับปิดหน้าจอ)
    let service: LibraryService
    
    let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    
    // MARK: - State
    @State private var selectedSeat: Int? = nil // 👈 เก็บ 1 ที่นั่ง
    @State private var bookedSeats: Set<Int> = [3, 8] // (ข้อมูลจำลอง)

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
                                selectedSeat: $selectedSeat, // 👈 ส่ง Binding 1 ที่
                                bookedSeats: bookedSeats,
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
                    // ⭐️ สั่ง AppState ให้สร้างการจอง
                    appState.createReservation(service: service, details: "Slot \(seat)")
                    dismiss() // ปิดหน้าจอ
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
    }
}

// MARK: - 2. SeatView
// (ปุ่ม "ที่นั่ง" ที่ใช้เฉพาะใน CoWorking)
struct SeatView: View {
    let seatNumber: Int
    @Binding var selectedSeat: Int? // 👈 รับ Binding 1 ที่
    let bookedSeats: Set<Int>
    let themeColor: Color
    
    // Logic การแสดงสี
    var isBooked: Bool { bookedSeats.contains(seatNumber) }
    var isSelected: Bool { selectedSeat == seatNumber } // 👈 Logic เลือก 1 ที่
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
            // Logic กดเลือก/ยกเลิก
            if isSelected { selectedSeat = nil } else { selectedSeat = seatNumber }
        }) {
            VStack {
                Image(systemName: "chair.lounge.fill")
                Text("Slot \(seatNumber)")
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