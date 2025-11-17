import SwiftUI

// MARK: - 1. Library Service Model
// (โมเดลสำหรับ "บริการ" 4 อย่าง)
struct LibraryService: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let iconName: String
    let themeColor: Color
}

// MARK: - 2. Mock Service Data
// (ข้อมูลดิบของบริการ 4 อย่าง)
let libraryServices: [LibraryService] = [
    LibraryService(name: "Co-working Space", description: "จองพื้นที่ทำงานกลุ่มและห้องประชุม", iconName: "person.3.fill", themeColor: .blue),
    LibraryService(name: "Netflix & Chill", description: "ห้องดูหนังพร้อมสตรีมมิ่งส่วนตัว", iconName: "play.tv.fill", themeColor: .red),
    LibraryService(name: "Board Game", description: "ยืมบอร์ดเกมและใช้โซนเล่นเกม", iconName: "gamecontroller.fill", themeColor: .purple),
    LibraryService(name: "Green-Screen Room", description: "ห้องถ่ายทำพร้อมฉากกรีนสกรีน", iconName: "camera.fill", themeColor: .green)
]

// MARK: - 3. Time Slot Model
// (โมเดลสำหรับ "รอบเวลา")
struct TimeSlot: Identifiable, Hashable {
    let id = UUID()
    let time: String
    var isBooked: Bool = false
}
