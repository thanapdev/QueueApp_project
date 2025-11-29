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
    
    // MARK: - Services
    private let authService = AuthService()
    private let bookingService = BookingService()
    private let queueService = QueueService()
    
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
    
    private var activityListeners: [UUID: ListenerRegistration] = [:] // Listener สำหรับคิวเดิม (แยกตาม Activity)
    private var activitiesListener: ListenerRegistration? // Listener สำหรับรายการกิจกรรมทั้งหมด
    
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

    // Data Model สำหรับ Booking (การจอง)
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
        var endTime: Timestamp?  // เวลาสิ้นสุด (สำหรับคำนวณ 2 ชม.) - เป็น Optional เพราะตอนจองอาจจะยังไม่กำหนดเวลาจบแน่นอน
        var extensionCount: Int? // จำนวนครั้งที่ต่อเวลา (เริ่มที่ 0)
        
        // Helper สำหรับแสดงผลรายละเอียดแบบรวมๆ
        var details: String {
            var parts = [String]()
            if let slotID = slotID { parts.append(slotID) }
            if let timeSlot = timeSlot { parts.append("@ \(timeSlot)") }
            if let items = items, !items.isEmpty { parts.append("(\(items.count) items)") }
            return parts.joined(separator: " ")
        }
    }
    
    // สถานะ Active (ยังไม่จบ)
    private var activeStatuses = ["Booked", "Queued", "In-Use"]

    
    // MARK: - 4. Personal Booking Logic (Student)
    // ฟังก์ชันจัดการการจองของฝั่งนิสิต
    
    // เช็คว่ามี Booking ค้างอยู่ไหม
    var hasActiveBooking: Bool {
        activeReservation != nil || activeQueue != nil
    }

    // Listener ส่วนตัว: ดักฟังการจองของตัวเองจาก Firestore
    // ทำงานแบบ Real-time: ถ้าสถานะใน Database เปลี่ยน หน้าจอก็จะเปลี่ยนตามทันที
    func listenForActiveBooking() {
        guard let userID = currentUser?.id else { return }
        
        // เคลียร์ Listener เก่าก่อนสร้างใหม่
        if personalBookingListener != nil { personalBookingListener?.remove() }
        
        print("Starting PERSONAL booking listener for user: \(userID)")
        
        personalBookingListener = bookingService.listenForPersonalBooking(userID: userID) { [weak self] booking, docID, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening for personal: \(error)")
                return
            }
            
            guard let booking = booking, let docID = docID else {
                // ไม่เจอเอกสาร = ไม่มีการจอง (หรือถูกยกเลิก/จบไปแล้ว)
                if self.activeReservation != nil || self.activeQueue != nil {
                    self.clearLocalBooking(fromListener: true)
                }
                return
            }
            
            DispatchQueue.main.async {
                // อัปเดต State
                self.activeReservation = (docID, booking)
                self.activeQueue = nil // ล้างค่าเก่า
                
                // เริ่มจับเวลา (Unified Timer) ถ้าสถานะเป็น In-Use
                self.startTimer(booking: booking)
            }
        }
    }
    
    // หยุดฟังการจอง (เช่น ตอน Logout)
    func stopListeningForBooking() {
        personalBookingListener?.remove()
        personalBookingListener = nil
        clearLocalBooking(fromListener: true)
    }

    // สร้าง Reservation ใหม่ (บันทึกลง Firestore)
    // สถานะเริ่มต้นจะเป็น "Booked" (รอ Admin Check-in ถึงจะเริ่มนับเวลา)
    func createReservation(service: LibraryService, slotID: String, timeSlot: String?, items: [String]?) {
        guard let userID = currentUser?.id else { return }
        bookingService.createReservation(userID: userID, service: service, slotID: slotID, timeSlot: timeSlot, items: items)
    }
    
    // (Legacy Wrapper) เรียกใช้ createReservation แทน
    func joinQueue(service: LibraryService, slotID: String, items: [String]?) {
        createReservation(service: service, slotID: slotID, timeSlot: nil, items: items)
    }

    // ต่อเวลา (+2 ชม.)
    func extendBooking() {
        guard let booking = activeReservation ?? activeQueue else { return }
        guard let currentEndTime = booking.data.endTime?.dateValue() else { return }
        
        bookingService.extendBooking(docID: booking.docID, currentEndTime: currentEndTime, currentExtensionCount: booking.data.extensionCount ?? 0) { [weak self] in
            DispatchQueue.main.async {
                self?.showExtendAlert = false
                print("Booking extended!")
            }
        }
    }

    // ยกเลิก/จบการจอง (เปลี่ยน Status เป็น Cancelled)
    func cancelActiveBooking(fromListener: Bool = false) {
        if fromListener {
            clearLocalBooking(fromListener: true)
            return
        }
        
        let docID = activeReservation?.docID ?? activeQueue?.docID
        guard let id = docID else {
            clearLocalBooking(fromListener: true)
            return
        }
        
        // อัปเดต Firestore -> Listener จะทำงานและเคลียร์หน้าจอให้เอง
        bookingService.cancelBooking(docID: id)
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
        
        currentServiceListener = bookingService.listenToServiceBookings(service: service, timeSlot: timeSlot) { [weak self] slots in
            DispatchQueue.main.async {
                self?.currentServiceBookedSlots = Set(slots)
            }
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
        bookedGamesListener = bookingService.listenToBookedGames { [weak self] items in
            DispatchQueue.main.async {
                self?.currentBookedGames = Set(items)
            }
        }
    }
    
    func stopListeningToBookedGames() {
        bookedGamesListener?.remove()
        bookedGamesListener = nil
        DispatchQueue.main.async { self.currentBookedGames = [] }
    }
    
    
    // MARK: - 6. Admin Logic
    // ฟังก์ชันสำหรับ Admin
    
    /// เริ่มฟังการเปลี่ยนแปลงของรายการจองทั้งหมดแบบ Real-time สำหรับ Admin
    /// ข้อมูลจะถูกเก็บใน `allAdminBookings` เพื่อให้ทุก View ที่ต้องการใช้ข้อมูลนี้ (เช่น AdminDashboardView, AdminBookingView)
    /// สามารถแสดงผลได้ทันทีและอัปเดตอย่างต่อเนื่อง
    /// Listener นี้จะทำงานตลอดเวลาที่ Admin ล็อกอินอยู่ เพื่อให้ข้อมูลบน Dashboard และหน้าจัดการต่างๆ เป็นปัจจุบันเสมอ
    func listenToAdminBookings() {
        // ตรวจสอบว่ามี Listener อยู่แล้วหรือไม่ เพื่อป้องกันการสร้าง Listener ซ้ำซ้อน
        guard adminListener == nil else {
            print("Admin listener already active. Skipping redundant start.")
            return
        }
        
        print("Starting Admin booking listener...")
        adminListener = bookingService.listenToAdminBookings { [weak self] bookings in
            DispatchQueue.main.async {
                self?.allAdminBookings = bookings
            }
        }
    }
    
    /// หยุดฟังการเปลี่ยนแปลงของรายการจองทั้งหมด และล้างข้อมูล `allAdminBookings`
    /// ควรเรียกใช้เมื่อ Admin ออกจากระบบ (Logout) เพื่อเคลียร์ State และประหยัดทรัพยากร
    func stopListeningToAdminBookings() {
        if adminListener != nil {
            print("Stopping Admin booking listener...")
            adminListener?.remove()
            adminListener = nil
            allAdminBookings = [] // ล้างข้อมูลเมื่อหยุดฟัง
        }
    }
    
    // Check-in: เปลี่ยนสถานะเป็น In-Use และเริ่มนับเวลา
    func checkInBooking(docID: String) {
        // Optimistic Update: อัปเดต UI ทันทีให้ดูเร็ว
        if let index = allAdminBookings.firstIndex(where: { $0.docID == docID }) {
            withAnimation { allAdminBookings[index].data.status = "In-Use" }
        }
        
        bookingService.checkInBooking(docID: docID)
    }
    
    // Finish: จบการใช้งาน (คืนของ/ออกจากห้อง)
    func finishBooking(docID: String) {
        if let index = allAdminBookings.firstIndex(where: { $0.docID == docID }) {
            withAnimation { allAdminBookings[index].data.status = "Finished" }
        }
        bookingService.finishBooking(docID: docID)
    }
    
    // Skip Time: (Debug/Admin Tool) ข้ามเวลาไปเหลือ 10 นาทีสุดท้าย
    func adminSkipTime(docID: String) {
        if let index = allAdminBookings.firstIndex(where: { $0.docID == docID }) {
            let newEndTime = Date().addingTimeInterval(600)
            withAnimation { allAdminBookings[index].data.endTime = Timestamp(date: newEndTime) }
        }
        bookingService.adminSkipTime(docID: docID)
    }

    
    // MARK: - 7. Unified Timer Logic
    // ระบบจับเวลาถอยหลัง
    
    // Timer ที่ฉลาดขึ้น (เริ่มนับเมื่อ In-Use เท่านั้น)
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
            stopListeningToActivities() // หยุดฟังกิจกรรมด้วย
        }
        authService.logout()
    }

    // สมัครสมาชิก
    func register(name: String, studentID: String, email: String, password: String, role: UserRole, completion: @escaping (Bool, String?) -> Void) {
        authService.register(name: name, studentID: studentID, email: email, password: password, role: role, completion: completion)
    }

    // เข้าสู่ระบบด้วย Student ID
    func loginAsStudent(studentID: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        authService.loginAsStudent(studentID: studentID, password: password) { [weak self] result in
            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.currentUser = user
                        self?.isLoggedIn = true
                        self?.isBrowsingAsGuest = false
                        self?.listenForActiveBooking()
                        // เริ่มฟังรายการกิจกรรมแบบ Real-time ตั้งแต่ Login
                        self?.listenToActivities()

                        // MARK: - อัปเดต Comment: เริ่ม Listener สำหรับ Admin Bookings ทันทีที่ Admin Login
                        // Logic นี้ทำให้ `appState.allAdminBookings` ได้รับการอัปเดตแบบ Real-time ตลอดเวลา
                        // ตั้งแต่ Admin เข้าสู่ระบบ ส่งผลให้ `AdminDashboardView` แสดงจำนวนการจองที่ถูกต้อง
                        // และ `AdminBookingView` แสดงข้อมูลทันทีโดยไม่มีอาการข้อมูลหายแว็บไป เนื่องจาก `AppState` เป็นผู้จัดการ Listener หลัก
                        if user.role == .admin {
                            self?.listenToAdminBookings()
                        }
                    }
                    completion(true, nil)
                }
            case .failure(let error):
                completion(false, error.localizedDescription)
            }
        }
    }
    
    
    // MARK: - 9. Legacy QueueApp (ระบบคิวแบบเดิม)
    // ส่วนนี้เป็นโค้ดเก่าสำหรับจัดการ Activity/Queue แบบเดิม (อาจจะไม่ได้ใช้ในระบบใหม่แล้ว แต่เก็บไว้ก่อน)
    
    func addActivity(name: String) {
        queueService.addActivity(name: name) { [weak self] newActivity in
            DispatchQueue.main.async {
                self?.activities.append(newActivity)
            }
        }
    }

    func loadActivities() {
        queueService.loadActivities { [weak self] loadedActivities in
            DispatchQueue.main.async {
                self?.activities = loadedActivities
            }
        }
    }
    
    /// ฟังการเปลี่ยนแปลงของรายการกิจกรรมแบบ Real-time
    /// ใช้สำหรับ StudentActivityListView เพื่อให้ queueCount อัปเดตทันที
    func listenToActivities() {
        // หยุดฟังเก่าก่อน (ถ้ามี)
        stopListeningToActivities()
        
        activitiesListener = queueService.listenToActivities { [weak self] loadedActivities in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // แทนที่จะแทนที่ array ทั้งหมด ให้อัปเดตค่าใน Activity object เดิม
                // เพื่อให้ SwiftUI ยังคง observe object เดิมอยู่
                
                for loadedActivity in loadedActivities {
                    if let existingIndex = self.activities.firstIndex(where: { $0.id == loadedActivity.id }) {
                        // อัปเดตค่าใน Activity object เดิม
                        let existing = self.activities[existingIndex]
                        existing.name = loadedActivity.name
                        existing.nextQueueNumber = loadedActivity.nextQueueNumber
                        existing.currentQueueNumber = loadedActivity.currentQueueNumber
                        existing.queueCount = loadedActivity.queueCount
                    } else {
                        // ถ้าเป็น Activity ใหม่ ให้เพิ่มเข้าไป
                        self.activities.append(loadedActivity)
                    }
                }
                
                // ลบ Activity ที่ไม่มีใน Firestore แล้ว
                // แก้ไขข้อผิดพลาด: ควรใช้ $0.id เพื่อเข้าถึง id ของแต่ละ Activity ใน array
                let loadedIDs = Set(loadedActivities.map { $0.id })
                self.activities.removeAll { !loadedIDs.contains($0.id) }
            }
        }
    }
    
    /// หยุดฟังการเปลี่ยนแปลงของรายการกิจกรรม
    func stopListeningToActivities() {
        activitiesListener?.remove()
        activitiesListener = nil
    }

    func updateActivity(activity: Activity) {
        queueService.updateActivity(activity: activity)
    }

    func deleteActivity(activity: Activity) {
        queueService.deleteActivity(activity: activity)
    }

    func addQueueItem(activity: Activity, queueItem: QueueItem) {
        queueService.addQueueItem(activity: activity, queueItem: queueItem) { newNextNumber in
            DispatchQueue.main.async {
                activity.nextQueueNumber = newNextNumber
            }
        }
    }

    func loadQueueItems(activity: Activity, completion: @escaping ([QueueItem]) -> Void) {
        queueService.loadQueueItems(activity: activity, completion: completion)
    }

    func updateQueueItemStatus(activity: Activity, queueItem: QueueItem, status: String) {
        queueService.updateQueueItemStatus(activity: activity, queueItem: queueItem, status: status) { newNextNumber in
            if let newNextNumber = newNextNumber {
                DispatchQueue.main.async {
                    activity.nextQueueNumber = newNextNumber
                }
            }
        }
    }

    func deleteQueueItem(activity: Activity, queueItem: QueueItem) {
        queueService.deleteQueueItem(activity: activity, queueItem: queueItem)
    }

    func updateCurrentQueueNumber(activity: Activity, queueItem: QueueItem) {
        // Note: This is internal to QueueService now, but if we need to update local state:
        // Ideally QueueService handles Firestore, and we rely on listeners to update UI.
        // But for now, let's assume QueueService handles it.
        // Wait, QueueService has `updateCurrentQueueNumber` as private helper.
        // If we need to expose it or if it's called from View...
        // It seems `updateCurrentQueueNumber` was called from `updateQueueItemStatus` internally in AppState.
        // So we might not need to call it explicitly from View.
    }

    func updateQueueCount(activity: Activity, increment: Bool) {
        // Similar to above, this is now handled internally in QueueService.
    }

    func startListening(to activity: Activity) {
        guard activityListeners[activity.id] == nil else { return }
        activityListeners[activity.id] = queueService.listenToQueueItems(activity: activity) { [weak self] items in
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
