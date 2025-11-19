//
//  SocialBoardView.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 19/11/2568 BE.
//

import SwiftUI
import FirebaseAuth

// ******************************************************
// MARK: - 1. MAIN FEED VIEW (SocialBoardView)
// ******************************************************

struct SocialBoardView: View {
    @StateObject var viewModel = SocialViewModel()
    @State private var showCreatePost = false
    // ดึง UID ณ เวลาที่ View ถูกสร้าง (ใช้เช็คสิทธิ์)
    let currentUserID = Auth.auth().currentUser?.uid
    
    var body: some View {
        // ใช้ NavigationStack ครอบทั้งหมด
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                
                // --- Background ---
                DynamicBackground(style: .random)
                
                // --- ส่วนแสดงรายการโพสต์ (ใช้ ScrollView เพื่อ Card Styling) ---
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView("กำลังโหลดสังคมชาว มศว...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.posts.isEmpty {
                    VStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("ยังไม่มีโพสต์ เริ่มต้นคุยกันเลย!")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) { // เพิ่ม spacing
                            ForEach(viewModel.posts) { post in
                                // ส่ง post เป็นค่าคงที่ (let) เพื่อให้รับค่าใหม่จาก ViewModel เสมอ
                                PostRowView(post: post, viewModel: viewModel, currentUserID: currentUserID)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 20) // ปรับ padding
                        .padding(.bottom, 80) // เผื่อพื้นที่ให้ Floating Button
                    }
                    .refreshable {
                        viewModel.fetchPosts()
                    }
                }
                
                // --- ปุ่ม Floating Action Button (+) ---
                Button(action: {
                    showCreatePost = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.Theme.primary) // ใช้สี Theme หลัก
                        .clipShape(Circle())
                        .shadow(color: Color.Theme.primary.opacity(0.4), radius: 8, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("SWU Social")
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(viewModel: viewModel)
            }
        }
    }
}

// ******************************************************
// MARK: - 2. POST ROW CARD COMPONENT (Card Style)
// ******************************************************

struct PostRowView: View {
    let post: SocialPost
    @ObservedObject var viewModel: SocialViewModel
    let currentUserID: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PostHeaderView(post: post, viewModel: viewModel, currentUserID: currentUserID)
            
            // --- Content ---
            Text(post.content)
                .font(.body)
                .foregroundColor(Color.Theme.textDark)
            
            PostFooterView(post: post, viewModel: viewModel, currentUserID: currentUserID)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Helper View: Post Header
private struct PostHeaderView: View {
    let post: SocialPost
    @ObservedObject var viewModel: SocialViewModel
    let currentUserID: String?
    
