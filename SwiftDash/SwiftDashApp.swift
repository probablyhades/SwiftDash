//
//  SwiftDashApp.swift
//  SwiftDash
//
//  Created by Harry Lewandowski on 27/9/2025.
//

import SwiftUI
import SwiftData

@main
struct SwiftDashApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Service.self,
            AppSettings.self,
            ServiceCategory.self,
        ])
       
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

