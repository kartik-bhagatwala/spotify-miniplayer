//
//  miniplayerApp.swift
//  miniplayer
//
//  Created by Kartik on 3/26/26.
//

import SwiftUI
import CoreData

@main
struct miniplayerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
