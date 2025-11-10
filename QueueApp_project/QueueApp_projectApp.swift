//
//  QueueApp_projectApp.swift
//  QueueApp_project
//
//  Created by Thanapong Yamkamol on 10/11/2568 BE.
//

import SwiftUI

@main
struct QueueApp_projectApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
