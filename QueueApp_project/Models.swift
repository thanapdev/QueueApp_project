//
//  Models.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 11/11/2568 BE.
//

import Foundation

enum UserRole {
    case organization
    case student
}

struct Activity: Identifiable {
    let id = UUID()
    var name: String
    var queues: [QueueItem] = []
    var nextQueueNumber = 1
}

struct QueueItem: Identifiable {
    let id = UUID()
    let studentId: String
    let studentName: String
    let number: Int
}
