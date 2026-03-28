import SwiftUI

@main
struct miniplayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var alwaysOnTop = false
    @AppStorage("showTrackInfo") private var showTrackInfo = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowConfigurator())
        }
        .windowResizability(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(after: .toolbar) {
                Toggle("Always on Top", isOn: Binding(
                    get: { alwaysOnTop },
                    set: { newValue in
                        alwaysOnTop = newValue
                        NSApp.windows.forEach { window in
                            window.level = newValue ? .floating : .normal
                        }
                    }
                ))
                .keyboardShortcut("t", modifiers: [.command])

                Toggle("Show Track Info", isOn: $showTrackInfo)
                    .keyboardShortcut("i", modifiers: [.command])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidBecomeActive(_ notification: Notification) {
        NSApp.windows.forEach { window in
            window.makeKeyAndOrderFront(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.windows.forEach { window in
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        return true
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

        override func mouseDown(with event: NSEvent) {
            super.mouseDown(with: event)
            window?.makeKeyAndOrderFront(nil)
        }

        private func configureWindow() {
            guard let window, !isConfigured else { return }
            isConfigured = true
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
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func makeNSView(context: Context) -> WindowView {
        WindowView()
    }

    func updateNSView(_ nsView: WindowView, context: Context) {}
}
