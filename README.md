# ChatBar

> **ChatGPT in your menu bar.** Quick, Reword, and Reply—without leaving your desk.

[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![OpenAI API](https://img.shields.io/badge/OpenAI-GPT--5.2-green.svg)](https://platform.openai.com/)

A native macOS menu bar app that lets you talk to **GPT-5.2** or **GPT-5 Mini** in one click. No browser, no tab switching—just type, pick a mode, and get a response.

---

## ✨ Features

| Mode | What it does |
|------|----------------|
| **Quick** | Send any message as-is. Free-form chat. |
| **Reword** | Adds a `reword` prompt before your text so ChatGPT rewrites or polishes it. |
| **Reply** | Two fields: paste the content you’re replying to, then your main idea. ChatGPT drafts the reply for you. |

- Stays in the **menu bar** (no Dock icon)
- **API key** and **model** (GPT-5.2 / GPT-5 Mini) saved in the app
- **Copy response** to clipboard with one click
- Built with **SwiftUI** and the **OpenAI Chat Completions API**

---

## 📋 Requirements

- **macOS** 14.0+ (Sonoma or later)
- **Xcode** 15+ (or Swift 5.9+)
- An **OpenAI API key** ([create one here](https://platform.openai.com/api-keys))

---

## 🚀 Getting Started

### Build & Run

1. Clone the repo:
   ```bash
   git clone https://github.com/YOUR_USERNAME/MenuChat.git
   cd MenuChat
   ```
2. Open the project in Xcode:
   ```bash
   open MenuChat.xcodeproj
   ```
3. Select the **MenuChat** scheme and run (**⌘R**).
4. Look for the **MenuChat** icon in the menu bar and click it.

### First-time setup

1. Click the menu bar icon to open the panel.
2. Enter your **OpenAI API key** in the secure field (stored locally).
3. Choose **GPT-5.2** or **GPT-5 Mini** from the model menu.
4. Pick a mode (Quick / Reword / Reply), type your content, and hit **Send to ChatGPT**.

---

## 📁 Project Structure

```
MenuChat/
├── MenuChat/
│   ├── MenuChatApp.swift      # App entry, MenuBarExtra
│   ├── ChatMenuView.swift     # Main UI: modes, inputs, response
│   ├── ChatGPTService.swift   # OpenAI API client
│   └── MenuChat.entitlements   # Sandbox + network client
├── MenuChat.xcodeproj/
└── README.md
```

---

## 🔒 Privacy & Security

- Your **API key** is stored in the app’s UserDefaults (keychain-level storage is not used).
- Requests go directly to **OpenAI**; no intermediate servers.
- The app uses **App Sandbox** and only requests **outgoing network** access.

---

## 📄 License

This project is open source. Add your preferred license (e.g. MIT) and copyright notice here.

---

**Made with SwiftUI for macOS.**
