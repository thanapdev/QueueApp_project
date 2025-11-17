import SwiftUI
import Combine // 👈 1. Import Combine เพื่อใช้ Timer

// MARK: - 0. Booking State (สำคัญมาก)
// ⭐️ เปลี่ยนชื่อจาก AppState เป็น BookingState เพื่อไม่ให้ซ้ำ
class BookingState: ObservableObject {
    
    // R3: ระบบจองได้แค่ครั้งเดียว (เก็บได้แค่ 1 อย่าง)
    // 1. สำหรับการ "จอง" (Reservation: Co-working, Netflix)
    @Published var reservation: (service: LibraryService, details: String)? = nil
    
    // 2. สำหรับการ "ต่อคิว" (Queue: Board Game)
    @Published var queue: (service: LibraryService, table: Int, games: [String])? = nil
    
    // R2, R4: เวลานับถอยหลัง (3 นาที = 180 วินาที)
    @Published var queueTimeRemaining: TimeInterval = 180
    @Published var showQueueAlert: Bool = false // R5: สำหรับแจ้งเตือน
    
    // ตัวจัดการ Timer
    private var timerSubscription: AnyCancellable?
    
    // เช็กว่ามีจองอยู่ไหม (R3)
    var hasActiveBooking: Bool {
        reservation != nil || queue != nil
    }
    
    // R4: เริ่มนับถอยหลัง
    func startQueueTimer() {
        // ตั้งค่าเวลาเริ่มต้น
        self.queueTimeRemaining = 180
        
        // สร้าง Timer ให้ทำงานทุก 1 วินาที
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.queueTimeRemaining > 0 {
                    self.queueTimeRemaining -= 1
                } else {
                    // R5: เวลาหมด!
                    self.stopQueueTimer()
                    self.showQueueAlert = true // สั่งให้ Alert เด้ง
                    self.queue = nil // ล้างคิว
                }
            }
    }
    
    // หยุด Timer
    func stopQueueTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    // ล้างการจอง/คิว ทั้งหมด
    func cancelAllBookings() {
        reservation = nil
        queue = nil
        stopQueueTimer()
    }
}


// MARK: - 1. Data Model (โมเดลข้อมูลบริการ)
struct LibraryService: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let iconName: String
    let themeColor: Color
}



// MARK: - 2. Service Data (ข้อมูลบริการของคุณ)
let libraryServices: [LibraryService] = [
    LibraryService(name: "Co-working Space",
                   description: "จองพื้นที่ทำงานกลุ่มและห้องประชุม",
                   iconName: "person.3.fill",
                   themeColor: .blue),
    LibraryService(name: "Netflix & Chill",
                   description: "ห้องดูหนังพร้อมสตรีมมิ่งส่วนตัว",
                   iconName: "play.tv.fill",
                   themeColor: .red),
    LibraryService(name: "Board Game",
                   description: "ยืมบอร์ดเกมและใช้โซนเล่นเกม",
                   iconName: "gamecontroller.fill",
                   themeColor: .purple), // 👈 ธีมสีม่วง
    LibraryService(name: "Green-Screen Room",
                   description: "ห้องถ่ายทำพร้อมฉากกรีนสกรีน",
                   iconName: "camera.fill",
                   themeColor: .green)
]


