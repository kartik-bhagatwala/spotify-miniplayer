import SwiftUI

struct ContentView: View {
    @State private var spotify = SpotifyController()
    @State private var showControls = false
    @State private var fadeTimer: Timer?
    @State private var trackingArea: NSTrackingArea?
    @AppStorage("showTrackInfo") private var showTrackInfo = true
    @State private var showTimeRemaining = true

    var body: some View {
        ZStack {
            if let art = spotify.albumArt {
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.black
            }

            // Overlay group — always present, controlled by opacity
            Group {
                Color.black.opacity(0.3)

                // Playback controls
                HStack(spacing: 30) {
                    Button { spotify.previousTrack(); resetFadeTimer() } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)

                    Button { spotify.togglePlayPause(); resetFadeTimer() } label: {
                        Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)

                    Button { spotify.nextTrack(); resetFadeTimer() } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)
                }

                // Track info (bottom)
                if showTrackInfo {
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                    }

                    VStack {
                        Spacer()

                        // Track seeker
                        HStack(spacing: 10) {
                            Text(formatTime(spotify.trackPosition))
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.8))
                                .monospacedDigit()
                            SeekerBar(spotify: spotify)
                                .frame(height: 12)
                            Text(showTimeRemaining ? "-\(formatTime(spotify.trackDuration - spotify.trackPosition))" : formatTime(spotify.trackDuration))
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.8))
                                .monospacedDigit()
                                .onTapGesture { showTimeRemaining.toggle() }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spotify.trackName)
                                    .font(.system(size: 16, weight: .bold))
                                Text(spotify.artistName)
                                    .font(.system(size: 12))
                                if spotify.albumName != spotify.trackName {
                                    Text(spotify.albumName)
                                        .font(.system(size: 10))
                                        .opacity(0.8)
                                }
                            }
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .shadow(radius: 4)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
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
            }
            .opacity(showControls ? 1 : 0)
            .allowsHitTesting(showControls)
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

        fadeTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            Task { @MainActor in
                withAnimation(.linear(duration: 3.0)) {
                    showControls = false
                }
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func hideControls() {
        fadeTimer?.invalidate()
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls = false
        }
    }
}

struct SeekerBar: View {
    var spotify: SpotifyController
    @State private var isHovered = false

    var body: some View {
        GeometryReader { geo in
            let progress = spotify.trackDuration > 0 ? spotify.trackPosition / spotify.trackDuration : 0
            let barHeight: CGFloat = isHovered ? 6 : 3
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(height: barHeight)
                Capsule()
                    .fill(.white)
                    .frame(width: geo.size.width * progress, height: barHeight)
                // Grab pill
                if isHovered {
                    Capsule()
                        .fill(.white)
                        .frame(width: 14, height: 10)
                        .shadow(radius: 2)
                        .offset(x: geo.size.width * progress - 8)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .overlay(SeekerDragView { fraction in
                let clamped = max(0, min(1, fraction))
                spotify.seek(to: clamped * spotify.trackDuration)
            })
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
    }
}

struct SeekerDragView: NSViewRepresentable {
    var onSeek: (Double) -> Void

    func makeNSView(context: Context) -> SeekerNSView {
        let view = SeekerNSView()
        view.onSeek = onSeek
        return view
    }

    func updateNSView(_ nsView: SeekerNSView, context: Context) {
        nsView.onSeek = onSeek
    }

    class SeekerNSView: NSView {
        var onSeek: ((Double) -> Void)?

        override var mouseDownCanMoveWindow: Bool { false }

        override func mouseDown(with event: NSEvent) {
            window?.isMovableByWindowBackground = false
            seek(with: event)
        }

        override func mouseDragged(with event: NSEvent) {
            seek(with: event)
        }

        override func mouseUp(with event: NSEvent) {
            window?.isMovableByWindowBackground = true
        }

        private func seek(with event: NSEvent) {
            let location = convert(event.locationInWindow, from: nil)
            let fraction = Double(location.x / bounds.width)
            onSeek?(fraction)
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
