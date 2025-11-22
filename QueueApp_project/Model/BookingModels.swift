import SwiftUI

// MARK: - 1. Library Service Model
// โมเดลสำหรับ "บริการ" หลัก 4 อย่างของห้องสมุด
struct LibraryService: Identifiable {
    let id = UUID()
    let name: String        // ชื่อบริการ
    let description: String // คำอธิบาย
    let iconName: String    // ชื่อไอคอน SF Symbol
    let themeColor: Color   // สีประจำบริการ
}

// MARK: - 2. Mock Service Data
// ข้อมูลจำลองของบริการทั้ง 4 อย่าง (ใช้สำหรับแสดงผลในหน้า ServiceView)
let libraryServices: [LibraryService] = [
    LibraryService(name: "Co-working Space", description: "จองพื้นที่ทำงานกลุ่มและห้องประชุม", iconName: "person.3.fill", themeColor: .blue),
    LibraryService(name: "Netflix & Chill", description: "ห้องดูหนังพร้อมสตรีมมิ่งส่วนตัว", iconName: "play.tv.fill", themeColor: .red),
    LibraryService(name: "Board Game", description: "ยืมบอร์ดเกมและใช้โซนเล่นเกม", iconName: "gamecontroller.fill", themeColor: .purple),
    LibraryService(name: "Green-Screen Room", description: "ห้องถ่ายทำพร้อมฉากกรีนสกรีน", iconName: "camera.fill", themeColor: .green)
]

// MARK: - 3. Time Slot Model
// โมเดลสำหรับ "รอบเวลา" ในการจอง
struct TimeSlot: Identifiable, Hashable {
    let id = UUID()
    let time: String      // เวลา (เช่น "10:00 - 12:00")
    var isBooked: Bool = false // สถานะว่าถูกจองเต็มหรือยัง
}
