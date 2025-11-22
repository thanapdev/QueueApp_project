//
//  Models.swift
//  term_projecct
//
//  Created by Thanapong Yamkamol on 7/11/2568 BE.
//

import Foundation

// MARK: - User Role
// ประเภทของผู้ใช้ในระบบ
enum UserRole {
    case admin   // ผู้ดูแลระบบ
    case student // นิสิต
}

// MARK: - Activity Model (Legacy Queue System)
// โมเดลสำหรับ "กิจกรรม" ในระบบคิวแบบเดิม (เช่น งาน Open House หรือกิจกรรมคณะ)
class Activity: Identifiable, Equatable, ObservableObject, Codable {
    let id: UUID
    @Published var name: String // ชื่อกิจกรรม
    @Published var queues: [QueueItem] = [] // รายการคิวในกิจกรรมนี้
    @Published var nextQueueNumber: Int // เลขคิวถัดไปที่จะแจก
    @Published var currentQueueNumber: Int? // เลขคิวที่กำลังเรียกอยู่ (Optional)
    @Published var queueCount: Int // จำนวนคิวทั้งหมดที่รออยู่
    
    init(id: UUID = UUID(), name: String, queues: [QueueItem] = [], nextQueueNumber: Int = 1, currentQueueNumber: Int? = nil, queueCount: Int = 0) {
        self.id = id
        self.name = name
        self.queues = queues
        self.nextQueueNumber = nextQueueNumber
        self.currentQueueNumber = currentQueueNumber
        self.queueCount = queueCount
    }

    static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.id == rhs.id
    }

    // MARK: - Codable Conformance
    // กำหนด CodingKeys เพื่อให้ Encode/Decode กับ Firestore ได้ถูกต้อง
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
        try container.encode(currentQueueNumber, forKey: .currentQueueNumber)
        try container.encode(queueCount, forKey: .queueCount)
    }
}


// MARK: - Queue Item Model
// โมเดลสำหรับ "บัตรคิว" แต่ละใบ
struct QueueItem: Identifiable, Equatable, Codable {
    let id: UUID
    let studentId: String // รหัสนิสิตเจ้าของคิว
    let studentName: String // ชื่อนิสิต
    let number: Int // หมายเลขคิว
    var status: String? // สถานะคิว (เช่น "waiting", "called", "completed")
}
