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

// MARK: - App State (Global Store)
// คลาสหลักสำหรับจัดการ State ทั้งหมดของแอป (Single Source of Truth)
// ทำหน้าที่:
// 1. เก็บข้อมูลผู้ใช้ (User Session)
// 2. จัดการการเชื่อมต่อ Firebase (Authentication & Firestore)
// 3. เก็บสถานะการจอง/คิว (Booking/Queue Status)
// 4. จัดการ Timer สำหรับนับเวลาถอยหลัง
class AppState: ObservableObject {
    
    // MARK: - 1. Published Properties (State)
    // ตัวแปรที่ View จะคอยสังเกตการเปลี่ยนแปลง (Reactive UI)
    
    // --- State เดิม (Authentication & QueueApp) ---
    @Published var isLoggedIn = false // สถานะการล็อกอิน
    @Published var currentUser: (role: UserRole, name: String, id: String)? // ข้อมูลผู้ใช้ปัจจุบัน (id = studentID 11 หลัก)
    @Published var activities: [Activity] = [] // รายการกิจกรรม (สำหรับระบบคิวเดิม)
    @Published var isBrowsingAsGuest = false // สถานะ Guest Mode
    
    // --- State ใหม่ (Dark Mode) ---
    @Published var isDarkMode: Bool = UserDefaults.standard.bool(forKey: "isDarkMode") {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    // --- State ใหม่ (Library Booking System) ---
    
    // R3: State สำหรับการจอง "ส่วนตัว" (ของ User นี้)
    // (รวมทั้ง Reservation และ Queue เก่า มาเป็น Booking เดียวกัน)
    // เก็บข้อมูลการจองปัจจุบันของผู้ใช้ (ถ้ามี)
    @Published var activeReservation: (docID: String, data: Booking)? = nil
    @Published var activeQueue: (docID: String, data: Booking)? = nil // (Legacy: อาจไม่ได้ใช้แล้ว ถ้าปรับเป็น Reservation หมด แต่เก็บไว้กัน error)
    
    // R1: State สำหรับ "ช่อง" ที่ถูกจองไปแล้วทั้งหมด (สำหรับกันจองซ้ำ)
    // เก็บ Set ของ slotID ที่ไม่ว่าง
    @Published var currentServiceBookedSlots: Set<String> = []
    
    // R2: State สำหรับ "เกม" ที่ถูกยืมไปแล้ว (In-Use)
    // เก็บ Set ของชื่อเกมที่ถูกยืม
    @Published var currentBookedGames: Set<String> = []
    
    // R2, R4: ตัวแปรเวลาที่เหลือ (ใช้ร่วมกันทั้ง Queue และ Usage)
    @Published var timeRemaining: TimeInterval = 0 // เวลาที่เหลือ (วินาที)
    @Published var showQueueAlert: Bool = false // แจ้งเตือนเมื่อหมดเวลา
    @Published var showExtendAlert: Bool = false // แจ้งเตือนให้ต่อเวลา (10 นาทีสุดท้าย)
    
    // R2: State สำหรับ Admin Panel
    // รายการจองทั้งหมดสำหรับหน้า Admin
    @Published var allAdminBookings: [(docID: String, data: Booking)] = []

    
    // MARK: - 2. Firebase & Listeners
    // ตัวจัดการการเชื่อมต่อฐานข้อมูล
    
    private let db = Firestore.firestore()
    private var activityListeners: [UUID: ListenerRegistration] = [:] // Listener สำหรับคิวเดิม (แยกตาม Activity)
    
    // Listeners ใหม่ (Real-time Updates)
    private var personalBookingListener: ListenerRegistration? // ฟังการจองของตัวเอง
    private var currentServiceListener: ListenerRegistration? // ฟังสถานะห้อง/โต๊ะ (ว่าง/ไม่ว่าง)
    private var bookedGamesListener: ListenerRegistration? // ฟังสถานะบอร์ดเกม
    private var adminListener: ListenerRegistration? // ฟังรายการจองทั้งหมด (สำหรับ Admin)
    
    private var timerSubscription: AnyCancellable? // ตัวจัดการ Timer (Combine)

    
    // MARK: - 3. Core Data Models
    // โครงสร้างข้อมูลภายใน App
    
    enum UserRole {
        case admin
        case student
    }

    // ⭐️ Data Model สำหรับ Booking (การจอง)
    // ใช้ Codable เพื่อแปลงไป-กลับจาก Firestore ได้ง่าย
    struct Booking: Codable, Identifiable {
        @DocumentID var id: String? // ID ของเอกสารใน Firestore
        
        let userID: String // รหัสนิสิต (studentID 11 หลัก)
        let serviceName: String // ชื่อบริการ (e.g., "Co-Working Space", "Board Game")
        let bookingType: String // ประเภท: "Reservation" (จองล่วงหน้า/ปกติ) หรือ "Queue" (ต่อคิว)
        var status: String // สถานะ: "Booked" (จองแล้ว), "Queued" (รอคิว), "In-Use" (กำลังใช้งาน), "Finished" (เสร็จสิ้น), "Cancelled" (ยกเลิก)
        
        // ข้อมูลรายละเอียดการจอง
        let slotID: String?      // e.g., "Slot 5", "Room 1", "Table 2"
        let timeSlot: String?    // e.g., "10:00 - 12:00"
        let items: [String]?     // e.g., ["Catan", "Uno"] (สำหรับบอร์ดเกม)
        
        // เวลา
        let startTime: Timestamp // เวลาที่กดจอง
        var endTime: Timestamp?  // ⭐️ เวลาสิ้นสุด (สำหรับคำนวณ 2 ชม.) - เป็น Optional เพราะตอนจองอาจจะยังไม่กำหนดเวลาจบแน่นอน
        var extensionCount: Int? // ⭐️ จำนวนครั้งที่ต่อเวลา (เริ่มที่ 0)
        
        // Helper สำหรับแสดงผลรายละเอียดแบบรวมๆ
        var details: String {
            var parts = [String]()
            if let slotID = slotID { parts.append(slotID) }
            if let timeSlot = timeSlot { parts.append("@ \(timeSlot)") }
            if let items = items, !items.isEmpty { parts.append("(\(items.count) items)") }
            return parts.joined(separator: " ")
        }
    }
    
    // สถานะที่ถือว่า Active (ยังไม่จบ)
    private var activeStatuses = ["Booked", "Queued", "In-Use"]

    
    // MARK: - 4. Personal Booking Logic (Student)
    // ฟังก์ชันจัดการการจองของฝั่งนิสิต
    
    // เช็คว่ามี Booking ค้างอยู่ไหม
    var hasActiveBooking: Bool {
        activeReservation != nil || activeQueue != nil
    }

    // ⭐️ Listener ส่วนตัว: ดักฟังการจองของตัวเองจาก Firestore
    // ทำงานแบบ Real-time: ถ้าสถานะใน Database เปลี่ยน หน้าจอก็จะเปลี่ยนตามทันที
    func listenForActiveBooking() {
        guard let userID = currentUser?.id else { return }
        
        // เคลียร์ Listener เก่าก่อนสร้างใหม่
        if personalBookingListener != nil { personalBookingListener?.remove() }
        
        print("Starting PERSONAL booking listener for user: \(userID)")
        
        personalBookingListener = db.collection("bookings")
            .whereField("userID", isEqualTo: userID)
            .whereField("status", in: activeStatuses) // ดึงเฉพาะที่ยัง Active
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error { print("Error listening for personal: \(error)"); return }
                
                guard let document = querySnapshot?.documents.first else {
                    // ไม่เจอเอกสาร = ไม่มีการจอง (หรือถูกยกเลิก/จบไปแล้ว)
                    if self.activeReservation != nil || self.activeQueue != nil {
                        self.clearLocalBooking(fromListener: true)
                    }
                    return
                }
                
                do {
                    let bookingData = try document.data(as: Booking.self)
                    let docID = document.documentID
                    
                    // อัปเดต State
                    self.activeReservation = (docID, bookingData)
                    self.activeQueue = nil // ล้างค่าเก่า
                    
                    // ⭐️ เริ่มจับเวลา (Unified Timer) ถ้าสถานะเป็น In-Use
                    self.startTimer(booking: bookingData)
                    
                } catch {
                    print("Failed to decode personal booking: \(error)")
                }
            }
    }
    
