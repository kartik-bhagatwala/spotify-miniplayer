import SwiftUI

@main
struct miniplayerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowConfigurator())
        }
        .windowResizability(.automatic)
    }
}

struct WindowConfigurator: NSViewRepresentable {
    class WindowView: NSView {
        private var isConfigured = false

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            configureWindow()
        }

        override func layout() {
            super.layout()
            window?.contentAspectRatio = NSSize(width: 1, height: 1)
        }

        private func configureWindow() {
            guard let window, !isConfigured else { return }
            isConfigured = true
            // Remove title bar entirely, keep resizable
            window.styleMask = [.borderless, .resizable, .miniaturizable]
            window.isMovableByWindowBackground = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.cornerRadius = 10
            window.contentView?.layer?.masksToBounds = true
            window.contentAspectRatio = NSSize(width: 1, height: 1)
            window.contentMinSize = NSSize(width: 200, height: 200)
            window.setContentSize(NSSize(width: 300, height: 300))
        }
    }

    func makeNSView(context: Context) -> WindowView {
        WindowView()
    }

    func updateNSView(_ nsView: WindowView, context: Context) {}
}
