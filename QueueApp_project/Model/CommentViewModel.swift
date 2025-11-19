//
//  CommentViewModel.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 19/11/2568 BE.
//

import SwiftUI
import FirebaseAuth

// MARK: - Comment Manager (เพื่อใช้ใน PostDetailView)
class CommentViewModel: ObservableObject {
    @Published var comments: [SocialComment] = []
    @Published var isLoading = false
    @Published var postID: String
    
    // ต้องรับ SocialViewModel มาเพื่อเรียกใช้ฟังก์ชัน add/fetch
    private var socialVM: SocialViewModel
    
    init(postID: String, socialVM: SocialViewModel) {
        self.postID = postID
        self.socialVM = socialVM
        fetchComments()
    }
    
    func fetchComments() {
        guard !postID.isEmpty else { return }
        isLoading = true
        // เรียกใช้ฟังก์ชัน fetchComments จาก SocialViewModel
        socialVM.fetchComments(for: postID) { [weak self] fetchedComments in
            self?.comments = fetchedComments
            self?.isLoading = false // Corrected line
        }
    }
    
    func submitComment(content: String, isAnonymous: Bool) {
        socialVM.addComment(to: postID, content: content, isAnonymous: isAnonymous) { success in
            if success {
                // ไม่ต้องทำอะไรมาก เพราะ listener ใน fetchComments จะดึงข้อมูลใหม่เข้ามาเอง
                print("Comment submitted successfully!")
            }
        }
    }
}