    // หยุดฟังการจอง (เช่น ตอน Logout)
    func stopListeningForBooking() {
        personalBookingListener?.remove()
        personalBookingListener = nil
        clearLocalBooking(fromListener: true)
    }

    // ⭐️ สร้าง Reservation ใหม่ (บันทึกลง Firestore)
    // สถานะเริ่มต้นจะเป็น "Booked" (รอ Admin Check-in ถึงจะเริ่มนับเวลา)
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
    
    // (Legacy Wrapper) เรียกใช้ createReservation แทน
    func joinQueue(service: LibraryService, slotID: String, items: [String]?) {
        createReservation(service: service, slotID: slotID, timeSlot: nil, items: items)
    }

    // ⭐️ ต่อเวลา (+2 ชม.)
    func extendBooking() {
        guard let booking = activeReservation ?? activeQueue else { return }
        
        // ต้องมีเวลาจบอยู่แล้วถึงจะต่อได้
        guard let currentEndTime = booking.data.endTime?.dateValue() else { return }
        
        // เพิ่มเวลา 2 ชั่วโมง (7200 วินาที) จากเวลาเดิม
        let newEndTime = currentEndTime.addingTimeInterval(7200)
        
        // อัปเดต Firestore
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
        
        // อัปเดต Firestore -> Listener จะทำงานและเคลียร์หน้าจอให้เอง
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
    // ฟังก์ชันสำหรับดูสถานะรวมของระบบ (เช่น ห้องไหนว่างบ้าง)
    
    // (R1) Listener ดูว่า Slot ไหนไม่ว่างบ้าง
    func listenToServiceBookings(service: String, timeSlot: String?) {
        stopListeningToServiceBookings()
        
        var query: Query = db.collection("bookings")
            .whereField("serviceName", isEqualTo: service)
            .whereField("status", in: activeStatuses) // เฉพาะที่ยังไม่จบ
        
        if let timeSlot = timeSlot {
            query = query.whereField("timeSlot", isEqualTo: timeSlot)
        }

        currentServiceListener = query.addSnapshotListener { [weak self] qs, _ in
            // ดึงรายการ slotID ที่ถูกจองไปแล้ว
            let slots = qs?.documents.compactMap { $0.data()["slotID"] as? String } ?? []
            DispatchQueue.main.async { self?.currentServiceBookedSlots = Set(slots) }
        }
    }
    
    func stopListeningToServiceBookings() {
        currentServiceListener?.remove()
        currentServiceListener = nil
        DispatchQueue.main.async { self.currentServiceBookedSlots = [] }
    }
    
    // (R2) Listener ดูว่าเกมไหนถูกยืมไปแล้วบ้าง
    func listenToBookedGames() {
        stopListeningToBookedGames()
        bookedGamesListener = db.collection("bookings")
            .whereField("serviceName", isEqualTo: "Board Game")
            .whereField("status", isEqualTo: "In-Use") // เฉพาะที่กำลังเล่นอยู่
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
    // ฟังก์ชันสำหรับ Admin
    
    // ฟังรายการจองทั้งหมด (Active Bookings)
    func listenToAdminBookings() {
        if adminListener != nil { adminListener?.remove() }
        
        adminListener = db.collection("bookings")
            .whereField("status", in: activeStatuses)
            // .order(by: "startTime", descending: true) // (ต้องทำ Index ใน Firebase ก่อนถึงจะเปิดใช้ได้)
            .addSnapshotListener { [weak self] qs, error in
                if let error = error { print("Admin Error: \(error)"); return }
                
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
    
    // Check-in: เปลี่ยนสถานะเป็น In-Use และเริ่มนับเวลา
    func checkInBooking(docID: String) {
        // Optimistic Update: อัปเดต UI ทันทีให้ดูเร็ว
        if let index = allAdminBookings.firstIndex(where: { $0.docID == docID }) {
            withAnimation { allAdminBookings[index].data.status = "In-Use" }
        }
        
        let now = Date()
        let endTime = now.addingTimeInterval(7200) // ⭐️ +2 ชั่วโมง จากเวลาที่ Check-in จริง
        
        // Update Firebase
        db.collection("bookings").document(docID).updateData([
            "status": "In-Use",
            "startTime": Timestamp(date: now), // อัปเดตเวลาเริ่มจริง
            "endTime": Timestamp(date: endTime) // ⭐️ บันทึกเวลาจบจริง
        ])
    }
    
    // Finish: จบการใช้งาน (คืนของ/ออกจากห้อง)
    func finishBooking(docID: String) {
        if let index = allAdminBookings.firstIndex(where: { $0.docID == docID }) {
            withAnimation { allAdminBookings[index].data.status = "Finished" }
        }
        db.collection("bookings").document(docID).updateData(["status": "Finished"])
    }
    
    // Skip Time: (Debug/Admin Tool) ข้ามเวลาไปเหลือ 10 นาทีสุดท้าย
    func adminSkipTime(docID: String) {
        let newEndTime = Date().addingTimeInterval(600) // อีก 10 นาทีหมดเวลา
        
        if let index = allAdminBookings.firstIndex(where: { $0.docID == docID }) {
            withAnimation { allAdminBookings[index].data.endTime = Timestamp(date: newEndTime) }
        }
        
        db.collection("bookings").document(docID).updateData([
            "endTime": Timestamp(date: newEndTime)
        ])
    }

    
    // MARK: - 7. Unified Timer Logic
    // ระบบจับเวลาถอยหลัง
    
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
                    }
                }
        }
    }
    
