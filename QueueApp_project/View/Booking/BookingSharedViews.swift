import SwiftUI

// ServiceCardView (เหมือนเดิม)
struct ServiceCardView: View {
    let service: LibraryService
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: service.iconName).font(.system(size: 40, weight: .bold)).foregroundColor(service.themeColor).frame(maxWidth: .infinity, minHeight: 100).background(service.themeColor.opacity(0.1)).cornerRadius(12)
            Text(service.name).font(.headline).fontWeight(.bold).foregroundColor(.black)
            Text(service.description).font(.caption).foregroundColor(.gray).lineLimit(2)
            Spacer()
            Text("Book Now").font(.caption).fontWeight(.bold).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 6).background(service.themeColor).cornerRadius(20)
        }
        .padding().frame(minHeight: 240).background(.white.opacity(0.8)).cornerRadius(16).shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// ⭐️ Banner (อัปเกรด)
struct MyBookingBannerView: View {
    @EnvironmentObject var appState: AppState
    
    var activeBooking: AppState.Booking? {
        appState.activeReservation?.data ?? appState.activeQueue?.data
    }

    var body: some View {
        VStack(spacing: 12) {
            if let booking = activeBooking {
                HStack {
                    VStack(alignment: .leading) {
                        Text(booking.status == "In-Use" ? "Currently Using" : (booking.status == "Queued" ? "Waiting in Queue" : "Reserved"))
                            .font(.caption).foregroundColor(.white.opacity(0.7))
                        
                        Text("\(booking.serviceName): \(booking.details)")
                            .font(.headline).fontWeight(.bold)
                        
                        // ⭐️ แสดงเวลาถอยหลัง
                        Text("Time Remaining: \(formatTime(appState.timeRemaining))")
                            .font(.title3).fontWeight(.heavy)
                            .foregroundColor(appState.timeRemaining < 600 ? .red : .green) // สีแดงถ้าเหลือน้อย
                    }
                    
                    Spacer()
                    
                    // ปุ่ม Cancel (เสมอ)
                    Button("End/Cancel") { appState.cancelActiveBooking() }
                        .buttonStyle(.bordered).tint(.white.opacity(0.8))
                }
                
                // ⭐️ ปุ่ม Extend (โชว์เฉพาะตอนแจ้งเตือน)
                if appState.showExtendAlert {
                    Button(action: {
                        appState.extendBooking()
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Extend for 2 Hours")
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.85))
        .foregroundColor(.white)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom))
        .alert("หมดเวลาแล้ว!", isPresented: $appState.showQueueAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("กรุณาติดต่อเจ้าหน้าที่เพื่อคืนอุปกรณ์/เช็คเอาท์")
        }
    }
    
    func formatTime(_ totalSeconds: TimeInterval) -> String {
        let h = Int(totalSeconds) / 3600
        let m = (Int(totalSeconds) % 3600) / 60
        let s = Int(totalSeconds) % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        else { return String(format: "%02d:%02d", m, s) }
    }
}

// AlreadyBookedView (เหมือนเดิม)
struct AlreadyBookedView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        VStack {
            Text("You have an active session").font(.title2).fontWeight(.bold).padding()
            if let b = appState.activeReservation?.data ?? appState.activeQueue?.data {
                Text(b.serviceName); Text(b.details)
            }
            Button("End Session") { appState.cancelActiveBooking() }.buttonStyle(.borderedProminent).tint(.red).padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).background(.black.opacity(0.8)).foregroundColor(.white)
    }
}

// LegendView & TimeSlotView (เหมือนเดิม)
struct LegendView: View {
    let service: LibraryService
    var body: some View {
        HStack(spacing: 20) {
            HStack(spacing: 5) { RoundedRectangle(cornerRadius: 4).fill(service.themeColor.opacity(0.3)).frame(width: 20, height: 20); Text("Available") }
            HStack(spacing: 5) { RoundedRectangle(cornerRadius: 4).fill(Color.green).frame(width: 20, height: 20); Text("Selected") }
            HStack(spacing: 5) { RoundedRectangle(cornerRadius: 4).fill(Color.gray).frame(width: 20, height: 20); Text("Booked") }
        }.font(.caption).padding(.leading, 10)
    }
}
struct TimeSlotView: View {
    let slot: TimeSlot; @Binding var selectedSlot: TimeSlot?; let themeColor: Color
    var isBooked: Bool { slot.isBooked }; var isSelected: Bool { selectedSlot?.id == slot.id }
    var slotColor: Color { if isBooked { return .gray } else if isSelected { return .green } else { return themeColor.opacity(0.3) } }
    var body: some View {
        Button(action: { selectedSlot = slot }) {
            Text(slot.time).font(.system(size: 14, weight: .bold)).frame(maxWidth: .infinity).padding(.vertical, 16).background(slotColor).foregroundColor(isBooked ? .white.opacity(0.7) : .white).cornerRadius(8)
        }.disabled(isBooked)
    }
}