// MARK: - 3. Main View (หน้าหลักสำหรับจองบริการ)
struct BookingView: View {
    // ⭐️ 2. สร้าง BookingState ขึ้นมา (ไม่ซ้ำกับ AppState เดิมของคุณแล้ว)
    @StateObject private var bookingState = BookingState()
    
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)

    var body: some View {
        // ⭐️ 3. Vstack คลุมทั้งหมด เพื่อให้ Banner อยู่ข้างล่าง
        VStack {
            NavigationStack {
                ZStack {
                    // Background
                    LinearGradient(gradient: Gradient(colors: [swuGray.opacity(0.3), swuRed.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                        .edgesIgnoringSafeArea(.all)
                    
                    // Shape Background
                    GeometryReader { geometry in
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.24, green: 0.27, blue: 0.68, alpha: 1)), Color(#colorLiteral(red: 0.14, green: 0.64, blue: 0.96, alpha: 1))]), startPoint: .top, endPoint: .bottom))
                            .frame(width: 200, height: 200)
                            .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.1)
                        
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.97, green: 0.32, blue: 0.18, alpha: 1)), Color(#colorLiteral(red: 0.94, green: 0.59, blue: 0.1, alpha: 1))]), startPoint: .top, endPoint: .bottom))
                            .frame(width: 200, height: 200)
                            .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.9)
                    }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            LazyVGrid(columns: gridColumns, spacing: 16) {
                                ForEach(libraryServices) { service in
                                    NavigationLink(destination: BookingDetailView(service: service)) {
                                        ServiceCardView(service: service)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 10)
                    }
                }
                .navigationTitle("Library Services")
                .navigationBarTitleDisplayMode(.large)
            }
            .environmentObject(bookingState) // ⭐️ 4. ส่ง BookingState ไปให้ทุก View
            
            // ⭐️ 5. (R3) แสดง Banner นี้ ถ้ามีการจอง/เข้าคิวอยู่
            if bookingState.hasActiveBooking {
                MyBookingBannerView()
                    .environmentObject(bookingState) // ⭐️ ส่ง BookingState
            }
        }
    }
}


