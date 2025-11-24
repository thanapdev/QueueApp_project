import SwiftUI

// MARK: - Library Service Model
// โมเดลสำหรับบริการต่างๆ ในห้องสมุด (Library Services)
// ใช้สำหรับแสดงรายการบริการที่นิสิตสามารถจองได้
// เช่น: Co-Working Space, Netflix Room, Green Screen, Board Game
struct LibraryService: Identifiable {
    let id = UUID()
    let name: String        // ชื่อบริการ
    let description: String // คำอธิบาย
    let iconName: String    // ชื่อไอคอน SF Symbol
    let themeColor: Color   // สีประจำบริการ
}

// MARK: - Mock Service Data
// ข้อมูลจำลองของบริการทั้ง 4 อย่าง (ใช้สำหรับแสดงผลในหน้า ServiceView)
let libraryServices: [LibraryService] = [
    LibraryService(name: "Co-working Space", description: "จองพื้นที่ทำงานกลุ่มและห้องประชุม", iconName: "person.3.fill", themeColor: .blue),
    LibraryService(name: "Netflix & Chill", description: "ห้องดูหนังพร้อมสตรีมมิ่งส่วนตัว", iconName: "play.tv.fill", themeColor: .red),
    LibraryService(name: "Board Game", description: "ยืมบอร์ดเกมและใช้โซนเล่นเกม", iconName: "gamecontroller.fill", themeColor: .purple),
    LibraryService(name: "Green-Screen Room", description: "ห้องถ่ายทำพร้อมฉากกรีนสกรีน", iconName: "camera.fill", themeColor: .green)
]

// MARK: - Time Slot Model
// โมเดลสำหรับช่วงเวลาที่สามารถจองได้
struct TimeSlot: Identifiable, Hashable {
    let id = UUID()
    let time: String      // เวลา (เช่น "10:00 - 12:00")
    var isBooked: Bool = false // สถานะว่าถูกจองเต็มหรือยัง
}

// MARK: - Predefined Time Slots
// ช่วงเวลามาตรฐานที่ใช้ในระบบ (แบ่งเป็นช่วงละ 2 ชั่วโมง)
let timeSlots: [TimeSlot] = [
    TimeSlot(time: "10:00 - 12:00"),
    TimeSlot(time: "12:00 - 14:00"),
    TimeSlot(time: "14:00 - 16:00"),
    TimeSlot(time: "16:00 - 18:00")
]
