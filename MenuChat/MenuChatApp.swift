//
//  MenuChatApp.swift
//  MenuChat
//
//  Created by cricel on 2/21/26.
//

import SwiftUI

@main
struct MenuChatApp: App {
    var body: some Scene {
        MenuBarExtra("MenuChat", systemImage: "square.stack.3d.down.right.fill") {
            ChatMenuView()
        }
        .menuBarExtraStyle(.window)
    }
}
