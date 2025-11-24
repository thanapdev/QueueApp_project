//
//  QueueService.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol.
//

import Foundation
import FirebaseFirestore

// MARK: - Queue Service (Legacy)
// Service สำหรับจัดการระบบคิวแบบเดิม (Legacy Queue System)
// ทำหน้าที่:
// 1. จัดการ Activities (กิจกรรม)
// 2. จัดการ Queue Items (รายการคิว)
// 3. อัปเดตสถานะคิว (มาแล้ว/ข้ามคิว/ยกเลิก)
// 4. ฟังการเปลี่ยนแปลงแบบ Real-time
class QueueService {
    private let db = Firestore.firestore()
    
    // MARK: - Activities (กิจกรรม)
    
    /// เพิ่มกิจกรรมใหม่
    func addActivity(name: String, completion: @escaping (Activity) -> Void) {
        let new = Activity(name: name)
        db.collection("activities").document(new.id.uuidString).setData([
            "name": new.name,
            "nextQueueNumber": new.nextQueueNumber,
            "currentQueueNumber": new.currentQueueNumber ?? NSNull(),
            "queueCount": new.queueCount
        ])
        completion(new)
    }
    
    /// โหลดรายการกิจกรรมทั้งหมด (แบบครั้งเดียว)
    func loadActivities(completion: @escaping ([Activity]) -> Void) {
        db.collection("activities").getDocuments { (qs, _) in
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
            completion(loadedActivities)
        }
    }
    
    /// ฟังการเปลี่ยนแปลงของรายการกิจกรรมแบบ Real-time
    /// - Parameter completion: Callback ที่จะถูกเรียกทุกครั้งที่มีการเปลี่ยนแปลง
    /// - Returns: ListenerRegistration สำหรับหยุดฟัง
    func listenToActivities(completion: @escaping ([Activity]) -> Void) -> ListenerRegistration {
        return db.collection("activities").addSnapshotListener { (qs, error) in
            if let error = error {
                print("Error listening to activities: \(error)")
                return
            }
            
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
            completion(loadedActivities)
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
    
    // MARK: - Queue Items
    
    func addQueueItem(activity: Activity, queueItem: QueueItem, completion: @escaping (Int) -> Void) {
        do {
            try db.collection("activities").document(activity.id.uuidString)
                .collection("queues").document(queueItem.id.uuidString)
                .setData(from: queueItem) { _ in
                    // 1. Update queue count
                    self.updateQueueCount(activity: activity, increment: true)
                    
                    // 2. Update next queue number
                    let newNextNumber = activity.nextQueueNumber + 1
                    self.db.collection("activities").document(activity.id.uuidString)
                        .updateData(["nextQueueNumber": newNextNumber]) { _ in
                            completion(newNextNumber)
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
    
    func updateQueueItemStatus(activity: Activity, queueItem: QueueItem, status: String, completion: @escaping (Int?) -> Void) {
        db.collection("activities").document(activity.id.uuidString).collection("queues")
            .document(queueItem.id.uuidString)
            .updateData(["status": status]) { _ in
                
                if status == "มาแล้ว" || status == "ข้ามคิว" {
                    self.updateQueueCount(activity: activity, increment: false)
                    self.updateCurrentQueueNumber(activity: activity, queueItem: queueItem)
                }
                
                if status == "ยกเลิกคิว" {
                    self.updateQueueCount(activity: activity, increment: false)
                    
                    // Logic: If cancelling the latest queue, decrement nextQueueNumber
                    if queueItem.number == activity.nextQueueNumber - 1 {
                        let newNextNumber = max(1, activity.nextQueueNumber - 1)
                        self.db.collection("activities").document(activity.id.uuidString)
                            .updateData(["nextQueueNumber": newNextNumber]) { _ in
                                completion(newNextNumber)
                            }
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
    }
    
    func deleteQueueItem(activity: Activity, queueItem: QueueItem) {
        db.collection("activities").document(activity.id.uuidString).collection("queues")
            .document(queueItem.id.uuidString).delete { _ in
                self.updateQueueCount(activity: activity, increment: false)
            }
    }
    
    func listenToQueueItems(activity: Activity, completion: @escaping ([QueueItem]) -> Void) -> ListenerRegistration {
        return db.collection("activities").document(activity.id.uuidString).collection("queues")
            .addSnapshotListener { qs, _ in
                let items = qs?.documents.compactMap { doc -> QueueItem? in
                    try? doc.data(as: QueueItem.self)
                }.filter { $0.status == nil } ?? []
                completion(items)
            }
    }
    
    // MARK: - Helpers
    
    private func updateCurrentQueueNumber(activity: Activity, queueItem: QueueItem) {
        db.collection("activities").document(activity.id.uuidString)
            .updateData(["currentQueueNumber": queueItem.number])
    }
    
    private func updateQueueCount(activity: Activity, increment: Bool) {
        let c = max(0, activity.queueCount + (increment ? 1 : -1))
        db.collection("activities").document(activity.id.uuidString)
            .updateData(["queueCount": c])
    }
}
