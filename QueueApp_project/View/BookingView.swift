import SwiftUI

// MARK: - 1. Data Model (โมเดลข้อมูลบริการ)
struct LibraryService: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let iconName: String
    let themeColor: Color
}



// MARK: - 2. Service Data (ข้อมูลบริการของคุณ)
// คุณสามารถเพิ่ม/แก้ไข รายการบริการได้ตรงนี้
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
                   themeColor: .purple),
    LibraryService(name: "Green-Screen Room",
                   description: "ห้องถ่ายทำพร้อมฉากกรีนสกรีน",
                   iconName: "camera.fill",
                   themeColor: .green)
]


// MARK: - 3. Main View (หน้าหลักสำหรับจองบริการ)
struct BookingView: View { // 👈 (1) เปลี่ยนชื่อ struct หลัก
    
    // กำหนด layout ของ grid เป็น 2 คอลัมน์
    let gridColumns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    let swuGray = Color(red: 150/255, green: 150/255, blue: 150/255)
    let swuRed = Color(red: 190/255, green: 50/255, blue: 50/255)

    var body: some View {
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
                ScrollView { // ⭐️ ย้าย ScrollView มาไว้ข้างนอก
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // 4. ตาราง Grid แสดงบริการ (Services Grid)
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(libraryServices) { service in
                                // เมื่อกดที่การ์ด ให้ไปหน้า Detail (ยังเป็นหน้าเปล่า)
                                NavigationLink(destination: BookingDetailView(service: service)) { // 👈 ส่งไป BookingDetailView
                                    ServiceCardView(service: service)
                                }
                                .buttonStyle(PlainButtonStyle()) // ลบสไตล์ปุ่มสีฟ้าของ Link
                            }
                        }
                        .padding(.horizontal)
                        
                    }
                    .padding(.top, 10)
                }
            }
            .navigationTitle("Library Services") // ตั้งชื่อหน้า
            .navigationBarTitleDisplayMode(.large)
        }
    }
}


// MARK: - 4. Service Card (การ์ดแสดงผลแต่ละบริการ)
struct ServiceCardView: View {
    let service: LibraryService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1. ไอคอน
            Image(systemName: service.iconName)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(service.themeColor)
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(service.themeColor.opacity(0.1)) // พื้นหลังไอคอน
                .cornerRadius(12)
            
            // 2. ชื่อบริการ
            Text(service.name)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            // 3. คำอธิบาย
            Text(service.description)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(2) // จำกัด 2 บรรทัด
            
            Spacer() // ดันปุ่มไปอยู่ข้างล่าง
            
            // 4. ปุ่ม "Book Now" (จำลองดีไซน์)
            Text("Book Now")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(service.themeColor) // ใช้สีตามธีมบริการ
                .cornerRadius(20)
        }
        .padding()
        .frame(minHeight: 240) // ทำให้การ์ดสูงเท่ากัน
        .background(.white.opacity(0.8)) // ⭐️ ปรับให้พื้นหลังโปร่งแสงเล็กน้อย
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2) // เงา
    }
}


// MARK: - 6. Detail Page (หน้าสำหรับกดไปต่อ)
// ⭐️ (A) แก้ไข BookingDetailView ให้เป็น "ตัวสลับฉาก"
struct BookingDetailView: View {
    let service: LibraryService
    
