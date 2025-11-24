//
//  CommentViewModel.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol.
//

import SwiftUI
import Firebase

// MARK: - Comment View Model
// ViewModel สำหรับจัดการคอมเมนต์ในโพสต์ Social
// ทำหน้าที่:
// 1. ดึงคอมเมนต์ของโพสต์แบบ Real-time
// 2. เพิ่มคอมเมนต์ใหม่
// 3. ลบคอมเมนต์ (สำหรับ Admin)
class CommentViewModel: ObservableObject {
    @Published var comments: [SocialComment] = []   // รายการคอมเมนต์ทั้งหมดของโพสต์
    @Published var isLoading = false                // สถานะการโหลดข้อมูล
    @Published var postID: String                   // ID ของโพสต์ที่กำลังดูอยู่
    
    // ต้องรับ SocialViewModel มาเพื่อเรียกใช้ฟังก์ชัน add/fetch ที่เขียนไว้แล้ว (Reusability)
    private var socialVM: SocialViewModel           // Reference ไปยัง SocialViewModel หลัก
    
    init(postID: String, socialVM: SocialViewModel) {
        self.postID = postID
        self.socialVM = socialVM
        fetchComments() // ดึงคอมเมนต์ทันที
    }
    
    // ดึงคอมเมนต์
    func fetchComments() {
        guard !postID.isEmpty else { return }
        isLoading = true
        // เรียกใช้ฟังก์ชัน fetchComments จาก SocialViewModel
        socialVM.fetchComments(for: postID) { [weak self] fetchedComments in
            self?.comments = fetchedComments
            self?.isLoading = false
        }
    }
    
    // ส่งคอมเมนต์ใหม่
    func submitComment(content: String, isAnonymous: Bool) {
        socialVM.addComment(to: postID, content: content, isAnonymous: isAnonymous) { success in
            if success {
                // ไม่ต้องทำอะไรมาก เพราะ listener ใน fetchComments จะดึงข้อมูลใหม่เข้ามาเองและอัปเดต UI
                print("Comment submitted successfully!")
            }
        }
    }
}
