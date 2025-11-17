import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

class AppState: ObservableObject {
    
    // MARK: - 1. Published Properties (State)
    
    // --- State เดิม (Authentication & QueueApp) ---
    @Published var isLoggedIn = false
    @Published var currentUser: (role: UserRole, name: String, id: String)? // id = studentID 11 หลัก
    @Published var activities: [Activity] = [] // (นี่คือคิวของ QueueApp)
    @Published var isBrowsingAsGuest = false
    
    // --- State ใหม่ (Library Booking System) ---
    // R3: เก็บการจอง/คิว ได้แค่ 1 อย่าง (ถ้าค่าใดค่าหนึ่ง != nil แปลว่าจองอยู่)
    @Published var activeReservation: (docID: String, data: Booking)? = nil
    @Published var activeQueue: (docID: String, data: Booking)? = nil
    
    // R2, R4: State สำหรับ Timer นับถอยหลัง (Board Game)
    @Published var queueTimeRemaining: TimeInterval = 180
    @Published var showQueueAlert: Bool = false // R5: สำหรับแจ้งเตือน
    
    
    // MARK: - 2. Firebase & Listeners
    
    private let db = Firestore.firestore()
    private var activityListeners: [UUID: ListenerRegistration] = [:] // Listener คิว (ของเดิม)
    private var bookingListener: ListenerRegistration? // 👈 Listener การจอง (ของใหม่)
    private var timerSubscription: AnyCancellable?

    
    // MARK: - 3. Core Data Models
    
    enum UserRole {
        case admin
        case student
    }
    
    // ⭐️ Data Model ใหม่สำหรับ Booking (ใช้คุยกับ Firestore)
    struct Booking: Codable {
        let userID: String // 👈 จะเก็บ studentID 11 หลัก
        let serviceName: String
        let bookingType: String // "reservation" หรือ "queue"
        let details: String
        let startTime: Timestamp // 👈 (สำหรับ Queue Timer)
    }

    
    // MARK: - 4. Core Booking Logic (Reservation & Queue)
    
    // เช็กว่ามีจอง/คิว อยู่ไหม
    var hasActiveBooking: Bool {
        activeReservation != nil || activeQueue != nil
    }

    // ⭐️ ฟังก์ชันนี้จะถูกเรียกตอน Login/Register สำเร็จ
    func listenForActiveBooking() {
        guard let userID = currentUser?.id else { return } // 👈 ดึง studentID
        
        if bookingListener != nil {
            bookingListener?.remove() // ลบ Listener เก่า (ถ้ามี)
        }
        
        print("Starting booking listener for user (studentID): \(userID)")
        
        // ⭐️ สร้าง Listener คอยดักฟัง collection "bookings"
        // ที่มี "userID" ตรงกับ studentID 11 หลักของเรา
        bookingListener = db.collection("bookings")
            .whereField("userID", isEqualTo: userID)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for bookings: \(error.localizedDescription)")
                    return
                }
                
                // 1. ถ้าไม่เจอเอกสาร (จองเสร็จ/ยกเลิก/ไม่เคยจอง)
                guard let document = querySnapshot?.documents.first else {
                    // ถ้า state เก่าเรายังมีค่าค้างอยู่ ให้ล้างมันทิ้ง
                    if self.activeReservation != nil || self.activeQueue != nil {
                        self.cancelAllBookings(fromListener: true) // ล้างค่า local
                    }
                    return
                }
                
