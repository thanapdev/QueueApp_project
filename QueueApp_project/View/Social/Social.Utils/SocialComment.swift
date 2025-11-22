//
//  SocialComment.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 19/11/2568 BE.
//

import Foundation
import FirebaseFirestore

// MARK: - Social Comment Model
// โมเดลข้อมูลสำหรับความคิดเห็นในฟีเจอร์ Social
// ใช้สำหรับรับ-ส่งข้อมูลกับ Firebase Firestore
struct SocialComment: Identifiable, Codable {
    @DocumentID var id: String?
    var postID: String?         // อ้างอิงถึงกระทู้แม่ (Parent Post ID)
    var authorID: String        // UID ของผู้คอมเมนต์
    var authorName: String      // ชื่อที่แสดง (Display Name) หรือ "นิสิตท่านหนึ่ง"
    var realAuthorName: String  // ชื่อจริงสำหรับ Admin ตรวจสอบ
    var content: String         // เนื้อหาความคิดเห็น
    var timestamp: Date         // เวลาที่คอมเมนต์
    var isAnonymous: Bool       // สถานะการไม่ระบุตัวตน
    
    // MARK: - Helper Properties
    // แปลงเวลาเป็นรูปแบบ Relative Time ภาษาไทย (เช่น "2 นาทีที่แล้ว")
    var displayTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "th_TH")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
