//
//  AppState.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

class AppState: ObservableObject {
    
    // MARK: - 1. Published Properties (State)
    
    // --- State เดิม (Authentication & QueueApp) ---
    @Published var isLoggedIn = false
    @Published var currentUser: (role: UserRole, name: String, id: String)? // id = studentID 11 หลัก
    @Published var activities: [Activity] = [] // (คิวของ QueueApp)
    @Published var isBrowsingAsGuest = false
    
    // --- State ใหม่ (Library Booking System) ---
    
    // R3: State สำหรับการจอง "ส่วนตัว" (ของ User นี้)
    // (รวมทั้ง Reservation และ Queue เก่า มาเป็น Booking เดียวกัน)
    @Published var activeReservation: (docID: String, data: Booking)? = nil
    @Published var activeQueue: (docID: String, data: Booking)? = nil // (อาจไม่ได้ใช้แล้ว ถ้าปรับเป็น Reservation หมด แต่เก็บไว้กัน error)
    
    // R1: State สำหรับ "ช่อง" ที่ถูกจองไปแล้วทั้งหมด (สำหรับกันจองซ้ำ)
    @Published var currentServiceBookedSlots: Set<String> = []
    
    // R2: State สำหรับ "เกม" ที่ถูกยืมไปแล้ว (In-Use)
    @Published var currentBookedGames: Set<String> = []
    
    // R2, R4: ตัวแปรเวลาที่เหลือ (ใช้ร่วมกันทั้ง Queue และ Usage)
    @Published var timeRemaining: TimeInterval = 0
    @Published var showQueueAlert: Bool = false // แจ้งเตือนหมดเวลา
    @Published var showExtendAlert: Bool = false // แจ้งเตือนต่อเวลา (10 นาทีสุดท้าย)
    
    // R2: State สำหรับ Admin Panel
    @Published var allAdminBookings: [(docID: String, data: Booking)] = []

    
    // MARK: - 2. Firebase & Listeners
    
    private let db = Firestore.firestore()
    private var activityListeners: [UUID: ListenerRegistration] = [:] // Listener คิวเดิม
    
    // Listeners ใหม่
    private var personalBookingListener: ListenerRegistration?
    private var currentServiceListener: ListenerRegistration?
    private var bookedGamesListener: ListenerRegistration?
    private var adminListener: ListenerRegistration?
    
    private var timerSubscription: AnyCancellable?

    
    // MARK: - 3. Core Data Models
    
    enum UserRole {
        case admin
        case student
    }

    // ⭐️ Data Model สำหรับ Booking
    struct Booking: Codable, Identifiable {
        @DocumentID var id: String?
        
        let userID: String // studentID 11 หลัก
        let serviceName: String
        let bookingType: String // "Reservation" (เป็นหลัก) หรือ "Queue"
        var status: String // "Booked", "Queued", "In-Use", "Finished", "Cancelled"
        
        // ข้อมูลการจอง
        let slotID: String?      // e.g., "Slot 5", "Room 1", "Table 2"
        let timeSlot: String?    // e.g., "10:00 - 12:00"
        let items: [String]?     // e.g., ["Catan", "Uno"]
        
        // เวลา
        let startTime: Timestamp // เวลาเริ่ม (หรือเวลาจอง)
        var endTime: Timestamp?  // ⭐️ เวลาสิ้นสุด (สำหรับคำนวณ 2 ชม.) - เป็น Optional
        var extensionCount: Int? // ⭐️ จำนวนครั้งที่ต่อเวลา - เป็น Optional
        
        var details: String {
            var parts = [String]()
            if let slotID = slotID { parts.append(slotID) }
            if let timeSlot = timeSlot { parts.append("@ \(timeSlot)") }
            if let items = items, !items.isEmpty { parts.append("(\(items.count) items)") }
            return parts.joined(separator: " ")
        }
    }
    
    // สถานะที่ถือว่า Active
    private var activeStatuses = ["Booked", "Queued", "In-Use"]

    
    // MARK: - 4. Personal Booking Logic (Student)
    
    var hasActiveBooking: Bool {
        activeReservation != nil || activeQueue != nil
    }

