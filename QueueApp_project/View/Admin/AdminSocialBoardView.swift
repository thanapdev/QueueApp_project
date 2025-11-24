//
//  AdminSocialBoardView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 19/11/2568 BE.
//

import SwiftUI
import FirebaseAuth

// ******************************************************
// MARK: - 1. ADMIN MAIN FEED VIEW (AdminSocialBoardView)
// ******************************************************
// หน้าหลักสำหรับ Admin ในการจัดการ Social Board
// MARK: - Admin Social Board View
// หน้าจัดการ Social Board สำหรับ Admin
// ทำหน้าที่:
// 1. แสดงรายการโพสต์ทั้งหมด
// 2. ลบโพสต์และคอมเมนต์ที่ไม่เหมาะสม
struct AdminSocialBoardView: View {
    @StateObject var viewModel = SocialViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            ZStack {
                // --- Background Layer (FIXED: Base layer) ---
                DynamicBackground(style: .random).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // 1. CUSTOM HEADER
                    CustomHeader()
                        .padding(.top, 50)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    
                    // 2. POST LIST (Content Sheet - White Bottom)
                    ZStack {
                        // White Sheet (แค่ด้านล่าง)
                        Color.Theme.white
                            .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                            .edgesIgnoringSafeArea(.bottom) // ให้พื้นหลังขาวลากยาวถึงขอบล่าง
                        
                        if viewModel.posts.isEmpty {
                            // Empty State
                            VStack(spacing: 15) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray.opacity(0.4))
                                Text("No posts to moderate.").foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // List View (รายการโพสต์)
                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.posts) { post in
                                        NavigationLink(destination: AdminPostDetailView(post: post, socialVM: viewModel)) {
                                            AdminRowContent(post: post, viewModel: viewModel)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 50)
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.fetchPosts() // โหลดข้อมูลโพสต์เมื่อหน้าจอแสดง
            }
        }
    }
    
    // Custom Header Component
    // ส่วนหัวของหน้า Admin Social Board
    private struct CustomHeader: View {
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.headline).foregroundColor(.white)
                    .padding(.vertical, 8).padding(.horizontal, 12)
                    .background(Color.red.opacity(0.8)).clipShape(Capsule())
                }
                
                Spacer()
                
                Text("MODERATION BOARD")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                
                Spacer()
                
                Button(action: { /* Logic: Refresh */ }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
    }
}

// ******************************************************
// MARK: - 2. ADMIN POST DETAIL VIEW (Moderation Screen)
// ******************************************************
// หน้าแสดงรายละเอียดโพสต์สำหรับ Admin
// แสดงเนื้อหาโพสต์ ชื่อจริงผู้โพสต์ และรายการคอมเมนต์ (พร้อมปุ่มลบ)
struct AdminPostDetailView: View {
    let post: SocialPost
    @ObservedObject var socialVM: SocialViewModel
    
    @StateObject private var commentVM: CommentViewModel
    
    init(post: SocialPost, socialVM: SocialViewModel) {
        self.post = post
        self.socialVM = socialVM
        _commentVM = StateObject(wrappedValue: CommentViewModel(postID: post.id ?? "", socialVM: socialVM))
    }
    
