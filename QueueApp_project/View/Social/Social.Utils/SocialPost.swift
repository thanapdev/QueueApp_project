//
//  SocialPost.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 19/11/2568 BE.
//

import Foundation
import FirebaseFirestore

// MARK: - Social Post Model
// โมเดลข้อมูลสำหรับโพสต์ในฟีเจอร์ Social Board
// ใช้สำหรับรับ-ส่งข้อมูลกับ Firebase Firestore
struct SocialPost: Identifiable, Codable {
    @DocumentID var id: String?
    
    // MARK: - Author Info
    var authorID: String       // UID ของผู้ใช้ (ใช้เช็คว่าเป็นเจ้าของโพสต์ไหม)
    var authorName: String     // ชื่อที่ใช้แสดงผล (ถ้า Anonymous จะเป็น "นิสิตท่านหนึ่ง")
    var realAuthorName: String // ชื่อจริงของผู้โพสต์ (เก็บไว้สำหรับ Admin ตรวจสอบ)
    
    // MARK: - Content
    var content: String        // เนื้อหาโพสต์
    var category: String       // หมวดหมู่ เช่น "ถาม-ตอบ", "ของหาย", "รีวิวรายวิชา"
    
    // MARK: - Social Stats
    var likes: Int             // จำนวนไลค์
    var likedBy: [String]      // เก็บ UID ของคนที่กดไลค์ เพื่อป้องกันการกดซ้ำ
    
    // MARK: - Status & Metadata
    var isAnonymous: Bool      // โพสต์แบบไม่ระบุตัวตนหรือไม่
    var timestamp: Date        // เวลาที่โพสต์
    
    // MARK: - Helper Properties
    // แปลงเวลาเป็นคำพูดภาษาไทย เช่น "เมื่อสักครู่", "2 ชั่วโมงที่แล้ว"
    var displayTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "th_TH")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
