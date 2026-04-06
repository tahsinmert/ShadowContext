import AppKit
import AudioToolbox

class PasteboardManager {
    static let shared = PasteboardManager()

    func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Success Haptics or Sound
        AudioServicesPlaySystemSound(1054) // Subtile Pop sound
        
        // Optional: Post notification
        let notification = NSUserNotification()
        notification.title = "ShadowContext"
        notification.informativeText = "Context copied to clipboard!"
        NSUserNotificationCenter.default.deliver(notification)
    }
}
