//
//  SocialPost.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 19/11/2568 BE.
//


import Foundation
import FirebaseFirestore

struct SocialPost: Identifiable, Codable {
    @DocumentID var id: String?
    
    // ข้อมูลผู้โพสต์
    var authorID: String       // UID ของผู้ใช้ (ใช้เช็คว่าเป็นเจ้าของโพสต์ไหม)
    var authorName: String     // ชื่อที่ใช้แสดงผล (ถ้า Anonymous จะเป็น "นิสิตท่านหนึ่ง")
    var realAuthorName: String // ชื่อจริงของผู้โพสต์ (เก็บไว้สำหรับ Admin ตรวจสอบ)
    
    // เนื้อหา
    var content: String
    var category: String       // เช่น "ถาม-ตอบ", "ของหาย"
    
    // Social Stats
    var likes: Int
    var likedBy: [String]      // เก็บ UID ของคนที่กดไลค์ เพื่อป้องกันการกดซ้ำ
    
    // สถานะ
    var isAnonymous: Bool      // โพสต์แบบไม่ระบุตัวตนหรือไม่
    var timestamp: Date        // เวลาที่โพสต์
    
    // Helper Function: แปลงเวลาเป็นคำพูดภาษาไทย เช่น "เมื่อสักครู่", "2 ชั่วโมงที่แล้ว"
    var displayTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "th_TH")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
