//
//  Persistence.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 10/11/2568 BE.
//

import CoreData

// MARK: - Core Data Persistence
// ตัวจัดการฐานข้อมูล Core Data (Local Database)
// หมายเหตุ: ในโปรเจกต์นี้หลักๆ ใช้ Firebase เป็น Backend, Core Data อาจจะถูกสร้างมาโดย Default ของ Xcode
// แต่อาจจะยังเก็บไว้ใช้สำหรับ Cache ข้อมูลบางอย่างในเครื่องได้
struct PersistenceController {
    // Singleton Instance สำหรับเรียกใช้ทั่วทั้งแอป
    static let shared = PersistenceController()

    // Preview Instance สำหรับใช้ใน SwiftUI Preview (ข้อมูลจำลองใน RAM)
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    // Container หลักของ Core Data
    let container: NSPersistentContainer

    // Init: โหลด Database
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "QueueApp_project")
        if inMemory {
            // ถ้าเป็น inMemory (เช่นตอน Test) ให้เขียนลง /dev/null แทนไฟล์จริง
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        // ให้ ViewContext อัปเดตอัตโนมัติเมื่อมีการเปลี่ยนแปลงจาก Parent
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
