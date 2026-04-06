# ShadowContext - Xcode Setup Guide

To get ShadowContext running, follow these steps to configure your Xcode project correctly:

## 1. Project Initialization
- Open Xcode and create a new **App** project for **macOS**.
- Name the project `ShadowContext`.
- Interface: **SwiftUI**, Language: **Swift**.
- Ensure you delete existing `ShadowContextApp.swift` and `ContentView.swift` (if created) or replace their contents with the code provided.

## 2. Hide Dock Icon (LSUIElement)
To make the app run strictly in the menu bar:
1. Select your project in the Sidebar.
2. Select the **ShadowContext** Target.
3. Click the **Info** tab.
4. Hover over any key and click the `+` icon.
5. Add the key: `Application is agent (UIElement)`.
6. Set its value to `YES`.

## 3. Global Shortcuts (Optional but Recommended)
I've implemented a basic `NSEvent.addGlobalMonitorForEvents` in `AppDelegate.swift`. For a more robust experience (e.g., custom shortcut recording), I recommend:
1. Go to **File** -> **Add Packages**.
2. Search for: `https://github.com/sindresorhus/KeyboardShortcuts`.
3. Add the package to your target.

## 4. Sandbox Permissions
Since we read local directories:
1. Select the **ShadowContext** Target.
2. Go to **Signing & Capabilities**.
3. Under **App Sandbox**, ensure **User Selected Files** is set to `Read/Write` (so we can read the projects you select via the folder picker).

## 5. Build and Run
- Hit `Cmd + R`.
- Look for the 🌙 (Moon) icon in your menu bar!
- Use `Cmd + Shift + Space` to trigger the context gathering globally.
