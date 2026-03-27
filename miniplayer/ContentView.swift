import SwiftUI

struct ContentView: View {
    @State private var spotify = SpotifyController()
    @State private var showControls = false
    @State private var fadeTimer: Timer?
    @State private var trackingArea: NSTrackingArea?

    var body: some View {
        ZStack {
            if let art = spotify.albumArt {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.black
            }

            if showControls {
                Color.black.opacity(0.3)

                // Playback controls
                HStack(spacing: 30) {
                    Button(action: spotify.previousTrack) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)

                    Button(action: spotify.togglePlayPause) {
                        Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)

                    Button(action: spotify.nextTrack) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)
                }

                // Window buttons (top-left)
                VStack {
                    HStack(spacing: 8) {
                        WindowButton(color: .red, symbol: "xmark") {
                            NSApp.windows.first?.close()
                        }
                        WindowButton(color: .yellow, symbol: "minus") {
                            NSApp.windows.first?.miniaturize(nil)
                        }
                        Spacer()
                    }
                    .padding(12)
                    Spacer()
                }

                .transition(.opacity)
            }
        }
        .frame(minWidth: 200, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(MouseTracker(onMouseMoved: { resetFadeTimer() }, onMouseExited: { hideControls() }).allowsHitTesting(false))
        .onAppear { spotify.startPolling() }
        .onDisappear { spotify.stopPolling() }
    }

    private func resetFadeTimer() {
        fadeTimer?.invalidate()
        if !showControls {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls = true
            }
        }

        fadeTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    showControls = false
                }
            }
        }
    }

    private func hideControls() {
        fadeTimer?.invalidate()
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls = false
        }
    }
}

struct WindowButton: View {
    let color: Color
    let symbol: String
    let action: () -> Void
    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        ZStack {
            Circle()
                .fill(isPressed ? color.opacity(0.6) : color)
                .frame(width: 12, height: 12)
            if isHovered {
                Image(systemName: symbol)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.black.opacity(0.5))
            }
        }
        .shadow(radius: 0.5)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    action()
                }
        )
    }
}

struct MouseTracker: NSViewRepresentable {
    var onMouseMoved: () -> Void
    var onMouseExited: () -> Void

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.onMouseMoved = onMouseMoved
        view.onMouseExited = onMouseExited
        return view
    }

    func updateNSView(_ nsView: TrackingView, context: Context) {
        nsView.onMouseMoved = onMouseMoved
        nsView.onMouseExited = onMouseExited
    }

    class TrackingView: NSView {
        var onMouseMoved: (() -> Void)?
        var onMouseExited: (() -> Void)?

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach { removeTrackingArea($0) }
            addTrackingArea(NSTrackingArea(
                rect: bounds,
                options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways],
                owner: self
            ))
        }

        override func mouseMoved(with event: NSEvent) {
            onMouseMoved?()
        }

        override func mouseEntered(with event: NSEvent) {
            onMouseMoved?()
        }

        override func mouseExited(with event: NSEvent) {
            onMouseExited?()
        }
    }
}
