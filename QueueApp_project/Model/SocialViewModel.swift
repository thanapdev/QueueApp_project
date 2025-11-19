import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class SocialViewModel: ObservableObject {
    @Published var posts: [SocialPost] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAdmin: Bool = false // สถานะ Admin ของผู้ใช้ปัจจุบัน
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        checkAdminStatus() // ตรวจสอบสิทธิ์ก่อน
        fetchPosts()       // ดึงข้อมูลโพสต์
    }
    
    deinit {
        listenerRegistration?.remove() // ยกเลิกการดึงข้อมูลเมื่อหน้านี้ถูกปิด
    }
    
    // MARK: - 1. Authentication & Admin Check
    func checkAdminStatus() {
        guard let user = Auth.auth().currentUser else { return }
        
        // --- LOGIC ตรวจสอบ Admin ---
        // วิธีที่ 1: เช็คจาก Email (ง่ายที่สุดสำหรับการเริ่มต้น)
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
    
    // MARK: - 2. Fetch Posts (Real-time)
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
                
                // แปลงข้อมูลจาก Firestore เป็น SocialPost array
                self.posts = documents.compactMap { queryDocumentSnapshot -> SocialPost? in
                    return try? queryDocumentSnapshot.data(as: SocialPost.self)
                }
                
                self.isLoading = false
            }
    }
    
    // MARK: - 3. Create Post
    func createPost(content: String, category: String, isAnonymous: Bool, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            self.errorMessage = "กรุณาเข้าสู่ระบบ"
            completion(false)
            return
        }
        
        let userID = user.uid
        
        // 1. ดึงชื่อจริงจาก Collection "users" (หรือชื่อ Collection ที่คุณเก็บข้อมูลนิสิต)
        db.collection("users").document(userID).getDocument { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            // กำหนดชื่อ Default เผื่อหาไม่เจอ
            var realName = "Unknown User"
            
            if let data = snapshot?.data() {
                // *** เช็คตรงนี้: ใน Database คุณเก็บชื่อด้วย key อะไร? ***
                // เช่น "name", "fullName", "username", "studentName"
                // แก้ให้ตรงกับใน Database ของคุณนะครับ
                if let nameFromDB = data["name"] as? String {
                    realName = nameFromDB
                } else if let nameFromDB = data["fullName"] as? String {
                    realName = nameFromDB
                }
            }
            
            // 2. เตรียมข้อมูลโพสต์
            let displayName = isAnonymous ? "นิสิตท่านหนึ่ง" : realName
            
            let newPost = SocialPost(
                authorID: userID,
                authorName: displayName,
                realAuthorName: realName, // <--- ตรงนี้จะได้ชื่อที่ถูกต้องแล้ว
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
                print("Post created successfully by: \(realName)") // เช็ค Log ดู
                completion(true)
            } catch {
                self.errorMessage = "โพสต์ล้มเหลว: \(error.localizedDescription)"
                completion(false)
            }
        }
    }
    
    // MARK: - 4. Toggle Like
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
    
    // MARK: - 5. Delete Post
    // ใช้ได้ทั้ง Admin (ลบได้ทุกโพสต์) และ User (ลบโพสต์ตัวเอง)
    func deletePost(post: SocialPost) {
        guard let postID = post.id else { return }
        
        db.collection("social_posts").document(postID).delete { [weak self] error in
            if let error = error {
                self?.errorMessage = "ลบโพสต์ไม่สำเร็จ: \(error.localizedDescription)"
            } else {
                // Firestore Listener จะอัปเดตหน้าจอให้อัตโนมัติ แต่เราลบออกจาก array local เพื่อความลื่นไหลทันทีก็ได้
                if let index = self?.posts.firstIndex(where: { $0.id == postID }) {
                    self?.posts.remove(at: index)
                }
            }
        }
    }
    
    /// ดึงคอมเมนต์ของโพสต์ที่กำหนด (ใช้ใน PostDetailView)
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
    func addComment(to postID: String, content: String, isAnonymous: Bool, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else { return }
        let userID = user.uid
        
        // ต้องดึงชื่อจริงจาก Collection 'users' ก่อน (ใช้ Logic เดียวกับ createPost)
        db.collection("users").document(userID).getDocument { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            var realName = "Unknown User"
            if let data = snapshot?.data(), let nameFromDB = data["name"] as? String { // สมมติว่า key คือ "name"
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
    
    /// ลบคอมเมนต์ที่กำหนด (Admin สามารถใช้ฟังก์ชันนี้ได้)
    func deleteComment(postID: String, commentID: String) {
        db.collection("social_posts").document(postID)
            .collection("comments").document(commentID).delete { error in
                if let error = error {
                    print("Error deleting comment: \(error.localizedDescription)")
                } else {
                    print("Comment deleted successfully!")
                    // ไม่ต้องอัปเดต array เพราะ listener ใน CommentViewModel จัดการให้แล้ว
                }
            }
    }

}

