//
//  BookingService.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol.
//

import Foundation
import FirebaseFirestore
import Combine

// MARK: - Booking Service
// Service สำหรับจัดการเรื่องการจองทั้งหมด (Booking System)
// ทำหน้าที่:
// 1. จัดการการจองส่วนตัว (Personal Booking) - สร้าง/ยกเลิก/ต่อเวลา
// 2. ฟังสถานะการจองแบบ Real-time (Listeners)
// 3. จัดการสถานะห้อง/โต๊ะ/เกม (Global Status)
// 4. จัดการหน้า Admin (Check-in, Finish, Skip Time)
class BookingService {
    private let db = Firestore.firestore()
    private var activeStatuses = ["Booked", "Queued", "In-Use"] // สถานะที่ยังใช้งานอยู่
    
    // MARK: - Personal Booking (Student)
    
    func listenForPersonalBooking(userID: String, completion: @escaping (AppState.Booking?, String?, Error?) -> Void) -> ListenerRegistration {
        return db.collection("bookings")
            .whereField("userID", isEqualTo: userID)
            .whereField("status", in: activeStatuses)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    completion(nil, nil, error)
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    // No active booking
                    completion(nil, nil, nil)
                    return
                }
                
                do {
                    let bookingData = try document.data(as: AppState.Booking.self)
                    completion(bookingData, document.documentID, nil)
                } catch {
                    completion(nil, nil, error)
                }
            }
    }
    
    func createReservation(userID: String, service: LibraryService, slotID: String, timeSlot: String?, items: [String]?) {
        let newBooking = AppState.Booking(
            userID: userID,
            serviceName: service.name,
            bookingType: "Reservation",
            status: "Booked",
            slotID: slotID,
            timeSlot: timeSlot,
            items: items,
            startTime: Timestamp(date: Date()),
            endTime: nil,
            extensionCount: 0
        )
        
        do {
            try db.collection("bookings").addDocument(from: newBooking)
        } catch {
            print("Error creating reservation: \(error)")
        }
    }
    
    func extendBooking(docID: String, currentEndTime: Date, currentExtensionCount: Int, completion: @escaping () -> Void) {
        let newEndTime = currentEndTime.addingTimeInterval(7200)
        
        db.collection("bookings").document(docID).updateData([
            "endTime": Timestamp(date: newEndTime),
            "extensionCount": currentExtensionCount + 1
        ]) { _ in
            completion()
        }
    }
    
    func cancelBooking(docID: String) {
        db.collection("bookings").document(docID).updateData(["status": "Cancelled"])
    }
    
    // MARK: - Global Status
    
    func listenToServiceBookings(service: String, timeSlot: String?, completion: @escaping ([String]) -> Void) -> ListenerRegistration {
        var query: Query = db.collection("bookings")
            .whereField("serviceName", isEqualTo: service)
            .whereField("status", in: activeStatuses)
        
        if let timeSlot = timeSlot {
            query = query.whereField("timeSlot", isEqualTo: timeSlot)
        }
        
        return query.addSnapshotListener { qs, _ in
            let slots = qs?.documents.compactMap { $0.data()["slotID"] as? String } ?? []
            completion(slots)
        }
    }
    
    func listenToBookedGames(completion: @escaping ([String]) -> Void) -> ListenerRegistration {
        return db.collection("bookings")
            .whereField("serviceName", isEqualTo: "Board Game")
            .whereField("status", isEqualTo: "In-Use")
            .addSnapshotListener { qs, _ in
                let items = qs?.documents.compactMap { $0.data()["items"] as? [String] }.flatMap { $0 } ?? []
                completion(items)
            }
    }
    
    // MARK: - Admin
    
    func listenToAdminBookings(completion: @escaping ([(String, AppState.Booking)]) -> Void) -> ListenerRegistration {
        return db.collection("bookings")
            .whereField("status", in: activeStatuses)
            .addSnapshotListener { qs, error in
                if let error = error {
                    print("Admin Error: \(error)")
                    return
                }
                
                let bookings = qs?.documents.compactMap { doc -> (String, AppState.Booking)? in
                    guard let booking = try? doc.data(as: AppState.Booking.self) else { return nil }
                    return (doc.documentID, booking)
                } ?? []
                
                completion(bookings)
            }
    }
    
    func checkInBooking(docID: String) {
        let now = Date()
        let endTime = now.addingTimeInterval(7200)
        
        db.collection("bookings").document(docID).updateData([
            "status": "In-Use",
            "startTime": Timestamp(date: now),
            "endTime": Timestamp(date: endTime)
        ])
    }
    
    func finishBooking(docID: String) {
        db.collection("bookings").document(docID).updateData(["status": "Finished"])
    }
    
    func adminSkipTime(docID: String) {
        let newEndTime = Date().addingTimeInterval(600)
        db.collection("bookings").document(docID).updateData([
            "endTime": Timestamp(date: newEndTime)
        ])
    }
}
