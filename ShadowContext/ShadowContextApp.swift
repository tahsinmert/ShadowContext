import SwiftUI

@main
struct ShadowContextApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We use Settings instead of WindowGroup to hide the main window on launch
        // in combination with LSUIElement = YES in Info.plist.
        Settings {
            EmptyView()
        }
    }
}
