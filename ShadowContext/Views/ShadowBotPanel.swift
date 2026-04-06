import AppKit
import SwiftUI

class ShadowBotPanel: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 500),
            styleMask: [.nonactivatingPanel, .titled, .resizable, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .statusBar
        self.isReleasedWhenClosed = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        
        self.contentView = contentView
        
        // Center on screen initially
        if let screen = NSScreen.main {
            let rect = screen.visibleFrame
            let x = rect.maxX - 400
            let y = rect.maxY - 550
            self.setFrame(NSRect(x: x, y: y, width: 350, height: 500), display: true)
        }
    }
    
    override var canBecomeKey: Bool {
        return true
    }
}