                // 2. ถ้าเจอเอกสาร (แปลว่ามีการจอง/คิวอยู่)
                do {
                    let bookingData = try document.data(as: Booking.self)
                    let docID = document.documentID
                    
                    if bookingData.bookingType == "reservation" {
                        // ถ้าเป็นการจอง (Co-work, Netflix, Green)
                        self.activeReservation = (docID, bookingData)
                        self.activeQueue = nil
                        self.stopQueueTimer()
                    } else if bookingData.bookingType == "queue" {
                        // ถ้าเป็นการเข้าคิว (Board Game)
                        self.activeQueue = (docID, bookingData)
                        self.activeReservation = nil
                        self.startQueueTimer(startTime: bookingData.startTime.dateValue()) // 👈 เริ่มจับเวลา
                    }
                    
                } catch {
                    print("Failed to decode booking: \(error)")
                }
            }
    }
    
    // ⭐️ หยุด Listener ตอน Logout
    func stopListeningForBooking() {
        print("Stopping booking listener.")
        bookingListener?.remove()
        bookingListener = nil
        cancelAllBookings(fromListener: true) // ล้างค่า local ทั้งหมด
    }

    // ⭐️ ฟังก์ชันใหม่สำหรับ "สร้าง" การจอง (Co-work, Netflix, Green)
    func createReservation(service: LibraryService, details: String) {
        guard let userID = currentUser?.id else { return } // 👈 ดึง studentID
        
        let newBooking = Booking(
            userID: userID, // 👈 บันทึก studentID ลง Firestore
            serviceName: service.name,
            bookingType: "reservation",
            details: details,
            startTime: Timestamp(date: Date())
        )
        
        do {
            // เพิ่มเอกสารใหม่ลง Firestore
            // (เราไม่ต้องเซ็ต @Published var เอง, Listener จะเห็นและอัปเดต UI ให้)
            try db.collection("bookings").addDocument(from: newBooking)
        } catch {
            print("Error creating reservation: \(error)")
        }
    }
    
    // ⭐️ ฟังก์ชันใหม่สำหรับ "เข้าคิว" (Board Game)
    func joinQueue(service: LibraryService, table: Int, games: [String]) {
        guard let userID = currentUser?.id else { return } // 👈 ดึง studentID
        
        let details = "Table \(table) (\(games.count) games)"
        let newQueue = Booking(
            userID: userID, // 👈 บันทึก studentID ลง Firestore
            serviceName: service.name,
            bookingType: "queue",
            details: details,
            startTime: Timestamp(date: Date()) // 👈 เวลาเริ่มคิว (สำคัญมาก)
        )
        
        do {
            try db.collection("bookings").addDocument(from: newQueue)
            // (Listener จะเห็นเอกสารนี้ และสั่ง startQueueTimer อัตโนมัติ)
        } catch {
            print("Error joining queue: \(error)")
        }
    }

    // ⭐️ ฟังก์ชันใหม่สำหรับ "ยกเลิก"
    func cancelAllBookings(fromListener: Bool = false) {
        
        // A. ถ้าถูกเรียกจาก Listener (แปลว่าเอกสารมันหายไปเอง)
        if fromListener {
            DispatchQueue.main.async {
                self.activeReservation = nil
                self.activeQueue = nil
                self.stopQueueTimer()
            }
            return
        }
        
        // B. ถ้าผู้ใช้กด Cancel เอง (เราต้องไปลบเอกสาร)
        let docIDToCancel = activeReservation?.docID ?? activeQueue?.docID
        guard let docID = docIDToCancel else {
            // ถ้าไม่มีอะไรให้ยกเลิก
            activeReservation = nil
            activeQueue = nil
            stopQueueTimer()
            return
        }
        
        // สั่งลบเอกสารออกจาก Firestore
        db.collection("bookings").document(docID).delete { error in
            if let error = error {
                print("Error cancelling booking: \(error)")
            } else {
                print("Booking cancelled successfully.")
                // (Listener จะเห็นว่าเอกสารหายไป และล้างค่า local ให้เราเอง)
            }
        }
    }

    
    // MARK: - 5. Timer Logic (for Queue)
    
    // (R2, R4) Timer ที่แม่นยำขึ้น
    func startQueueTimer(startTime: Date) {
        // คำนวณเวลาที่เหลือจากเวลาที่บันทึกใน Firestore
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, 180 - elapsed) // 180 วิ = 3 นาที
        self.queueTimeRemaining = remaining

        // ถ้าเวลาเหลือ 0 แล้ว ให้ Alert เลย
        if remaining == 0 {
            self.showQueueAlert = true
            self.cancelAllBookings() // ลบออกจาก Firestore
            return
        }
        
        stopQueueTimer() // หยุดของเก่า (ถ้ามี)
        
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.activeQueue != nil else { return }
                
                if self.queueTimeRemaining > 0 {
                    self.queueTimeRemaining -= 1
                } else {
                    // R5: เวลาหมด!
                    self.stopQueueTimer()
                    self.showQueueAlert = true
                    self.cancelAllBookings() // สั่งลบ
                }
            }
    }
    
    func stopQueueTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    
    // MARK: - 6. Authentication (Login/Register)
    
    func logout() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoggedIn = false
            currentUser = nil
            isBrowsingAsGuest = false
            stopListeningForBooking() // 👈 หยุด Listener ตอน Logout
        }
        do { try Auth.auth().signOut() } catch { print("Error signing out: \(error.localizedDescription)") }
    }

    func register(name: String, studentID: String, email: String, password: String, role: UserRole, completion: @escaping (Bool, String?) -> Void) {
        guard studentID.count == 11, studentID.allSatisfy({ $0.isNumber }) else {
            completion(false, "รหัสนักศึกษาต้องมี 11 หลัก และเป็นตัวเลขเท่านั้น")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else if let user = authResult?.user {
                let userData: [String: Any] = ["name": name, "studentID": studentID, "email": email, "role": role == .student ? "student" : "admin"]
                
                self.db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        completion(false, "Failed to save user data.")
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.currentUser = (role: role, name: name, id: studentID) // 👈 ใช้ studentID 11 หลัก
                            self.isLoggedIn = true
                            self.isBrowsingAsGuest = false
                            self.listenForActiveBooking() // 👈 เริ่ม Listener
                        }
                        completion(true, nil)
                    }
                }
            } else {
                completion(false, "Failed to retrieve user information.")
            }
        }
    }

    func loginAsStudent(studentID: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("users").whereField("studentID", isEqualTo: studentID).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(false, "Failed to retrieve user data.")
                return
            }
            guard let document = querySnapshot?.documents.first else {
                completion(false, "Invalid Student ID or Password.")
                return
            }
            let data = document.data()
            let email = data["email"] as? String ?? ""
            let name = data["name"] as? String ?? ""
            let role: UserRole = (data["role"] as? String ?? "student") == "admin" ? .admin : .student
            
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    completion(false, "Invalid Student ID or Password.")
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.currentUser = (role: role, name: name, id: studentID) // 👈 ใช้ studentID 11 หลัก
                        self.isLoggedIn = true
                        self.isBrowsingAsGuest = false
                        self.listenForActiveBooking() // 👈 เริ่ม Listener
                    }
                    completion(true, nil)
                }
            }
        }
    }
    
    
    // MARK: - 7. Original QueueApp Logic (Activities)
    // (โค้ดส่วนนี้ของคุณ ผมคัดลอกมาให้ครบถ้วน)
    
    func addActivity(name: String) {
        let newActivity = Activity(name: name)
        activities.append(newActivity)
        db.collection("activities").document(newActivity.id.uuidString).setData([
            "name": newActivity.name,
            "nextQueueNumber": newActivity.nextQueueNumber,
            "currentQueueNumber": newActivity.currentQueueNumber,
            "queueCount": newActivity.queueCount
        ]) { err in
            if let err = err { print("Error adding document: \(err)") }
            else { print("Document added with ID: \(newActivity.id.uuidString)") }
        }
    }
    
    func loadActivities() {
        db.collection("activities").getDocuments() { [weak self] (querySnapshot, err) in
            guard let self = self else { return }
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                self.activities = querySnapshot!.documents.compactMap { document in
                    let data = document.data()
                    let name = data["name"] as? String ?? ""
                    let nextQueueNumber = data["nextQueueNumber"] as? Int ?? 1
                    let currentQueueNumber = data["currentQueueNumber"] as? Int
                    let queueCount = data["queueCount"] as? Int ?? 0
                    if let idString = document.documentID as String?, let id = UUID(uuidString: idString) {
                        let activity = Activity(id: id, name: name, nextQueueNumber: nextQueueNumber, currentQueueNumber: currentQueueNumber, queueCount: queueCount)
                        self.loadQueueItems(activity: activity) { queueItems in
                            activity.queues = queueItems
                        }
                        return activity
                    } else { return nil }
                }
            }
        }
    }

    func updateActivity(activity: Activity) {
        db.collection("activities").document(activity.id.uuidString).setData([
            "name": activity.name,
            "nextQueueNumber": activity.nextQueueNumber,
            "currentQueueNumber": activity.currentQueueNumber,
            "queueCount": activity.queueCount
        ]) { err in
            if let err = err { print("Error updating document: \(err)") }
            else { print("Document updated with ID: \(activity.id.uuidString)") }
        }
    }

    func deleteActivity(activity: Activity) {
        db.collection("activities").document(activity.id.uuidString).delete() { err in
            if let err = err { print("Error removing document: \(err)") }
            else { print("Document successfully removed!") }
        }
    }

    func addQueueItem(activity: Activity, queueItem: QueueItem) {
        db.collection("activities").document(activity.id.uuidString).collection("queues").document(queueItem.id.uuidString).setData([
            "studentName": queueItem.studentName,
            "number": queueItem.number,
            "studentId": queueItem.studentId,
            "status": queueItem.status
        ]) { err in
            if let err = err {
                print("Error adding queue item: \(err)")
            } else {
                print("Queue item added for activity \(activity.name)")
                self.updateQueueCount(activity: activity, increment: true)
                self.loadActivities()
            }
        }
    }
    
    func loadQueueItems(activity: Activity, completion: @escaping ([QueueItem]) -> Void) {
        db.collection("activities").document(activity.id.uuidString).collection("queues").order(by: "number").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting queue items: \(err)")
                completion([])
            } else {
                let queueItems = querySnapshot!.documents.compactMap { document in
                    let data = document.data()
                    let studentName = data["studentName"] as? String ?? ""
                    let number = data["number"] as? Int ?? 0
                    let studentId = data["studentId"] as? String ?? ""
                    let status = data["status"] as? String
                    if let idString = document.documentID as String?, let id = UUID(uuidString: idString) {
                        return QueueItem(id: id, studentId: studentId, studentName: studentName, number: number, status: status)
                    } else { return nil }
                }.filter { item in
                    item.status == nil
                }
                completion(queueItems)
            }
        }
    }

    func updateQueueItemStatus(activity: Activity, queueItem: QueueItem, status: String) {
        db.collection("activities").document(activity.id.uuidString).collection("queues").document(queueItem.id.uuidString).updateData([
            "status": status
        ]) { err in
            if let err = err {
                print("Error updating queue item status: \(err)")
            } else {
                print("Queue item status updated for \(queueItem.studentName)")
                self.updateCurrentQueueNumber(activity: activity, queueItem: queueItem)
                self.loadActivities()
            }
        }
    }

    func deleteQueueItem(activity: Activity, queueItem: QueueItem) { }

    func updateCurrentQueueNumber(activity: Activity, queueItem: QueueItem) {
        db.collection("activities").document(activity.id.uuidString).updateData([
            "currentQueueNumber": queueItem.number
        ]) { err in
            if let err = err { print("Error updating current queue number: \(err)") }
            else { print("Current queue number updated for activity \(activity.name)"); activity.currentQueueNumber = queueItem.number }
        }
    }

    func updateQueueCount(activity: Activity, increment: Bool) {
        let change = increment ? 1 : -1
        let newCount = max(0, activity.queueCount + change)
        db.collection("activities").document(activity.id.uuidString).updateData([
            "queueCount": newCount
        ]) { err in
            if let err = err { print("Error updating queue count: \(err)") }
            else { print("Queue count updated for activity \(activity.name)"); activity.queueCount = newCount }
        }
    }

    func startListening(to activity: Activity) {
        guard activityListeners[activity.id] == nil else { return }
        let listener = db.collection("activities").document(activity.id.uuidString).collection("queues").addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let queueItems = documents.compactMap { document in
                let data = document.data()
                let studentName = data["studentName"] as? String ?? ""
                let number = data["number"] as? Int ?? 0
                let studentId = data["studentId"] as? String ?? ""
                let status = data["status"] as? String
                if let idString = document.documentID as String?, let id = UUID(uuidString: idString) {
                    return QueueItem(id: id, studentId: studentId, studentName: studentName, number: number, status: status)
                } else { return nil }
            }.filter { item in
                item.status == nil
            }
            DispatchQueue.main.async {
                activity.queues = queueItems
            }
        }
        activityListeners[activity.id] = listener
    }

    func stopListening(to activity: Activity) {
        if let listener = activityListeners[activity.id] {
            listener.remove()
            activityListeners.removeValue(forKey: activity.id)
        }
    }
}