    var body: some View {
        ZStack {
            // ✅ FIX: Base Layer (Theme Background)
            DynamicBackground(style: .random).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    
                    // 1. Post Header (Admin View - Card Styling Applied)
                    AdminDetailHeaderView(post: post, socialVM: socialVM)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    
                    // 2. Comment Feed Title
                    HStack {
                        Text("คอมเมนต์ที่ต้องตรวจสอบ (\(commentVM.comments.count))")
                            .font(.title3).fontWeight(.bold)
                            .foregroundColor(Color.Theme.textDark)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // 3. Comment Feed List
                    VStack(alignment: .leading) {
                        if commentVM.isLoading {
                            ProgressView().padding()
                        } else {
                            ForEach(commentVM.comments) { comment in
                                AdminCommentRowView(
                                    comment: comment,
                                    socialVM: socialVM
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 50)
            }
        }
        .navigationTitle("MOD: \(post.category)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 3. HELPER VIEWS

// 3.1 Content สำหรับ List Row ในหน้าหลัก
// แสดงตัวอย่างโพสต์ในหน้า Admin Feed
private struct AdminRowContent: View {
    let post: SocialPost
    @ObservedObject var viewModel: SocialViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // --- Top Row (Admin Info & Delete Button) ---
            HStack(alignment: .top) {
                // Admin Info
                VStack(alignment: .leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.text.rectangle.fill")
                            .foregroundColor(.gray)
                        Text("Real Author:").font(.caption).foregroundColor(.gray)
                    }
                    Text(post.realAuthorName) // 🎯 Real Name (ชัดเจน)
                        .font(.subheadline).fontWeight(.bold).foregroundColor(.red)
                }
                
                Spacer()
                
                // ปุ่มลบโพสต์หลัก
                Button(action: { viewModel.deletePost(post: post) }) {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                        .padding(8).background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
            
            // --- Content Preview ---
            Text(post.content)
                .font(.body).lineLimit(2).foregroundColor(Color.Theme.textDark)
            
            // Info
            HStack {
                Text("Category: \(post.category)")
                    .font(.caption).padding(6).background(Color.Theme.primary.opacity(0.1)).cornerRadius(6)
                Spacer()
                Text("Likes: \(post.likes)").font(.caption).foregroundColor(.gray)
                Text(post.displayTime).font(.caption).foregroundColor(.gray)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Theme.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// 3.2 Header View สำหรับหน้า Detail
// แสดงรายละเอียดโพสต์เต็มรูปแบบในหน้า Admin Detail
private struct AdminDetailHeaderView: View {
    let post: SocialPost
    @ObservedObject var socialVM: SocialViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Post Detail")
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(Color.Theme.textDark)
                Spacer()
                
                // ปุ่มลบโพสต์หลักในหน้า Detail
                Button(action: { socialVM.deletePost(post: post); }) {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
            
            // Real Name Box
            VStack(alignment: .leading, spacing: 5) {
                Text("Real Author:")
                    .font(.caption).foregroundColor(.gray)
                Text(post.realAuthorName)
                    .font(.subheadline).fontWeight(.bold).foregroundColor(.red)
            }
            .padding(10)
            .background(Color.red.opacity(0.05))
            .cornerRadius(8)
            
            // Post Content
            Text(post.content)
                .font(.body).foregroundColor(Color.Theme.textDark)
            
            // Footer Info
            HStack {
                Text("Category: \(post.category)")
                    .font(.caption).padding(6).background(Color.gray.opacity(0.1)).cornerRadius(6)
                Spacer()
                Text("Likes: \(post.likes)").font(.caption).foregroundColor(.gray)
                Text(post.displayTime).font(.caption).foregroundColor(.gray)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        // ✅ พื้นหลังขาวและเงาเพื่อให้ลอยเด่นบนพื้นหลังธีม
        .background(Color.Theme.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.08), radius: 8)
    }
}

// 3.3 Comment Row พร้อมปุ่มลบสำหรับ Admin
// แสดงคอมเมนต์แต่ละรายการ พร้อมปุ่มลบสำหรับ Admin
private struct AdminCommentRowView: View {
    let comment: SocialComment
    @ObservedObject var socialVM: SocialViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // ชื่อผู้คอมเมนต์ + Real Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.authorName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(comment.isAnonymous ? .purple : Color.Theme.primary)
                    
                    if comment.isAnonymous {
                        Text("(\(comment.realAuthorName))") // 🎯 Real Name
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                // เวลา + ปุ่มลบ Comment
                HStack(spacing: 15) {
                    Text(comment.displayTime).font(.caption).foregroundColor(.gray)
                    
                    Button(action: {
                        guard let commentID = comment.id, let postID = comment.postID else { return }
                        socialVM.deleteComment(postID: postID, commentID: commentID)
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // เนื้อหาคอมเมนต์
            Text(comment.content).font(.callout)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.Theme.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .padding(.vertical, 4)
    }
}
