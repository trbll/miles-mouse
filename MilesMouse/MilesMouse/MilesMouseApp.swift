//
//  MilesMouseApp.swift
//  MilesMouse
//
//  Created by Bell, Tyler R on 4/23/26.
//

import SwiftUI

@main
struct MilesMouseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
