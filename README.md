# ChatBar

A native macOS menu bar app for quick access to OpenAI models—without opening a browser.

[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-macOS%2026-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![OpenAI](https://img.shields.io/badge/OpenAI-Chat%20Completions-412991.svg)](https://platform.openai.com/)

---

## Overview

ChatBar lives in the menu bar and provides three focused workflows for drafting and refining text with GPT. Responses stream in real time. The panel uses macOS Liquid Glass controls and collapses back to the menu bar when closed—no Dock icon, no context switching.

## Features

| Mode | Description |
|------|-------------|
| **Quick** | Free-form prompts sent as-is |
| **Reword** | Rewrites or polishes pasted text |
| **Reply** | Drafts a reply from source content plus your intent |

Additional capabilities:

- Streaming responses from the OpenAI Chat Completions API
- Model selection: GPT-5.2 and GPT-5 Mini
- Local API key storage via Settings
- One-click copy of the response to the clipboard
- Cancel in-flight requests with Stop
- Menu bar–only presence (`LSUIElement`); Quit is available in Settings

## Requirements

- macOS 26.2 or later
- Xcode 26 or later
- An [OpenAI API key](https://platform.openai.com/api-keys)

## Getting Started

### Build and run

```bash
git clone https://github.com/cricel/ChatBar.git
cd ChatBar
open ChatBar.xcodeproj
```

Select the **ChatBar** scheme and run (**⌘R**). The ChatBar icon appears in the menu bar.

### First-time setup

1. Click the menu bar icon to open the panel.
2. Open **Settings** (gear) and enter your OpenAI API key.
3. Choose **GPT-5.2** or **GPT-5 Mini**.
4. Select a mode, enter your content, and press **Send**.

The close (✕) control dismisses the panel. To fully exit, open Settings and choose **Quit ChatBar**.

## Project Structure

```
ChatBar/
├── ChatBar/
│   ├── ChatBarApp.swift       # App entry and MenuBarExtra
│   ├── ChatMenuView.swift     # Panel UI, modes, streaming display
│   ├── ChatGPTService.swift   # OpenAI streaming client
│   ├── ChatBar.entitlements   # App Sandbox and network client
│   ├── Info.plist
│   └── Assets.xcassets
├── ChatBar.xcodeproj/
└── README.md
```

## Privacy

- The API key is stored locally in UserDefaults (not Keychain).
- Requests go directly to OpenAI; there is no intermediate server.
- The app runs under App Sandbox with outgoing network access only.

## License

License terms are not specified in this repository. Clarify licensing before redistributing.