    var body: some View {
        HStack(alignment: .top) {
            // Icon
            Image(systemName: post.isAnonymous ? "person.circle.fill" : "person.circle")
                .resizable()
                .frame(width: 38, height: 38)
                .foregroundColor(post.isAnonymous ? .purple : Color.Theme.primary)
                .padding(.trailing, 4)
            
            // Name & Time
            VStack(alignment: .leading) {
                Text(post.authorName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.Theme.textDark)
                
                HStack {
                    Text(post.displayTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Badge หมวดหมู่
                    Text(post.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(5)
                }
            }
            
            Spacer()
            
            // ปุ่มลบ (เห็นเฉพาะของตัวเอง)
            if post.authorID == currentUserID {
                Button(action: { viewModel.deletePost(post: post) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Helper View: Post Footer
private struct PostFooterView: View {
    let post: SocialPost
    @ObservedObject var viewModel: SocialViewModel
    let currentUserID: String?
    
    var body: some View {
        HStack(spacing: 20) {
            // ปุ่ม Like
            Button(action: { viewModel.toggleLike(post: post) }) {
                HStack(spacing: 5) {
                    Image(systemName: post.likedBy.contains(currentUserID ?? "") ? "heart.fill" : "heart")
                        .foregroundColor(post.likedBy.contains(currentUserID ?? "") ? .red : .secondary)
                    Text("\(post.likes)")
                }
                .contentShape(Rectangle())
                .padding(.vertical, 5)
            }
            .buttonStyle(PlainButtonStyle())
            
            // ปุ่ม Comment (NavigationLink)
            NavigationLink(destination: PostDetailView(post: post, socialVM: viewModel)) {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.right")
                    Text("คอมเมนต์")
                }
                .contentShape(Rectangle())
                .padding(.vertical, 5)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(.top, 5)
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
}

// MARK: - 3. Post Detail View (หน้าหลักแสดงคอมเมนต์)
struct PostDetailView: View {
    // โพสต์แม่ (Passed from SocialBoardView)
    let post: SocialPost
    // ViewModel หลัก (Passed from SocialBoardView เพื่อให้เข้าถึง Logic ของ Firebase ได้)
    @ObservedObject var socialVM: SocialViewModel
    
    // ViewModel สำหรับ Comment เฉพาะโพสต์นี้ (Source of Truth สำหรับคอมเมนต์)
    @StateObject private var commentVM: CommentViewModel
    
    // State สำหรับ Input Area
    @State private var newCommentContent: String = ""
    @State private var isAnonymousComment: Bool = false
    
    init(post: SocialPost, socialVM: SocialViewModel) {
        self.post = post
        self.socialVM = socialVM
        // สร้าง StateObject ทันทีที่ init โดยใช้ post.id
        _commentVM = StateObject(wrappedValue: CommentViewModel(postID: post.id ?? "", socialVM: socialVM))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // ✅ FIX: Base Layer (Dynamic Background) - ลบ Color.white ออก
            DynamicBackground(style: .random).edgesIgnoringSafeArea(.all)
            
            // --- A. Scrollable Content (Post Header + Comment Feed) ---
            ScrollView(showsIndicators: false) { // ซ่อน Scroll Indicator เพื่อความสะอาด
                VStack(alignment: .leading, spacing: 15) {
                    
                    // 1. Post Header (แสดงรายละเอียดโพสต์แม่)
                    PostHeaderDetailView(post: post)
                        .padding(.horizontal, 20)
                        .padding(.top, 10) // ปรับ padding
                        .padding(.bottom, 5)
                    
                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 5) // เพิ่ม padding แนวตั้งให้ Divider
                    
                    // 2. Comment Feed Title
                    Text("ความคิดเห็น (\(commentVM.comments.count))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 5)
                        .foregroundColor(Color.Theme.textDark)
                    
                    // 3. Comment Feed List
                    VStack(alignment: .leading) {
                        if commentVM.isLoading {
                            ProgressView()
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else if commentVM.comments.isEmpty {
                            Text("เป็นคนแรกที่แสดงความคิดเห็น!")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20) // ปรับ padding
                        } else {
                            // แสดงรายการคอมเมนต์
                            ForEach(commentVM.comments) { comment in
                                CommentRowView(comment: comment)
                            }
                        }
                    }
                    .padding(.horizontal, 20) // ย้าย padding มาที่ VStack
                }
                .padding(.bottom, 100) // เผื่อพื้นที่ให้ Input Area
            }
            
            // --- B. Comment Input Area (อยู่ด้านล่างสุด) ---
            CommentInputBar(
                newCommentContent: $newCommentContent,
                isAnonymousComment: $isAnonymousComment,
                onSubmit: {
                    if !newCommentContent.isEmpty {
                        commentVM.submitComment(content: newCommentContent, isAnonymous: isAnonymousComment)
                        newCommentContent = "" // เคลียร์ช่อง input
                    }
                }
            )
            .keyboardShortcut(.return, modifiers: [])
        }
        .navigationTitle("กระทู้: \(post.category)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
// MARK: - Helper Views สำหรับ PostDetailView

private struct PostHeaderDetailView: View {
    let post: SocialPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // 1. Author Info
            HStack {
                Image(systemName: post.isAnonymous ? "person.circle.fill" : "person.circle")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .foregroundColor(post.isAnonymous ? .purple : Color.Theme.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.Theme.textDark)
                    
                    HStack {
                        Text(post.displayTime)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        // Badge หมวดหมู่
                        Text(post.category)
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.Theme.primary.opacity(0.1))
                            .foregroundColor(Color.Theme.primary)
                            .cornerRadius(5)
                    }
                }
                Spacer()
            }
            
            Divider()
            
            // 2. เนื้อหาหลัก
            Text(post.content)
                .font(.title3)
                .foregroundColor(Color.Theme.textDark)
                .padding(.vertical, 5)
            
            // 3. Stats (Likes)
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(post.likes) ถูกใจ")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        // ✅ Style: พื้นหลังขาวและเงาเพื่อให้ลอยเด่นบน DynamicBackground
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}


private struct CommentRowView: View {
    let comment: SocialComment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                // ชื่อผู้คอมเมนต์
                Text(comment.authorName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(comment.isAnonymous ? .purple : Color.Theme.primary)
                
                Spacer()
                
                // เวลา
                Text(comment.displayTime)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // เนื้อหาคอมเมนต์
            Text(comment.content)
                .font(.callout)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        // ✅ Style: การ์ดคอมเมนต์ที่เล็กและสะอาดกว่า
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .padding(.vertical, 4)
    }
}

private struct CommentInputBar: View {
    @Binding var newCommentContent: String
    @Binding var isAnonymousComment: Bool
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                // Input Field (Modern Pill Shape)
                TextField("เพิ่มความคิดเห็น...", text: $newCommentContent, axis: .vertical)
                    .lineLimit(1...3)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                
                // Toggle Anonymous
                Toggle(isOn: $isAnonymousComment) {
                    Image(systemName: isAnonymousComment ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(isAnonymousComment ? .purple : .gray)
                        .font(.title2)
                }
                .fixedSize()
                .toggleStyle(SwitchToggleStyle(tint: .purple))
                
                // Send Button
                Button(action: onSubmit) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(newCommentContent.isEmpty ? Color.gray : Color.Theme.primary)
                        .clipShape(Circle())
                }
                .disabled(newCommentContent.isEmpty)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: -2)
    }
}