// MARK: - 4. Service Card (การ์ดแสดงผลแต่ละบริการ)
struct ServiceCardView: View {
    let service: LibraryService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: service.iconName)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(service.themeColor)
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(service.themeColor.opacity(0.1))
                .cornerRadius(12)
            
            Text(service.name)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text(service.description)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            Spacer()
            
            Text("Book Now")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(service.themeColor)
                .cornerRadius(20)
        }
        .padding()
        .frame(minHeight: 240)
        .background(.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// ⭐️ START: Banner, Alert, Overlay (ของใหม่)

// MARK: - 5. (R4, R5) Banner แสดงการจอง/คิว
struct MyBookingBannerView: View {
    @EnvironmentObject var bookingState: BookingState // ⭐️ เปลี่ยนเป็น BookingState
    
    // R5: Alert ที่จะเด้งขึ้นมา
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 8) {
            if let reservation = bookingState.reservation {
                // --- 1. ถ้าเป็นการ "จอง" (Co-working/Netflix) ---
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Reservation")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(reservation.service.name): \(reservation.details)")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Button("Cancel") { bookingState.cancelAllBookings() } // ⭐️
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.5))
                }
            } else if let queue = bookingState.queue {
                // --- 2. ถ้าเป็นการ "ต่อคิว" (Board Game) ---
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Queue: \(queue.service.name)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        // R4: เวลานับถอยหลัง
                        Text("Your turn in: \(formatTime(bookingState.queueTimeRemaining))") // ⭐️
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Button("Cancel") { bookingState.cancelAllBookings() } // ⭐️
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.5))
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom))
        // R5: เมื่อ bookingState.showQueueAlert เป็น true ให้แสดง Alert นี้
        .alert("ถึงคิวของคุณแล้ว!", isPresented: $bookingState.showQueueAlert) { // ⭐️
            Button("OK", role: .cancel) { }
        } message: {
            Text("กรุณามารับ board game จากเจ้าหน้าที่")
        }
    }
    
    // ฟังก์ชันแปลงวินาทีเป็น 00:00
    func formatTime(_ totalSeconds: TimeInterval) -> String {
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 5. (R3) View สำหรับบังหน้าจอ ถ้าจองแล้ว
struct AlreadyBookedView: View {
    @EnvironmentObject var bookingState: BookingState // ⭐️ เปลี่ยนเป็น BookingState
    
    var body: some View {
        VStack {
            Text("You already have an active booking")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            // แสดงรายละเอียดการจอง
            if let reservation = bookingState.reservation {
                Text("\(reservation.service.name)")
                Text("\(reservation.details)")
            } else if let queue = bookingState.queue {
                Text("\(queue.service.name)")
                Text("Table \(queue.table) | \(queue.games.count) Games")
            }
            
            Button("Cancel Booking") {
                bookingState.cancelAllBookings() // ⭐️
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.8))
        .foregroundColor(.white)
    }
}
// ⭐️ END: Banner, Alert, Overlay

// MARK: - 6. Detail Page (หน้าสำหรับกดไปต่อ)
// ⭐️ (A) แก้ไข BookingDetailView ให้เป็น "ตัวสลับฉาก"
struct BookingDetailView: View {
    @EnvironmentObject var bookingState: BookingState // ⭐️ เปลี่ยนเป็น BookingState
    let service: LibraryService
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(red: 150/255, green: 150/255, blue: 150/255).opacity(0.3), Color(red: 190/255, green: 50/255, blue: 50/255).opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            // ⭐️ (R3) เช็กว่ามีจองอยู่ไหม ถ้ามี ให้บังหน้าจอ
            if bookingState.hasActiveBooking { // ⭐️
                AlreadyBookedView()
            } else {
                // ถ้าไม่มีจอง ให้แสดง View ตาม service
                switch service.name {
                case "Co-working Space":
                    CoWorkingBookingView(service: service)
                case "Netflix & Chill":
                    NetflixBookingView(service: service)
                case "Board Game": // ⭐️ R1: เพิ่ม Board Game
                    BoardGameBookingView(service: service)
                default:
                    Text("หน้าสำหรับจอง: \(service.name)")
                        .font(.title)
                        .navigationTitle(service.name)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ⭐️ START: โค้ดใหม่สำหรับหน้า Board Game (R1)
struct BoardGameBookingView: View {
    @EnvironmentObject var bookingState: BookingState // ⭐️ เปลี่ยนเป็น BookingState
    @Environment(\.dismiss) var dismiss
    let service: LibraryService
    
    // Grid 3 คอลัมน์ (สำหรับโต๊ะ)
    let tableColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    // --- Data (จำลอง) ---
    @State private var mockGames = ["Catan", "Monopoly", "Clue", "Risk", "Uno", "Jenga", "Exploding Kittens"]
    @State private var bookedTables: Set<Int> = [2, 5] // โต๊ะ 2 กับ 5 ไม่ว่าง
    
    // --- User Selection ---
    @State private var selectedTable: Int? = nil
    @State private var selectedGames: Set<String> = []
    
    // เช็กว่าพร้อมจองไหม (R1: 1 โต๊ะ และ 1-3 เกม)
    var isSelectionValid: Bool {
        selectedTable != nil && (1...3).contains(selectedGames.count)
    }

    var body: some View {
        VStack { // Vstack หลัก (สำหรับ ScrollView + ปุ่ม)
            ScrollView {
                VStack(alignment: .leading) {
                    
                    // --- 1. เลือกโต๊ะ (1 โต๊ะ) ---
                    Text("1. Select a Table (1)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding([.top, .horizontal])
                    
                    LazyVGrid(columns: tableColumns, spacing: 10) {
                        ForEach(1...6, id: \.self) { tableNum in
                            BoardGameTableView(
                                tableNumber: tableNum,
                                selectedTable: $selectedTable,
                                bookedTables: bookedTables,
                                themeColor: service.themeColor
                            )
                        }
                    }
                    .padding(.horizontal)

                    Divider().padding()

                    // --- 2. เลือกเกม (1-3 เกม) ---
                    Text("2. Select Games (1-3)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    Text("Selected: \(selectedGames.count)")
                        .font(.caption)
                        .padding(.horizontal)
                    
                    // ลิสต์เกมให้เลือก
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
                                // ถ้ามีอยู่แล้ว -> เอาออก
                                selectedGames.remove(game)
                            } else if selectedGames.count < 3 {
                                // ถ้ายังไม่ครบ 3 -> เพิ่ม
                                selectedGames.insert(game)
                            }
                            // ถ้าครบ 3 แล้ว จะเพิ่มอีกไม่ได้
                        }
                    }
                    .frame(height: 300) // จำกัดความสูงของ List
                    .listStyle(.plain)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            } // End ScrollView
            
            Spacer()
            
            // --- 3. ปุ่มยืนยัน (R2: Join Queue) ---
            Button(action: {
                guard let table = selectedTable else { return }
                // ⭐️ R2, R4: สั่งให้ BookingState เข้าคิวและเริ่มจับเวลา
                bookingState.queue = (service, table, Array(selectedGames))
                bookingState.startQueueTimer()
                dismiss() // ปิดหน้าจอนี้
            }) {
                Text("Join Queue")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSelectionValid ? Color.green : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!isSelectionValid)
            .padding()
        }
        .navigationTitle(service.name)
    }
}

// View สำหรับ "โต๊ะ Board Game"
struct BoardGameTableView: View {
    let tableNumber: Int
    @Binding var selectedTable: Int?
    let bookedTables: Set<Int>
    let themeColor: Color // สีม่วง
    
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
                Image(systemName: "gamecontroller.fill") // ⭐️ ไอคอน
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
// ⭐️ END: โค้ด Board Game


// MARK: - Co-Working Space (ของเดิมที่แก้แล้ว)
struct CoWorkingBookingView: View {
    @EnvironmentObject var bookingState: BookingState // ⭐️ R3
    @Environment(\.dismiss) var dismiss // ⭐️ R3
    let service: LibraryService
    
    let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    
    @State private var selectedSeat: Int? = nil // ⭐️ แก้เป็น 1 ที่
    @State private var bookedSeats: Set<Int> = [3, 8]

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Text("เลือกช่องที่ต้องการจอง")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    LegendView(service: service).padding(.bottom)
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(1...15, id: \.self) { seatNumber in
                            SeatView(
                                seatNumber: seatNumber,
                                selectedSeat: $selectedSeat, // ⭐️ ส่ง 1 ที่
                                bookedSeats: bookedSeats,
                                themeColor: service.themeColor
                            )
                        }
                    }
                    .padding()
                }
            }
            Spacer()
            Button(action: {
                // ⭐️ R3: บันทึกการจอง
                if let seat = selectedSeat {
                    bookingState.reservation = (service, "Slot \(seat)") // ⭐️
                    dismiss()
                }
            }) {
                Text("Confirm Booking")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedSeat == nil ? Color.gray : Color.green)
                    .cornerRadius(12)
            }
            .disabled(selectedSeat == nil)
            .padding()
        }
        .navigationTitle(service.name)
    }
}