    func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }

    
    // MARK: - 8. Authentication
    // จัดการ Login/Register/Logout
    
    func logout() {
        withAnimation {
            isLoggedIn = false; currentUser = nil; isBrowsingAsGuest = false
            stopListeningForBooking(); stopListeningToAdminBookings(); stopListeningToServiceBookings(); stopListeningToBookedGames()
        }
        try? Auth.auth().signOut()
    }

    // สมัครสมาชิก
    func register(name: String, studentID: String, email: String, password: String, role: UserRole, completion: @escaping (Bool, String?) -> Void) {
        guard studentID.count == 11, studentID.allSatisfy({ $0.isNumber }) else { completion(false, "ID ต้องเป็นตัวเลข 11 หลัก"); return }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error { completion(false, error.localizedDescription) }
            else if let user = authResult?.user {
                // บันทึกข้อมูลเพิ่มเติมลง Firestore
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

    // เข้าสู่ระบบด้วย Student ID
    func loginAsStudent(studentID: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        // 1. หา Email จาก StudentID ใน Firestore ก่อน
        db.collection("users").whereField("studentID", isEqualTo: studentID).getDocuments { (qs, err) in
            if err != nil { completion(false, "Failed to retrieve user data."); return }
            guard let doc = qs?.documents.first else { completion(false, "Invalid Student ID."); return }
            
            let data = doc.data()
            let email = data["email"] as? String ?? ""
            let name = data["name"] as? String ?? ""
            let role: UserRole = (data["role"] as? String ?? "student") == "admin" ? .admin : .student
            
            // 2. Login ด้วย Email/Password ผ่าน Firebase Auth
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
    
    
    // MARK: - 9. Legacy QueueApp (ระบบคิวแบบเดิม)
    // ส่วนนี้เป็นโค้ดเก่าสำหรับจัดการ Activity/Queue แบบเดิม (อาจจะไม่ได้ใช้ในระบบใหม่แล้ว แต่เก็บไว้ก่อน)
    
    func addActivity(name: String) {
        let new = Activity(name: name)
        activities.append(new)
        db.collection("activities").document(new.id.uuidString).setData([
            "name": new.name,
            "nextQueueNumber": new.nextQueueNumber,
            "currentQueueNumber": new.currentQueueNumber ?? NSNull(),
            "queueCount": new.queueCount
        ])
    }

    func loadActivities() {
        db.collection("activities").getDocuments { [weak self] (qs, _) in
            guard let self = self else { return }
            let loadedActivities = qs?.documents.compactMap { doc -> Activity? in
                guard let id = UUID(uuidString: doc.documentID) else { return nil }
                let d = doc.data()
                return Activity(
                    id: id,
                    name: d["name"] as? String ?? "",
                    nextQueueNumber: d["nextQueueNumber"] as? Int ?? 1,
                    currentQueueNumber: d["currentQueueNumber"] as? Int,
                    queueCount: d["queueCount"] as? Int ?? 0
                )
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
            "currentQueueNumber": activity.currentQueueNumber ?? NSNull(),
            "queueCount": activity.queueCount
        ])
    }

    func deleteActivity(activity: Activity) {
        db.collection("activities").document(activity.id.uuidString).delete()
    }

    func addQueueItem(activity: Activity, queueItem: QueueItem) {
        do {
            try db.collection("activities").document(activity.id.uuidString)
                .collection("queues").document(queueItem.id.uuidString)
                .setData(from: queueItem) { _ in
                    // 1. เพิ่มจำนวนคิวที่รอ
                    self.updateQueueCount(activity: activity, increment: true)
                    
                    // 2. อัปเดตเลขคิวถัดไป (Next Queue Number)
                    let newNextNumber = activity.nextQueueNumber + 1
                    self.db.collection("activities").document(activity.id.uuidString)
                        .updateData(["nextQueueNumber": newNextNumber]) { _ in
                            activity.nextQueueNumber = newNextNumber
                        }
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
                    try? doc.data(as: QueueItem.self)
                }.filter { $0.status == nil } ?? []
                completion(items)
            }
    }

    func updateQueueItemStatus(activity: Activity, queueItem: QueueItem, status: String) {
        db.collection("activities").document(activity.id.uuidString).collection("queues")
            .document(queueItem.id.uuidString)
            .updateData(["status": status]) { _ in
                
                // ถ้าสถานะเป็น "มาแล้ว" หรือ "ข้ามคิว" -> ลดจำนวนคนที่รอ
                if status == "มาแล้ว" || status == "ข้ามคิว" {
                    self.updateQueueCount(activity: activity, increment: false)
                    self.updateCurrentQueueNumber(activity: activity, queueItem: queueItem)
                }
                
                // ถ้าสถานะเป็น "ยกเลิกคิว"
                if status == "ยกเลิกคิว" {
                    self.updateQueueCount(activity: activity, increment: false)
                    
                    // เช็คว่าเป็นคิวล่าสุดหรือไม่? (ถ้าใช่ ให้ลด nextQueueNumber ลง เพื่อให้คนถัดไปได้เลขเดิม)
                    // Logic: ถ้า number ของคนที่ยกเลิก == nextQueueNumber - 1 แสดงว่าเป็นคนล่าสุด
                    if queueItem.number == activity.nextQueueNumber - 1 {
                        let newNextNumber = max(1, activity.nextQueueNumber - 1)
                        self.db.collection("activities").document(activity.id.uuidString)
                            .updateData(["nextQueueNumber": newNextNumber]) { _ in
                                activity.nextQueueNumber = newNextNumber
                            }
                    }
                }
            }
    }

    func deleteQueueItem(activity: Activity, queueItem: QueueItem) {
        db.collection("activities").document(activity.id.uuidString).collection("queues")
            .document(queueItem.id.uuidString).delete { _ in
                self.updateQueueCount(activity: activity, increment: false)
            }
    }

    func updateCurrentQueueNumber(activity: Activity, queueItem: QueueItem) {
        db.collection("activities").document(activity.id.uuidString)
            .updateData(["currentQueueNumber": queueItem.number]) { _ in
                activity.currentQueueNumber = queueItem.number
            }
    }

    func updateQueueCount(activity: Activity, increment: Bool) {
        let c = max(0, activity.queueCount + (increment ? 1 : -1))
        db.collection("activities").document(activity.id.uuidString)
            .updateData(["queueCount": c]) { _ in
                activity.queueCount = c
            }
    }

    func startListening(to activity: Activity) {
        guard activityListeners[activity.id] == nil else { return }
        activityListeners[activity.id] = db.collection("activities").document(activity.id.uuidString).collection("queues")
            .addSnapshotListener { [weak self] qs, _ in
                let items = qs?.documents.compactMap { doc -> QueueItem? in
                    try? doc.data(as: QueueItem.self)
                }.filter { $0.status == nil } ?? []
                
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