    // ⭐️ Listener ส่วนตัว: ดักฟังการจองของตัวเอง
    func listenForActiveBooking() {
        guard let userID = currentUser?.id else { return }
        
        if personalBookingListener != nil { personalBookingListener?.remove() }
        
        print("Starting PERSONAL booking listener for user: \(userID)")
        
        personalBookingListener = db.collection("bookings")
            .whereField("userID", isEqualTo: userID)
            .whereField("status", in: activeStatuses)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error { print("Error listening for personal: \(error)"); return }
                
                guard let document = querySnapshot?.documents.first else {
                    // ไม่เจอเอกสาร = ไม่มีการจอง
                    if self.activeReservation != nil || self.activeQueue != nil {
                        self.clearLocalBooking(fromListener: true)
                    }
                    return
                }
                
                do {
                    let bookingData = try document.data(as: Booking.self)
                    let docID = document.documentID
                    
                    // เก็บลง activeReservation (ใช้ตัวนี้เป็นหลักสำหรับทุกอย่าง)
                    self.activeReservation = (docID, bookingData)
                    self.activeQueue = nil // ล้างค่าเก่า
                    
                    // ⭐️ เริ่มจับเวลา (Unified Timer)
                    self.startTimer(booking: bookingData)
                    
                } catch {
                    print("Failed to decode personal booking: \(error)")
                }
            }
    }
    
    func stopListeningForBooking() {
        personalBookingListener?.remove()
        personalBookingListener = nil
        clearLocalBooking(fromListener: true)
    }

    // ⭐️ สร้าง Reservation (รอ Admin Check-in ถึงเริ่มนับเวลา)
    func createReservation(service: LibraryService, slotID: String, timeSlot: String?, items: [String]?) {
        guard let userID = currentUser?.id else { return }
        
        let newBooking = Booking(
            userID: userID,
            serviceName: service.name,
            bookingType: "Reservation",
            status: "Booked",
            slotID: slotID,
            timeSlot: timeSlot,
            items: items,
            startTime: Timestamp(date: Date()), // เวลาที่กดจอง
            endTime: nil, // ⭐️ ยังไม่เริ่มนับเวลา! รอ Admin Check-in
            extensionCount: 0
        )
        do {
            try db.collection("bookings").addDocument(from: newBooking)
        } catch {
            print("Error creating reservation: \(error)")
        }
    }
    
    // (ฟังก์ชันนี้อาจไม่ได้ใช้แล้ว เพราะ BoardGame เปลี่ยนไปใช้ createReservation แต่เก็บไว้กัน error)
    func joinQueue(service: LibraryService, slotID: String, items: [String]?) {
        createReservation(service: service, slotID: slotID, timeSlot: nil, items: items)
    }

    // ⭐️ ต่อเวลา (+2 ชม.)
    func extendBooking() {
        guard let booking = activeReservation ?? activeQueue else { return }
        
        // ต้องมีเวลาจบอยู่แล้วถึงจะต่อได้
        guard let currentEndTime = booking.data.endTime?.dateValue() else { return }
        
        // เพิ่มเวลา 2 ชั่วโมง จากเวลาเดิม
        let newEndTime = currentEndTime.addingTimeInterval(7200)
        
        db.collection("bookings").document(booking.docID).updateData([
            "endTime": Timestamp(date: newEndTime),
            "extensionCount": (booking.data.extensionCount ?? 0) + 1
        ]) { _ in
            self.showExtendAlert = false
            print("Booking extended!")
        }
    }

    // ⭐️ ยกเลิก/จบการจอง (เปลี่ยน Status เป็น Cancelled)
    func cancelActiveBooking(fromListener: Bool = false) {
        if fromListener {
            DispatchQueue.main.async {
                self.activeReservation = nil
                self.activeQueue = nil
                self.stopTimer()
            }
            return
        }
        
        let docID = activeReservation?.docID ?? activeQueue?.docID
        guard let id = docID else {
            clearLocalBooking(fromListener: true)
            return
        }
        
        db.collection("bookings").document(id).updateData(["status": "Cancelled"])
    }
    
    private func clearLocalBooking(fromListener: Bool = false) {
        if fromListener {
            DispatchQueue.main.async {
                self.activeReservation = nil
                self.activeQueue = nil
                self.stopTimer()
            }
        }
    }

    
    // MARK: - 5. Global Logic (Real-time Status)
    
    // (R1) Listener ส่วนรวม (Slots)
    func listenToServiceBookings(service: String, timeSlot: String?) {
        stopListeningToServiceBookings()
        
        var query: Query = db.collection("bookings")
            .whereField("serviceName", isEqualTo: service)
            .whereField("status", in: activeStatuses)
        
        if let timeSlot = timeSlot {
            query = query.whereField("timeSlot", isEqualTo: timeSlot)
        }

        currentServiceListener = query.addSnapshotListener { [weak self] qs, _ in
            let slots = qs?.documents.compactMap { $0.data()["slotID"] as? String } ?? []
            DispatchQueue.main.async { self?.currentServiceBookedSlots = Set(slots) }
        }
    }
    
    func stopListeningToServiceBookings() {
        currentServiceListener?.remove()
        currentServiceListener = nil
        DispatchQueue.main.async { self.currentServiceBookedSlots = [] }
    }
    
    // (R2) Listener เกมที่ถูกยืม
    func listenToBookedGames() {
        stopListeningToBookedGames()
        bookedGamesListener = db.collection("bookings")
            .whereField("serviceName", isEqualTo: "Board Game")
            .whereField("status", isEqualTo: "In-Use")
            .addSnapshotListener { [weak self] qs, _ in
                let items = qs?.documents.compactMap { $0.data()["items"] as? [String] }.flatMap { $0 } ?? []
                DispatchQueue.main.async { self?.currentBookedGames = Set(items) }
            }
    }
    
    func stopListeningToBookedGames() {
        bookedGamesListener?.remove()
        bookedGamesListener = nil
        DispatchQueue.main.async { self.currentBookedGames = [] }
    }
    
    
    // MARK: - 6. Admin Logic
    
    func listenToAdminBookings() {
        if adminListener != nil { adminListener?.remove() }
        
        // เรียงลำดับเวลา, กรองเฉพาะ Active
        adminListener = db.collection("bookings")
            .whereField("status", in: activeStatuses)
            // .order(by: "startTime", descending: true) // ถ้ายังไม่ได้ทำ Index ให้ comment บรรทัดนี้ไว้ก่อน
            .addSnapshotListener { [weak self] qs, error in
                if let error = error { print("Admin Error: \(error)"); return }
                
                // Decode แบบปลอดภัย (ถ้าอันไหนพังก็ข้ามไป)
                let bookings = qs?.documents.compactMap { doc -> (String, Booking)? in
                    guard let booking = try? doc.data(as: Booking.self) else { return nil }
                    return (doc.documentID, booking)
                } ?? []
                
                DispatchQueue.main.async { self?.allAdminBookings = bookings }
            }
    }
    
    func stopListeningToAdminBookings() {
        adminListener?.remove()
        adminListener = nil
        allAdminBookings = []
    }
    
    // (Optimistic Update) Check-in: เริ่มนับเวลา 2 ชม.
    func checkInBooking(docID: String) {
        // Update UI ทันที
        if let index = allAdminBookings.firstIndex(where: { $0.docID == docID }) {
            withAnimation { allAdminBookings[index].data.status = "In-Use" }
        }
        
        let now = Date()
        let endTime = now.addingTimeInterval(7200) // ⭐️ +2 ชั่วโมง จากเวลาที่ Check-in
        
        // Update Firebase
        db.collection("bookings").document(docID).updateData([
            "status": "In-Use",
            "startTime": Timestamp(date: now), // อัปเดตเวลาเริ่มจริง
            "endTime": Timestamp(date: endTime) // ⭐️ บันทึกเวลาจบจริง
        ])
    }
    
    // (Optimistic Update) Finish
    func finishBooking(docID: String) {
        if let index = allAdminBookings.firstIndex(where: { $0.docID == docID }) {
            withAnimation { allAdminBookings[index].data.status = "Finished" }
        }
        db.collection("bookings").document(docID).updateData(["status": "Finished"])
    }
    
    // (Optimistic Update) Skip Time
    func adminSkipTime(docID: String) {
        // เหลือ 10 นาที (600 วิ)
        let newEndTime = Date().addingTimeInterval(600)
        
        // Update UI
        if let index = allAdminBookings.firstIndex(where: { $0.docID == docID }) {
            withAnimation { allAdminBookings[index].data.endTime = Timestamp(date: newEndTime) }
        }
        
        // Update Firebase
        db.collection("bookings").document(docID).updateData([
            "endTime": Timestamp(date: newEndTime)
        ])
    }

    
    // MARK: - 7. Unified Timer Logic
    
    // ⭐️ Timer ที่ฉลาดขึ้น (เริ่มนับเมื่อ In-Use เท่านั้น)
    func startTimer(booking: Booking) {
        stopTimer()
        
        // กรณีที่ 1: ยังไม่ได้ Check-in (Status = Booked/Queued)
        // ให้โชว์เวลา 2 ชม. ค้างไว้เฉยๆ (7200 วินาที)
        if booking.status == "Booked" || booking.status == "Queued" {
            self.timeRemaining = 7200
            return // ⛔️ จบฟังก์ชันเลย ไม่ต้องสร้าง Timer
        }
        
        // กรณีที่ 2: กำลังใช้งาน (Status = In-Use) -> นับถอยหลังตามจริง
        if booking.status == "In-Use" {
            timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    
                    let targetTime = booking.endTime?.dateValue() ?? Date()
                    let remaining = targetTime.timeIntervalSince(Date())
                    self.timeRemaining = max(0, remaining)
                    
                    // Alert ต่อเวลา (เหลือ <= 10 นาที และไม่เคยต่อ)
                    if self.timeRemaining <= 600 && self.timeRemaining > 0 && (booking.extensionCount ?? 0) == 0 {
                        if !self.showExtendAlert { self.showExtendAlert = true }
                    } else {
                        self.showExtendAlert = false
                    }
                    
                    // หมดเวลา
                    if self.timeRemaining <= 0 {
                        self.stopTimer()
                        self.showQueueAlert = true
                        // (คุณอาจเลือกที่จะ cancelActiveBooking() อัตโนมัติ หรือให้ค้างหน้านี้ไว้รอคืนของก็ได้)
                    }
                }
        }
    }
    
    func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    
    // MARK: - 8. Authentication
    func logout() {
        withAnimation {
            isLoggedIn = false; currentUser = nil; isBrowsingAsGuest = false
            stopListeningForBooking(); stopListeningToAdminBookings(); stopListeningToServiceBookings(); stopListeningToBookedGames()
        }
        try? Auth.auth().signOut()
    }

    func register(name: String, studentID: String, email: String, password: String, role: UserRole, completion: @escaping (Bool, String?) -> Void) {
        guard studentID.count == 11, studentID.allSatisfy({ $0.isNumber }) else { completion(false, "ID ต้องเป็นตัวเลข 11 หลัก"); return }
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error { completion(false, error.localizedDescription) }
            else if let user = authResult?.user {
                let userData: [String: Any] = ["name": name, "studentID": studentID, "email": email, "role": role == .student ? "student" : "admin"]
                self.db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error { completion(false, "Failed to save user data.") }
                    else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.currentUser = (role: role, name: name, id: studentID)
                            self.isLoggedIn = true; self.isBrowsingAsGuest = false; self.listenForActiveBooking()
                        }
                        completion(true, nil)
                    }
                }
            } else { completion(false, "Failed to retrieve user information.") }
        }
    }

    func loginAsStudent(studentID: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("users").whereField("studentID", isEqualTo: studentID).getDocuments { (qs, err) in
            if err != nil { completion(false, "Failed to retrieve user data."); return }
            guard let doc = qs?.documents.first else { completion(false, "Invalid Student ID."); return }
            
            let data = doc.data()
            let email = data["email"] as? String ?? ""
            let name = data["name"] as? String ?? ""
            let role: UserRole = (data["role"] as? String ?? "student") == "admin" ? .admin : .student
            
            Auth.auth().signIn(withEmail: email, password: password) { authResult, err in
                if err != nil { completion(false, "Invalid Password.") }
                else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.currentUser = (role: role, name: name, id: studentID)
                        self.isLoggedIn = true; self.isBrowsingAsGuest = false; self.listenForActiveBooking()
                    }
                    completion(true, nil)
                }
            }
        }
    }
    
    
    // MARK: - 9. Legacy QueueApp (ย่อไว้)
    func addActivity(name: String) {
        let new = Activity(name: name)
        activities.append(new)
        // Store Activity data. `id` for Activity is UUID, but Firestore document ID is a String.
        // We store the UUID string as the document ID and other properties inside.
        db.collection("activities").document(new.id.uuidString).setData([
            "name": new.name,
            "nextQueueNumber": new.nextQueueNumber,
            "currentQueueNumber": new.currentQueueNumber ?? NSNull(), // Handle optional currentQueueNumber
            "queueCount": new.queueCount
        ])
    }

    func loadActivities() {
        db.collection("activities").getDocuments { [weak self] (qs, _) in
            guard let self = self else { return }
            // Manually map Activity because its `id` (UUID) is derived from the documentID string,
            // and other properties are standard dictionary fields.
            let loadedActivities = qs?.documents.compactMap { doc -> Activity? in
                guard let id = UUID(uuidString: doc.documentID) else { return nil }
                let d = doc.data()
                let activity = Activity(
                    id: id,
                    name: d["name"] as? String ?? "",
                    nextQueueNumber: d["nextQueueNumber"] as? Int ?? 1,
                    currentQueueNumber: d["currentQueueNumber"] as? Int,
                    queueCount: d["queueCount"] as? Int ?? 0
                )
                // Do NOT call loadQueueItems here. Queues are managed by startListening
                return activity
            } ?? []
            
            DispatchQueue.main.async {
                self.activities = loadedActivities
            }
        }
    }

    func updateActivity(activity: Activity) {
        db.collection("activities").document(activity.id.uuidString).setData([
            "name": activity.name,
            "nextQueueNumber": activity.nextQueueNumber,
            "currentQueueNumber": activity.currentQueueNumber ?? NSNull(), // Handle optional currentQueueNumber
            "queueCount": activity.queueCount
        ])
    }

    func deleteActivity(activity: Activity) {
        db.collection("activities").document(activity.id.uuidString).delete()
    }

    func addQueueItem(activity: Activity, queueItem: QueueItem) {
        // Use setData(from:) because QueueItem is Codable
        do {
            try db.collection("activities").document(activity.id.uuidString)
                .collection("queues").document(queueItem.id.uuidString)
                .setData(from: queueItem) { _ in
                    self.updateQueueCount(activity: activity, increment: true)
                    // loadActivities() might be too broad; consider only updating the specific activity
                }
        } catch {
            print("Error adding queue item: \(error)")
        }
    }

    func loadQueueItems(activity: Activity, completion: @escaping ([QueueItem]) -> Void) {
        db.collection("activities").document(activity.id.uuidString).collection("queues")
            .order(by: "number")
            .getDocuments { (qs, _) in
                let items = qs?.documents.compactMap { doc -> QueueItem? in
                    // Use data(as:) for Codable decoding
                    try? doc.data(as: QueueItem.self)
                }.filter { $0.status == nil } ?? [] // Filter after successful decoding
                completion(items)
            }
    }

    func updateQueueItemStatus(activity: Activity, queueItem: QueueItem, status: String) {
        db.collection("activities").document(activity.id.uuidString).collection("queues")
            .document(queueItem.id.uuidString)
            .updateData(["status": status]) { _ in
                self.updateCurrentQueueNumber(activity: activity, queueItem: queueItem)
                // loadActivities() might be too broad; consider only updating the specific activity
            }
    }

    func deleteQueueItem(activity: Activity, queueItem: QueueItem) {
        // Implementation for deleting a specific queue item
        db.collection("activities").document(activity.id.uuidString).collection("queues")
            .document(queueItem.id.uuidString).delete { _ in
                self.updateQueueCount(activity: activity, increment: false)
                // No need to loadActivities() here as the listener should handle updates
            }
    }

    func updateCurrentQueueNumber(activity: Activity, queueItem: QueueItem) {
        db.collection("activities").document(activity.id.uuidString)
            .updateData(["currentQueueNumber": queueItem.number]) { _ in
                // Directly update the observed object if needed, though listener might also update
                activity.currentQueueNumber = queueItem.number
            }
    }

    func updateQueueCount(activity: Activity, increment: Bool) {
        let c = max(0, activity.queueCount + (increment ? 1 : -1))
        db.collection("activities").document(activity.id.uuidString)
            .updateData(["queueCount": c]) { _ in
                // Directly update the observed object if needed, though listener might also update
                activity.queueCount = c
            }
    }

    func startListening(to activity: Activity) {
        guard activityListeners[activity.id] == nil else { return }
        activityListeners[activity.id] = db.collection("activities").document(activity.id.uuidString).collection("queues")
            .addSnapshotListener { [weak self] qs, _ in
                let items = qs?.documents.compactMap { doc -> QueueItem? in
                    // Use data(as:) for Codable decoding
                    try? doc.data(as: QueueItem.self)
                }.filter { $0.status == nil } ?? [] // Filter after successful decoding
                
                DispatchQueue.main.async {
                    activity.queues = items
                }
            }
    }

    func stopListening(to activity: Activity) {
        activityListeners[activity.id]?.remove()
        activityListeners.removeValue(forKey: activity.id)
    }
}