// ⭐️ SeatView (ของเดิมที่แก้แล้ว)
struct SeatView: View {
    let seatNumber: Int
    @Binding var selectedSeat: Int? // ⭐️ แก้เป็น 1 ที่
    let bookedSeats: Set<Int>
    let themeColor: Color
    
    var isBooked: Bool { bookedSeats.contains(seatNumber) }
    var isSelected: Bool { selectedSeat == seatNumber } // ⭐️ แก้ Logic

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
            // ⭐️ แก้ Logic
            if isSelected {
                selectedSeat = nil
            } else {
                selectedSeat = seatNumber
            }
        }) {
            VStack {
                Image(systemName: "chair.lounge.fill")
                    .font(.title2)
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

// MARK: - Netflix (ของเดิมที่แก้แล้ว)
struct NetflixBookingView: View {
    @EnvironmentObject var bookingState: BookingState // ⭐️ R3
    @Environment(\.dismiss) var dismiss // ⭐️ R3
    let service: LibraryService
    
    let roomColumns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    let slotColumns = [GridItem(.flexible()), GridItem(.flexible())]
    
    @State private var bookedRooms: Set<Int> = [3]
    @State private var timeSlots: [TimeSlot] = []
    
    @State private var selectedRoom: Int? = nil
    @State private var selectedSlot: TimeSlot? = nil
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Text("1. Select a Room").font(.title2).fontWeight(.bold).padding(.top)
                    LegendView(service: service).padding(.bottom, 5)
                    LazyVGrid(columns: roomColumns, spacing: 15) {
                        ForEach(1...6, id: \.self) { roomNumber in
                            NetflixRoomView(
                                roomNumber: roomNumber,
                                selectedRoom: $selectedRoom,
                                bookedRooms: bookedRooms,
                                themeColor: service.themeColor
                            )
                        }
                    }
                    .padding(.horizontal)
                    Divider().padding()
                    Text("2. Select a Time Slot").font(.title2).fontWeight(.bold)
                    LazyVGrid(columns: slotColumns, spacing: 10) {
                        ForEach(timeSlots) { slot in
                            TimeSlotView(
                                slot: slot,
                                selectedSlot: $selectedSlot,
                                themeColor: service.themeColor
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            Spacer()
            Button(action: {
                // ⭐️ R3: บันทึกการจอง
                if let room = selectedRoom, let slot = selectedSlot {
                    bookingState.reservation = (service, "Room \(room) @ \(slot.time)") // ⭐️
                    dismiss()
                }
            }) {
                Text("Confirm Booking")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedRoom == nil || selectedSlot == nil ? Color.gray : Color.green)
                    .cornerRadius(12)
            }
            .disabled(selectedRoom == nil || selectedSlot == nil)
            .padding()
        }
        .navigationTitle(service.name)
        .onAppear { loadMockTimeSlots() }
    }
    
    func loadMockTimeSlots() {
        self.timeSlots = [
            TimeSlot(time: "10:00 - 12:00", isBooked: false),
            TimeSlot(time: "12:00 - 14:00", isBooked: false),
            TimeSlot(time: "14:00 - 16:00", isBooked: false),
            TimeSlot(time: "16:00 - 18:00", isBooked: false),
            TimeSlot(time: "18:00 - 20:00", isBooked: true)
        ]
    }
}

// (ย้าย struct ย่อยๆ มารวมกัน)
struct TimeSlot: Identifiable, Hashable {
    let id = UUID()
    let time: String
    var isBooked: Bool = false
}

struct NetflixRoomView: View {
    let roomNumber: Int
    @Binding var selectedRoom: Int?
    let bookedRooms: Set<Int>
    let themeColor: Color
    
    var isBooked: Bool { bookedRooms.contains(roomNumber) }
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
                Image(systemName: "play.tv.fill")
                Text("Room \(roomNumber)")
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

struct TimeSlotView: View {
    let slot: TimeSlot
    @Binding var selectedSlot: TimeSlot?
    let themeColor: Color
    var isBooked: Bool { slot.isBooked }
    var isSelected: Bool { selectedSlot?.id == slot.id }
    var slotColor: Color {
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
        Button(action: { selectedSlot = slot }) {
            Text(slot.time)
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(slotColor)
                .foregroundColor(textColor)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? .green : Color.clear, lineWidth: 2))
        }
        .disabled(isBooked)
    }
}

// ⭐️ LegendView (ของเดิม)
struct LegendView: View {
    let service: LibraryService
    var body: some View {
        HStack(spacing: 20) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4).fill(service.themeColor.opacity(0.3)).frame(width: 20, height: 20)
                Text("Available")
            }
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4).fill(Color.green).frame(width: 20, height: 20)
                Text("Selected")
            }
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4).fill(Color.gray).frame(width: 20, height: 20)
                Text("Booked")
            }
        }
        .font(.caption)
    }
}
// ⭐️ END: โค้ด Co-Working
// ⭐️


// MARK: - 7. Preview
#Preview {
    BookingView()
        .environmentObject(BookingState()) // ⭐️ 6. ต้องใส่ BookingState ให้ Preview ด้วย
}
