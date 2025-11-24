import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - Social View Model
// ViewModel สำหรับจัดการ Logic ทั้งหมดของหน้า Social (Community Board)
// ทำหน้าที่:
// 1. ดึงโพสต์แบบ Real-time จาก Firestore
// 2. สร้างโพสต์ใหม่ (รองรับโหมด Anonymous)
// 3. จัดการไลค์ (Like/Unlike)
// 4. ลบโพสต์ (Admin และเจ้าของโพสต์)
// 5. จัดการคอมเมนต์ (เพิ่ม/ลบ)
class SocialViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var posts: [SocialPost] = []      // รายการโพสต์ทั้งหมดที่ดึงมาจาก Firestore
    @Published var isLoading: Bool = false       // สถานะการโหลดข้อมูล (แสดง Loading Indicator)
    @Published var errorMessage: String?         // ข้อความ Error (ถ้ามี) สำหรับแสดง Alert
    @Published var isAdmin: Bool = false         // สถานะ Admin ของผู้ใช้ปัจจุบัน (เพื่อแสดงปุ่มลบทุกโพสต์)
    
    // MARK: - Private Properties
    
    private var db = Firestore.firestore()                      // Firebase Firestore instance
    private var listenerRegistration: ListenerRegistration?     // Listener สำหรับฟังการเปลี่ยนแปลงของโพสต์แบบ Real-time
    
    init() {
        checkAdminStatus() // ตรวจสอบสิทธิ์ก่อน
        fetchPosts()       // เริ่มดึงข้อมูลโพสต์ทันทีที่สร้าง ViewModel
    }
    
    deinit {
        listenerRegistration?.remove() // ยกเลิกการดึงข้อมูลเมื่อหน้านี้ถูกปิด (Memory Management)
    }
    
    // MARK: - Authentication & Admin Check
    
    /// ตรวจสอบสิทธิ์ Admin ของผู้ใช้ปัจจุบัน
    /// - Note: ใช้วิธีเช็คจาก Email (Hardcoded List) หรือดึงจาก Firestore Collection 'users'
    func checkAdminStatus() {
        guard let user = Auth.auth().currentUser else { return }
        
        // --- LOGIC ตรวจสอบ Admin ---
        // วิธีที่ 1: เช็คจาก Email (Hardcoded List) - ง่ายที่สุดสำหรับการเริ่มต้น
        let adminEmails = ["admin@swu.ac.th", "staff@swu.ac.th"] // ใส่ Email ของ Admin ที่นี่
        if let email = user.email, adminEmails.contains(email) {
            self.isAdmin = true
            print("User is Admin")
        }
        
        // วิธีที่ 2: (Option) ถ้าคุณเก็บ Role ไว้ใน Firestore Collection 'users'
        /*
        db.collection("users").document(user.uid).getDocument { snapshot, _ in
            if let data = snapshot?.data(), let role = data["role"] as? String, role == "admin" {
                DispatchQueue.main.async { self.isAdmin = true }
            }
        }
        */
    }
    
    // MARK: - Fetch Posts
    
    /// ดึงข้อมูลโพสต์จาก Firestore แบบ Real-time
    /// ใช้ Snapshot Listener เพื่อให้ UI อัปเดตทันทีเมื่อมีการเปลี่ยนแปลง
    func fetchPosts() {
        isLoading = true
        
        // ล้าง Listener เดิมก่อนเพื่อป้องกันการเรียกซ้ำ
        listenerRegistration?.remove()
        
        listenerRegistration = db.collection("social_posts")
            .order(by: "timestamp", descending: true) // เรียงจากใหม่ -> เก่า
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = "ไม่สามารถโหลดข้อมูลได้: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.posts = []
                    self.isLoading = false
                    return
                }
                
                // แปลงข้อมูลจาก Firestore Document -> SocialPost Object
                self.posts = documents.compactMap { queryDocumentSnapshot -> SocialPost? in
                    return try? queryDocumentSnapshot.data(as: SocialPost.self)
                }
                
                self.isLoading = false
            }
    }
    
    // MARK: - Create Post
    
    /// สร้างโพสต์ใหม่
    /// - Parameters:
    ///   - content: เนื้อหาโพสต์
    ///   - category: หมวดหมู่ (เช่น "ทั่วไป", "ถาม-ตอบ")
    ///   - isAnonymous: โพสต์แบบไม่ระบุชื่อหรือไม่
    ///   - completion: Callback เมื่อเสร็จสิ้น (success: Bool)
    func createPost(content: String, category: String, isAnonymous: Bool, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "กรุณาเข้าสู่ระบบ"
            completion(false)
            return
        }
        
        let userID = user.uid
        
        // 1. ดึงชื่อจริงจาก Collection "users" ก่อน (เพื่อให้ได้ชื่อที่ถูกต้อง)
        db.collection("users").document(userID).getDocument { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            // กำหนดชื่อ Default เผื่อหาไม่เจอ
            var realName = "Unknown User"
            
            if let data = snapshot?.data() {
                // เช็ค Key ให้ตรงกับ Database (เช่น "name", "fullName")
                if let nameFromDB = data["name"] as? String {
                    realName = nameFromDB
                } else if let nameFromDB = data["fullName"] as? String {
                    realName = nameFromDB
                }
            }
            
            // 2. เตรียมข้อมูลโพสต์
            // ถ้าเลือก Anonymous ให้ใช้ชื่อ "นิสิตท่านหนึ่ง" แต่ยังเก็บ realAuthorName ไว้เผื่อ Admin ตรวจสอบ
            let displayName = isAnonymous ? "นิสิตท่านหนึ่ง" : realName
            
            let newPost = SocialPost(
                authorID: userID,
                authorName: displayName,
                realAuthorName: realName,
                content: content,
                category: category,
                likes: 0,
                likedBy: [],
                isAnonymous: isAnonymous,
                timestamp: Date()
            )
            
            // 3. บันทึกลง Firebase
            do {
                try self.db.collection("social_posts").addDocument(from: newPost)
                print("Post created successfully by: \(realName)")
                completion(true)
            } catch {
                self.errorMessage = "โพสต์ล้มเหลว: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
    
    // MARK: - Toggle Like
    
    /// กดไลค์หรือยกเลิกไลค์โพสต์
    /// - Parameter post: โพสต์ที่ต้องการไลค์/ยกเลิกไลค์
    func toggleLike(post: SocialPost) {
        guard let postID = post.id, let userID = Auth.auth().currentUser?.uid else { return }
        
        let postRef = db.collection("social_posts").document(postID)
        
        if post.likedBy.contains(userID) {
            // Case: เคยไลค์แล้ว -> เอาออก (Unlike)
            postRef.updateData([
                "likes": FieldValue.increment(Int64(-1)),
                "likedBy": FieldValue.arrayRemove([userID])
            ])
        } else {
            // Case: ยังไม่เคยไลค์ -> เพิ่ม (Like)
            postRef.updateData([
                "likes": FieldValue.increment(Int64(1)),
                "likedBy": FieldValue.arrayUnion([userID])
            ])
        }
    }
    
    // MARK: - Delete Post
    
    /// ลบโพสต์
    /// - Parameter post: โพสต์ที่ต้องการลบ
    /// - Note: ใช้ได้ทั้ง Admin และเจ้าของโพสต์
    func deletePost(post: SocialPost) {
        guard let postID = post.id else { return }
        
        db.collection("social_posts").document(postID).delete { [weak self] error in
            if let error = error {
                self?.errorMessage = "ลบโพสต์ไม่สำเร็จ: \(error.localizedDescription)"
            } else {
                // Firestore Listener จะอัปเดตหน้าจอให้อัตโนมัติ 
                // แต่เราลบออกจาก array local เพื่อความลื่นไหลทันทีก็ได้ (Optimistic Update)
                if let index = self?.posts.firstIndex(where: { $0.id == postID }) {
                    self?.posts.remove(at: index)
                }
            }
        }
    }
    
    // MARK: - Comments Management
    
    /// ดึงคอมเมนต์ของโพสต์แบบ Real-time
    /// - Parameters:
    ///   - postID: ID ของโพสต์
    ///   - completion: Callback ที่ส่งรายการคอมเมนต์กลับมา
    func fetchComments(for postID: String, completion: @escaping ([SocialComment]) -> Void) {
        db.collection("social_posts").document(postID).collection("comments")
            .order(by: "timestamp", descending: false) // เรียงจากเก่าไปใหม่ (คอมเมนต์แรกอยู่บน)
            .addSnapshotListener { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching comments: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let comments = documents.compactMap { queryDocumentSnapshot -> SocialComment? in
                    return try? queryDocumentSnapshot.data(as: SocialComment.self)
                }
                completion(comments)
            }
    }

    /// เพิ่มคอมเมนต์ใหม่
    /// - Parameters:
    ///   - postID: ID ของโพสต์ที่ต้องการคอมเมนต์
    ///   - content: เนื้อหาคอมเมนต์
    ///   - isAnonymous: คอมเมนต์แบบไม่ระบุชื่อหรือไม่
    ///   - completion: Callback เมื่อเสร็จสิ้น (success: Bool)
    func addComment(to postID: String, content: String, isAnonymous: Bool, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else { return }
        let userID = user.uid
        
        // ต้องดึงชื่อจริงจาก Collection 'users' ก่อน (ใช้ Logic เดียวกับ createPost)
        db.collection("users").document(userID).getDocument { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            var realName = "Unknown User"
            if let data = snapshot?.data(), let nameFromDB = data["name"] as? String {
                realName = nameFromDB
            }
            
            let displayName = isAnonymous ? "นิสิตท่านหนึ่ง" : realName
            
            let newComment = SocialComment(
                postID: postID,
                authorID: userID,
                authorName: displayName,
                realAuthorName: realName,
                content: content,
                timestamp: Date(),
                isAnonymous: isAnonymous
            )
            
            do {
                try self.db.collection("social_posts").document(postID)
                    .collection("comments").addDocument(from: newComment)
                completion(true)
            } catch {
                self.errorMessage = "ไม่สามารถคอมเมนต์ได้: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
    
    /// ลบคอมเมนต์
    /// - Parameters:
    ///   - postID: ID ของโพสต์
    ///   - commentID: ID ของคอมเมนต์ที่ต้องการลบ
    /// - Note: Admin สามารถลบคอมเมนต์ทุกอันได้
    func deleteComment(postID: String, commentID: String) {
        db.collection("social_posts").document(postID)
            .collection("comments").document(commentID).delete { error in
                if let error = error {
                    print("Error deleting comment: \(error.localizedDescription)")
                } else {
                    print("Comment deleted successfully!")
                }
            }
    }

}

