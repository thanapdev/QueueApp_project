//
//  CommentViewModel.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 19/11/2568 BE.
//

import SwiftUI
import FirebaseAuth

// MARK: - Comment View Model
// ตัวจัดการ Logic สำหรับหน้า Comment (PostDetailView)
// แยกออกมาจาก SocialViewModel เพื่อให้จัดการได้ง่ายขึ้นเมื่อเข้าสู่หน้า Detail
class CommentViewModel: ObservableObject {
    @Published var comments: [SocialComment] = [] // รายการคอมเมนต์
    @Published var isLoading = false
    @Published var postID: String // ID ของโพสต์ที่กำลังดูอยู่
    
    // ต้องรับ SocialViewModel มาเพื่อเรียกใช้ฟังก์ชัน add/fetch ที่เขียนไว้แล้ว (Reusability)
    private var socialVM: SocialViewModel
    
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
