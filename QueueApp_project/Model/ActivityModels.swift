//
//  ActivityModels.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol.
//

import Foundation

// MARK: - User Role Enum
// ประเภทของผู้ใช้ในระบบ
// ใช้สำหรับแยกสิทธิ์การเข้าถึงฟีเจอร์ต่างๆ
enum UserRole {
    case admin   // ผู้ดูแลระบบ (มีสิทธิ์จัดการทุกอย่าง)
    case student // นิสิต (ใช้งานบริการต่าง ๆ )
}

// MARK: - Activity Model (Legacy Queue System)
// โมเดลสำหรับ "กิจกรรม" ในระบบคิวแบบเดิม
// ใช้สำหรับ:
// 1. เก็บข้อมูลกิจกรรม (เช่น งาน Open House, กิจกรรมคณะ)
// 2. จัดการเลขคิว (nextQueueNumber, currentQueueNumber)
// 3. นับจำนวนคนที่รอคิว (queueCount)
// - Note: เป็น ObservableObject เพื่อให้ SwiftUI อัปเดต UI แบบ Real-time
class Activity: Identifiable, Equatable, ObservableObject, Codable {
    let id: UUID                                    // ID เฉพาะของกิจกรรม
    @Published var name: String                     // ชื่อกิจกรรม (เช่น "Open House 2024")
    @Published var queues: [QueueItem] = []         // รายการคิวทั้งหมดในกิจกรรมนี้
    @Published var nextQueueNumber: Int             // เลขคิวถัดไปที่จะแจกให้คนต่อคิว
    @Published var currentQueueNumber: Int?         // เลขคิวที่กำลังเรียกอยู่ (Optional - อาจยังไม่มี)
    @Published var queueCount: Int                  // จำนวนคนที่รอคิวอยู่ทั้งหมด (Real-time count)
    
    init(id: UUID = UUID(), name: String, queues: [QueueItem] = [], nextQueueNumber: Int = 1, currentQueueNumber: Int? = nil, queueCount: Int = 0) {
        self.id = id
        self.name = name
        self.queues = queues
        self.nextQueueNumber = nextQueueNumber
        self.currentQueueNumber = currentQueueNumber
        self.queueCount = queueCount
    }
    
    // MARK: - Codable Support
    // เพื่อให้ Encode/Decode ได้ (บันทึกลง Firestore)
    enum CodingKeys: String, CodingKey {
        case id, name, queues, nextQueueNumber, currentQueueNumber, queueCount
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        queues = try container.decode([QueueItem].self, forKey: .queues)
        nextQueueNumber = try container.decode(Int.self, forKey: .nextQueueNumber)
        currentQueueNumber = try container.decodeIfPresent(Int.self, forKey: .currentQueueNumber)
        queueCount = try container.decode(Int.self, forKey: .queueCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(queues, forKey: .queues)
        try container.encode(nextQueueNumber, forKey: .nextQueueNumber)
        try container.encodeIfPresent(currentQueueNumber, forKey: .currentQueueNumber)
        try container.encode(queueCount, forKey: .queueCount)
    }
    
    // MARK: - Equatable Support
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Queue Item Model
// โมเดลสำหรับ "คิว" แต่ละคนในกิจกรรม
// เก็บข้อมูลคนที่ต่อคิว เช่น ชื่อ, เลขคิว, สถานะ
struct QueueItem: Identifiable, Codable, Equatable {
    let id: UUID                        // ID เฉพาะของคิว
    let studentId: String               // รหัสนิสิตเจ้าของคิว
    let studentName: String             // ชื่อนิสิตที่ต่อคิว
    let number: Int                     // เลขคิวที่ได้รับ (เช่น 1, 2, 3...)
    var status: String?                 // สถานะของคิว (เช่น "waiting", "called", "completed")
}
