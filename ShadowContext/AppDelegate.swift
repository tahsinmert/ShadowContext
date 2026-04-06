import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    private var popover = NSPopover()
    private var botPanel: ShadowBotPanel?
    private var projectManager = ProjectManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the popover
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView())
        
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "ShadowContext")
            button.action = #selector(togglePopover(_:))
        }
        
        // Global Keyboard Shortcut Monitor (Command + Shift + Space)
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // ⌘(command) = 1 << 20, ⇧(shift) = 1 << 17
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if modifiers == [.command, .shift] && event.keyCode == 49 { // 49 is Space
                self?.triggerContextGather()
            }
        }
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem?.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.becomeKey()
            }
        }
    }
    
    @objc func toggleShadowBot(_ sender: Any?) {
        DispatchQueue.main.async {
            if let panel = self.botPanel {
                if panel.isVisible {
                    panel.orderOut(nil)
                } else {
                    panel.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            } else {
                // Lazy creation of Bot Panel
                let path = self.projectManager.recentProjects.first?.path ?? ""
                let botView = ShadowBotView(projectURL: URL(fileURLWithPath: path))
                let hostingView = NSHostingView(rootView: botView)
                let panel = ShadowBotPanel(contentView: hostingView)
                
                self.botPanel = panel
                panel.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    private func triggerContextGather() {
        // Since we're in a global monitor, we trigger the logic directly
        // In a real app with KeyboardShortcuts package, this is much cleaner.
        NotificationCenter.default.post(name: Notification.Name("TriggerContextGather"), object: nil)
        
        // Feedback
        NSApp.activate(ignoringOtherApps: true)
        
        // This is a simplified trigger. In a production app, we'd use a shared state.
        print("Global Shortcut Triggered!")
    }
}
