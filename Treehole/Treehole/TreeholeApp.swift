//
//  TreeholeApp.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

@main
struct TreeholeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Request notification permissions on app launch
                    NotificationManager.shared.requestAuthorization()
                }
        }
    }
}
