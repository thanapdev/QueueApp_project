//
//  SocialComment.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 19/11/2568 BE.
//


import Foundation
import FirebaseFirestore

struct SocialComment: Identifiable, Codable {
    @DocumentID var id: String?
    var postID: String?         // อ้างอิงถึงกระทู้แม่
    var authorID: String
    var authorName: String     // ชื่อที่แสดง (หรือ "นิสิตท่านหนึ่ง")
    var realAuthorName: String // ชื่อจริงสำหรับ Admin
    var content: String
    var timestamp: Date
    var isAnonymous: Bool      // อนุญาตให้คอมเมนต์แบบไม่เปิดเผยชื่อได้
    
    // Helper Function
    var displayTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "th_TH")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
