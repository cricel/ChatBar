//
//  ChatBarApp.swift
//  ChatBar
//
//  Created by cricel on 2/21/26.
//

import SwiftUI

@main
struct ChatBarApp: App {
    var body: some Scene {
        MenuBarExtra("ChatBar", systemImage: "square.stack.3d.down.right.fill") {
            ChatMenuView()
        }
        .menuBarExtraStyle(.window)
    }
}
