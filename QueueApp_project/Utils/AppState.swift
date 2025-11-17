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
    
    // R3: State สำหรับการจอง/คิว "ส่วนตัว" (ของ User นี้)
    // (ถ้าค่าใดค่าหนึ่ง != nil แปลว่าจองอยู่)
    @Published var activeReservation: (docID: String, data: Booking)? = nil
    @Published var activeQueue: (docID: String, data: Booking)? = nil
    
    // R1: State สำหรับ "ช่อง" ที่ถูกจองไปแล้วทั้งหมด (สำหรับกันจองซ้ำ)
    @Published var currentServiceBookedSlots: Set<String> = []
    
    // R2: State สำหรับ Timer (Board Game)
    @Published var queueTimeRemaining: TimeInterval = 180
    @Published var showQueueAlert: Bool = false // 👈 นี่คือตัวที่แก้ Error
    
    // R2: State สำหรับ Admin Panel
    @Published var allAdminBookings: [(docID: String, data: Booking)] = []

    
    // MARK: - 2. Firebase & Listeners
    
    private let db = Firestore.firestore()
    private var activityListeners: [UUID: ListenerRegistration] = [:] // Listener คิว (ของเดิม)
    private var personalBookingListener: ListenerRegistration? // 👈 Listener ส่วนตัว
    private var currentServiceListener: ListenerRegistration?  // 👈 Listener ส่วนรวม (R1)
    private var adminListener: ListenerRegistration?           // 👈 Listener ของ Admin (R2)
    private var timerSubscription: AnyCancellable?

    
    // MARK: - 3. Core Data Models
    
    enum UserRole {
        case admin
        case student
    }

    // ⭐️⭐️⭐️ (R1, R2, R3) อัปเกรด Booking struct ⭐️⭐️⭐️
    struct Booking: Codable, Identifiable {
        @DocumentID var id: String? // Firestore จะ map ID ให้เอง
        
        let userID: String // 👈 studentID 11 หลัก
        let serviceName: String
        let bookingType: String // "Reservation" หรือ "Queue"
        
        // R2 & R3: สถานะ
        var status: String // "Booked", "Queued", "In-Use", "Finished", "Cancelled"
        
        // R1: ข้อมูลช่องที่จอง
        let slotID: String?      // e.g., "Slot 5", "Room 1", "Table 2"
        let timeSlot: String?    // e.g., "10:00 - 12:00"
        let items: [String]?     // e.g., ["Camera", "Tripod"]
        
        // R4: เวลา
        let startTime: Timestamp // เวลาที่สร้าง (สำหรับ Queue)
        
        // (Helper)
        var details: String {
            var parts = [String]()
            if let slotID = slotID { parts.append(slotID) }
            if let timeSlot = timeSlot { parts.append("@ \(timeSlot)") }
            if let items = items, !items.isEmpty { parts.append("(\(items.count) items)") }
            return parts.joined(separator: " ")
        }
    }
    
    // (สถานะที่ถือว่า Active)
    private var activeStatuses = ["Booked", "Queued", "In-Use"]

    
    // MARK: - 4. Personal Booking Logic (R3)
    
    var hasActiveBooking: Bool {
        activeReservation != nil || activeQueue != nil
    }

    // ⭐️ (R3) Listener ส่วนตัว (ค้นหาเฉพาะ Status ที่ Active)
    func listenForActiveBooking() {
        guard let userID = currentUser?.id else { return } // 👈 ดึง studentID
        
        if personalBookingListener != nil { personalBookingListener?.remove() }
        
        print("Starting PERSONAL booking listener for user: \(userID)")
        
        personalBookingListener = db.collection("bookings")
            .whereField("userID", isEqualTo: userID)
            .whereField("status", in: activeStatuses) // 👈 (R3) ค้นหาเฉพาะ 3 สถานะนี้
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error { print("Error listening for personal bookings: \(error.localizedDescription)"); return }
                
                guard let document = querySnapshot?.documents.first else {
                    // ไม่เจอเอกสาร (แปลว่าไม่มีการจอง/คิว ที่ Active)
                    if self.activeReservation != nil || self.activeQueue != nil {
                        self.clearLocalBooking(fromListener: true)
                    }
                    return
                }
                
                do {
                    let bookingData = try document.data(as: Booking.self)
                    let docID = document.documentID
                    
                    if bookingData.bookingType == "Reservation" {
                        self.activeReservation = (docID, bookingData)
                        self.activeQueue = nil
                        self.stopQueueTimer()
                    } else if bookingData.bookingType == "Queue" {
                        self.activeQueue = (docID, bookingData)
                        self.activeReservation = nil
                        self.startQueueTimer(startTime: bookingData.startTime.dateValue())
                    }
                    
                } catch {
                    print("Failed to decode personal booking: \(error)")
                }
            }
    }
    
    // ⭐️ หยุด Listener ส่วนตัว (ตอน Logout)
    func stopListeningForBooking() {
        print("Stopping personal booking listener.")
        personalBookingListener?.remove()
        personalBookingListener = nil
        clearLocalBooking(fromListener: true)
    }

    // ⭐️ (R3) ฟังก์ชัน "สร้าง" การจอง (เขียน Status: Booked)
    func createReservation(service: LibraryService, slotID: String, timeSlot: String?, items: [String]?) {
        guard let userID = currentUser?.id else { return } // 👈 ดึง studentID
        
        let newBooking = Booking(
            userID: userID, // 👈 บันทึก studentID ลง Firestore
            serviceName: service.name,
            bookingType: "Reservation",
            status: "Booked", // 👈 R2
            slotID: slotID,   // 👈 R1
            timeSlot: timeSlot, // 👈 R1
            items: items,       // 👈 R1
            startTime: Timestamp(date: Date())
        )
        do {
            try db.collection("bookings").addDocument(from: newBooking)
        } catch { print("Error creating reservation: \(error)") }
    }
    
    // ⭐️ (R3) ฟังก์ชัน "เข้าคิว" (เขียน Status: Queued)
    func joinQueue(service: LibraryService, slotID: String, items: [String]?) {
        guard let userID = currentUser?.id else { return } // 👈 ดึง studentID
        
        let newQueue = Booking(
            userID: userID, // 👈 บันทึก studentID ลง Firestore
            serviceName: service.name,
            bookingType: "Queue",
            status: "Queued", // 👈 R2
            slotID: slotID,   // 👈 R1
            timeSlot: nil,
            items: items,       // 👈 R1
            startTime: Timestamp(date: Date()) // 👈 R4
        )
        do {
            try db.collection("bookings").addDocument(from: newQueue)
        } catch { print("Error joining queue: \(error)") }
    }

    // ⭐️ (R3) แก้ไข: เปลี่ยนจาก "ลบ" เป็น "อัปเดต"
    // (นี่คือฟังก์ชันที่แก้ Error 3)
    func cancelActiveBooking(fromListener: Bool = false) {
        if fromListener {
            DispatchQueue.main.async {
                self.activeReservation = nil
                self.activeQueue = nil
                self.stopQueueTimer()
            }
            return
        }
        
        let docIDToCancel = activeReservation?.docID ?? activeQueue?.docID
        guard let docID = docIDToCancel else {
            clearLocalBooking(fromListener: true)
            return
        }
        
        // ⭐️ R3: อัปเดตสถานะเป็น "Cancelled" แทนการลบ
        db.collection("bookings").document(docID).updateData([
            "status": "Cancelled"
        ]) { error in
            if let error = error { print("Error cancelling booking: \(error)") }
            else { print("Booking status set to Cancelled.") }
            // (Listener ส่วนตัว จะเห็นการเปลี่ยนแปลงนี้ และล้างค่า local ให้อัตโนมัติ)
        }
    }
    
    // (Helper function)
    private func clearLocalBooking(fromListener: Bool = false) {
        if fromListener {
            DispatchQueue.main.async {
                self.activeReservation = nil
                self.activeQueue = nil
                self.stopQueueTimer()
            }
        }
    }

    
    // MARK: - 5. Global Booking Logic (R1 - Real-time Status)
    
    // ⭐️ (R1) Listener ส่วนรวม (ถูกเรียกจาก .onAppear ของ View)
    func listenToServiceBookings(service: String, timeSlot: String?) {
        stopListeningToServiceBookings() // หยุด Listener เก่าก่อน
        print("Starting GLOBAL listener for: \(service) @ \(timeSlot ?? "N/A")")
        
        var query: Query = db.collection("bookings")
            .whereField("serviceName", isEqualTo: service)
            .whereField("status", in: activeStatuses) // 👈 R1: ดึงเฉพาะที่ยัง Active
        
        if let timeSlot = timeSlot {
            query = query.whereField("timeSlot", isEqualTo: timeSlot)
        }

        currentServiceListener = query.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }
            if let error = error { print("Error listening to service bookings: \(error)"); return }
            
            guard let documents = querySnapshot?.documents else { return }
            
            let bookedSlots = documents.compactMap { $0.data()["slotID"] as? String }
            
            DispatchQueue.main.async {
                self.currentServiceBookedSlots = Set(bookedSlots)
                print("Updated booked slots: \(self.currentServiceBookedSlots)")
            }
        }
    }
    
    // ⭐️ (R1) หยุด Listener ส่วนรวม
    func stopListeningToServiceBookings() {
        currentServiceListener?.remove()
        currentServiceListener = nil
        DispatchQueue.main.async {
            self.currentServiceBookedSlots = []
        }
    }
    
    
    // MARK: - 6. Admin Logic (R2)
    
    // ⭐️ (R2) Listener สำหรับ Admin Panel
    func listenToAdminBookings() {
        if adminListener != nil { adminListener?.remove() }
        print("Starting ADMIN listener...")

        adminListener = db.collection("bookings")
            .whereField("status", in: activeStatuses) // 👈 ดึงทุกคิวที่ Active
            .order(by: "startTime", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if let error = error { print("Error listening for admin: \(error)"); return }
                
                guard let documents = querySnapshot?.documents else { return }
                
                let bookings = documents.compactMap { doc -> (docID: String, data: Booking)? in
                    do {
                        let bookingData = try doc.data(as: Booking.self)
                        return (doc.documentID, bookingData)
                    } catch {
                        print("Admin failed to decode booking: \(error)")
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    self.allAdminBookings = bookings
                }
            }
    }
    
    // ⭐️ (R2) หยุด Listener Admin
    func stopListeningToAdminBookings() {
        adminListener?.remove()
        adminListener = nil
        DispatchQueue.main.async {
            self.allAdminBookings = []
        }
    }
    
    // ⭐️ (R2) ฟังก์ชัน "Check-in"
    func checkInBooking(docID: String) {
        db.collection("bookings").document(docID).updateData([
            "status": "In-Use"
        ])
    }
    
    // ⭐️ (R2) ฟังก์ชัน "Check-out"
    func finishBooking(docID: String) {
        db.collection("bookings").document(docID).updateData([
            "status": "Finished"
        ])
    }
    

    // MARK: - 7. Timer Logic (for Queue)
    
    // (R2, R4) Timer ที่แม่นยำขึ้น
    func startQueueTimer(startTime: Date) {
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, 180 - elapsed)
        self.queueTimeRemaining = remaining

        if remaining == 0 {
            self.showQueueAlert = true
            self.cancelActiveBooking() // 👈 เปลี่ยนเป็น cancel (อัปเดต status)
            return
        }
        
        stopQueueTimer()
        
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.activeQueue != nil else { return }
                
                if self.queueTimeRemaining > 0 {
                    self.queueTimeRemaining -= 1
                } else {
                    self.stopQueueTimer()
                    self.showQueueAlert = true
                    self.cancelActiveBooking() // 👈 เปลี่ยนเป็น cancel (อัปเดต status)
                }
            }
    }
    
    func stopQueueTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    
    // MARK: - 8. Authentication (Login/Register)
    // (โค้ดส่วนนี้คือเวอร์ชันที่ใช้ studentID 11 หลัก)
    
    func logout() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoggedIn = false
            currentUser = nil
            isBrowsingAsGuest = false
            stopListeningForBooking() // 👈 หยุด Listener ส่วนตัว
            stopListeningToAdminBookings() // 👈 หยุด Listener Admin
            stopListeningToServiceBookings() // 👈 หยุด Listener Service
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
                            self.listenForActiveBooking() // 👈 เริ่ม Listener ส่วนตัว
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
                        self.listenForActiveBooking() // 👈 เริ่ม Listener ส่วนตัว
                    }
                    completion(true, nil)
                }
            }
        }
    }
    
    
    // MARK: - 9. Original QueueApp Logic (Activities)
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