    var body: some View {
        ZStack {
            // 1. ใส่ Background แบบเดียวกับหน้า BookingView
            LinearGradient(gradient: Gradient(colors: [Color(red: 150/255, green: 150/255, blue: 150/255).opacity(0.3), Color(red: 190/255, green: 50/255, blue: 50/255).opacity(0.3)]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            // 2. เช็กชื่อ service
            if service.name == "Co-working Space" {
                // 3. ถ้าใช่ ให้แสดงหน้าจองที่นั่ง
                CoWorkingBookingView(service: service)
                
            // ⭐️ 4. เพิ่ม else if สำหรับ Netflix
            } else if service.name == "Netflix & Chill" {
                NetflixBookingView(service: service) // 👈 หน้าใหม่ (ที่แก้ไขแล้ว)
                
            } else {
                // 5. ถ้าเป็น Service อื่น ให้แสดงแบบเดิม
                Text("หน้าสำหรับจอง: \(service.name)")
                    .font(.title)
                    .navigationTitle(service.name)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ⭐️ START: โค้ดใหม่สำหรับหน้า Netflix & Chill (ฉบับแก้ไข)
// ⭐️ (E) โมเดลสำหรับรอบเวลา (ยังใช้เหมือนเดิม)
struct TimeSlot: Identifiable, Hashable {
    let id = UUID()
    let time: String
    var isBooked: Bool = false
}

// ⭐️ (F) สร้างหน้าสำหรับจอง Netflix (เลือกห้อง + เวลา)
struct NetflixBookingView: View {
    let service: LibraryService
    
    // Grid 3 คอลัมน์ (สำหรับ 6 ห้อง)
    let roomColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    // Grid 2 คอลัมน์ (สำหรับรอบเวลา)
    let slotColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // --- State ที่ต้องใช้ ---
    // 1. State (จำลอง) ว่าห้องไหนจองแล้ว (เช่น ห้อง 3 ซ่อม)
    @State private var bookedRooms: Set<Int> = [3]
    // 2. State (จำลอง) รอบเวลาที่เต็ม (เช่น 18:00 เต็ม)
    @State private var timeSlots: [TimeSlot] = []
    
    // --- State ที่ผู้ใช้เลือก ---
    // 1. ห้องที่เลือก (เลือกได้แค่ 1)
    @State private var selectedRoom: Int? = nil
    // 2. รอบเวลาที่เลือก (เลือกได้แค่ 1)
    @State private var selectedSlot: TimeSlot? = nil
    
    var body: some View {
        VStack { // ⭐️ Vstack หลัก (สำหรับ ScrollView + ปุ่ม)
            ScrollView {
                VStack {
                    // --- 1. ส่วนเลือกห้อง ---
                    Text("1. Select a Room")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    LegendView(service: service) // ⭐️ ใช้ LegendView ซ้ำ
                        .padding(.bottom, 5)

                    LazyVGrid(columns: roomColumns, spacing: 15) {
                        ForEach(1...6, id: \.self) { roomNumber in
                            // ⭐️ ใช้ View ใหม่ (NetflixRoomView)
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

                    // --- 2. ส่วนเลือกรอบเวลา ---
                    Text("2. Select a Time Slot")
                        .font(.title2)
                        .fontWeight(.bold)

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
            } // ⭐️ End ScrollView
            
            Spacer()
            
            // --- 3. ปุ่มยืนยัน ---
            Button(action: {
                if let room = selectedRoom, let slot = selectedSlot {
                    print("จอง Netflix: Room \(room) @ \(slot.time)")
                }
            }) {
                Text("Confirm Booking")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedRoom == nil || selectedSlot == nil ? Color.gray : Color.green) // ⭐️ เช็ก 2 ค่า
                    .cornerRadius(12)
            }
            .disabled(selectedRoom == nil || selectedSlot == nil) // ⭐️ ปิดปุ่มถ้ายังไม่เลือกครบ
            .padding()
        }
        .navigationTitle(service.name)
        .onAppear {
            // โหลดข้อมูลรอบเวลา (จำลอง)
            loadMockTimeSlots()
        }
    }
    
    // ฟังก์ชันจำลองการโหลดข้อมูลรอบเวลา (ไม่ต้องใช้ Date แล้ว)
    func loadMockTimeSlots() {
        self.timeSlots = [
            TimeSlot(time: "10:00 - 12:00", isBooked: false),
            TimeSlot(time: "12:00 - 14:00", isBooked: false),
            TimeSlot(time: "14:00 - 16:00", isBooked: false),
            TimeSlot(time: "16:00 - 18:00", isBooked: false),
            TimeSlot(time: "18:00 - 20:00", isBooked: true) // ⭐️ 6 โมงเย็นเต็ม
        ]
    }
}

// ⭐️ (G) สร้าง View ของ "ห้อง Netflix" (คล้าย SeatView แต่เลือกได้อันเดียว)
struct NetflixRoomView: View {
    let roomNumber: Int
    @Binding var selectedRoom: Int? // ⭐️ ใช้ Int? (Optional)
    let bookedRooms: Set<Int>
    let themeColor: Color // สีประจำ service (สีแดง)
    
    // เช็กสถานะ
    var isBooked: Bool { bookedRooms.contains(roomNumber) }
    var isSelected: Bool { selectedRoom == roomNumber } // ⭐️ เช็กว่าตรงกันไหม

    // เลือกสีตามสถานะ
    var seatColor: Color {
        if isBooked { return .gray }
        if isSelected { return .green }
        return themeColor.opacity(0.3) // ว่าง = สีธีม (แดงอ่อน)
    }
    
    // สีตัวอักษร
    var textColor: Color {
        if isBooked { return .white.opacity(0.7) }
        if isSelected { return .white }
        return themeColor
    }

    var body: some View {
        Button(action: {
            // action ตอนกด
            selectedRoom = roomNumber // ⭐️ เลือกห้องนี้เลย
        }) {
            VStack {
                Image(systemName: "play.tv.fill") // ⭐️ ไอคอน Netflix
                    .font(.title2)
                Text("Room \(roomNumber)") // ⭐️ ข้อความ
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(seatColor)
            .foregroundColor(textColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? .green : Color.clear, lineWidth: 2)
            )
        }
        .disabled(isBooked) // กดไม่ได้ถ้าจองแล้ว
    }
}

// ⭐️ (H) สร้าง View ของ "รอบเวลา" (ของเดิมจากรอบที่แล้ว)
struct TimeSlotView: View {
    let slot: TimeSlot
    @Binding var selectedSlot: TimeSlot?
    let themeColor: Color

    var isBooked: Bool { slot.isBooked }
    var isSelected: Bool { selectedSlot?.id == slot.id } // ⭐️ เช็กด้วย ID

    // เลือกสีตามสถานะ
    var slotColor: Color {
        if isBooked { return .gray }
        if isSelected { return .green }
        return themeColor.opacity(0.3)
    }
    
    // สีตัวอักษร
    var textColor: Color {
        if isBooked { return .white.opacity(0.7) }
        if isSelected { return .white }
        return themeColor
    }

    var body: some View {
        Button(action: {
            selectedSlot = slot
        }) {
            Text(slot.time)
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(slotColor)
                .foregroundColor(textColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? .green : Color.clear, lineWidth: 2)
                )
        }
        .disabled(isBooked)
    }
}
// ⭐️ END: โค้ดใหม่สำหรับหน้า Netflix


// ⭐️ START: โค้ดสำหรับหน้า Co-Working Space (ของเดิม)
// ⭐️ (B) สร้างหน้าสำหรับจอง Co-Working
struct CoWorkingBookingView: View {
    let service: LibraryService
    
    // Grid 4 คอลัมน์
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    // 🔴 1. แก้ไขตรงนี้: เปลี่ยนจาก Set เป็น Int? (Optional)
    @State private var selectedSeat: Int? = nil // 👈 เปลี่ยนชื่อและชนิด
    
    // State (จำลอง) ว่ามีที่นั่ง "จองแล้ว"
    @State private var bookedSeats: Set<Int> = [3, 8] // สมมติว่าล็อก 3 กับ 8 ไม่ว่าง

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Text("เลือกช่องที่ต้องการจอง")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)

                    // 1. คำอธิบายสถานะ
                    LegendView(service: service)
                        .padding(.bottom)

                    // 2. Grid ของที่นั่ง
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(1...15, id: \.self) { seatNumber in
                            SeatView(
                                seatNumber: seatNumber,
                                // 🔴 2. ส่ง Binding ของตัวแปรใหม่
                                selectedSeat: $selectedSeat, // 👈 ส่งตัวนี้แทน
                                bookedSeats: bookedSeats,
                                themeColor: service.themeColor
                            )
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            // 3. ปุ่มยืนยัน
            Button(action: {
                // 🔴 3. อัปเดต action
                if let seat = selectedSeat {
                    print("จองที่นั่ง: \(seat)")
                }
            }) {
                Text("Confirm Booking")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    // 🔴 4. อัปเดตเงื่อนไขสี
                    .background(selectedSeat == nil ? Color.gray : Color.green)
                    .cornerRadius(12)
            }
            // 🔴 5. อัปเดตเงื่อนไข disabled
            .disabled(selectedSeat == nil)
            .padding()
            
        }
        .navigationTitle(service.name)
    }
}

// ⭐️ (C) สร้าง View ของ "ล็อก" หรือ "ที่นั่ง"
struct SeatView: View {
    let seatNumber: Int
    // 🔴 1. เปลี่ยน Binding ให้ตรงกัน
    @Binding var selectedSeat: Int?
    let bookedSeats: Set<Int>
    let themeColor: Color // สีประจำ service (สีฟ้า)
    
    // เช็กสถานะ
    var isBooked: Bool { bookedSeats.contains(seatNumber) }
    // 🔴 2. อัปเดต Logic การเช็ก isSelected
    var isSelected: Bool { selectedSeat == seatNumber } // 👈 เช็กว่าตรงกันไหม

    // เลือกสีตามสถานะ
    var seatColor: Color {
        if isBooked { return .gray } // จองแล้ว = สีเทา
        if isSelected { return .green } // กำลังเลือก = สีเขียว
        return themeColor.opacity(0.3) // ว่าง = สีธีม (ฟ้าอ่อน)
    }
    
    // สีตัวอักษร
    var textColor: Color {
        if isBooked { return .white.opacity(0.7) }
        if isSelected { return .white }
        return themeColor
    }

    var body: some View {
        Button(action: {
            // 🔴 3. อัปเดต action ตอนกด
            if isSelected {
                selectedSeat = nil // 👈 กดซ้ำเพื่อ "ยกเลิก" การเลือก
            } else {
                selectedSeat = seatNumber // 👈 เลือกที่นั่งนี้
            }
        }) {
            VStack {
                // ใช้ไอคอน "โต๊ะ" หรือ "เก้าอี้" ก็ได้
                Image(systemName: "chair.lounge.fill")
                    .font(.title2)
                Text("Slot \(seatNumber)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(seatColor)
            .foregroundColor(textColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? .green : Color.clear, lineWidth: 2)
            )
        }
        .disabled(isBooked) // ⭐️ กดไม่ได้ถ้าจองแล้ว
    }
}

// ⭐️ (D) สร้าง View อธิบายสัญลักษณ์สี (ใช้ซ้ำได้)
struct LegendView: View {
    let service: LibraryService
    
    var body: some View {
        HStack(spacing: 20) {
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(service.themeColor.opacity(0.3))
                    .frame(width: 20, height: 20)
                Text("Available")
            }
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green)
                    .frame(width: 20, height: 20)
                Text("Selected")
            }
            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray)
                    .frame(width: 20, height: 20)
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
    BookingView() // 👈 (2) เปลี่ยนชื่อใน Preview ให้ตรงกัน
}
