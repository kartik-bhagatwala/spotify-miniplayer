import SwiftUI

@Observable
class SpotifyController {
    var isPlaying = false
    var trackName = ""
    var artistName = ""
    var albumName = ""
    var albumArt: NSImage?
    var trackPosition: Double = 0
    var trackDuration: Double = 1

    private var timer: Timer?
    private var lastArtworkURL = ""
    private var suppressPollUntil: Date = .distantPast

    func startPolling() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, Date() >= self.suppressPollUntil else { return }
                self.update()
            }
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func togglePlayPause() {
        runAppleScript("tell application \"Spotify\" to playpause")
        isPlaying.toggle()
        suppressPollUntil = Date().addingTimeInterval(1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.update() }
    }

    func nextTrack() {
        runAppleScript("tell application \"Spotify\" to next track")
        suppressPollUntil = Date().addingTimeInterval(1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.update() }
    }

    func seek(to position: Double) {
        runAppleScript("tell application \"Spotify\" to set player position to \(position)")
        trackPosition = position
    }

    func previousTrack() {
        runAppleScript("tell application \"Spotify\" to previous track")
        suppressPollUntil = Date().addingTimeInterval(1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.update() }
    }

    private var spotifyIsRunning: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.spotify.client" }
    }

    private func update() {
        guard spotifyIsRunning else {
            isPlaying = false
            trackName = ""
            artistName = ""
            albumName = ""
            trackPosition = 0
            trackDuration = 1
            albumArt = nil
            lastArtworkURL = ""
            return
        }

        let state = runAppleScript("tell application \"Spotify\" to player state as string") ?? ""
        isPlaying = (state == "playing")

        trackName = runAppleScript("tell application \"Spotify\" to name of current track") ?? ""
        artistName = runAppleScript("tell application \"Spotify\" to artist of current track") ?? ""
        albumName = runAppleScript("tell application \"Spotify\" to album of current track") ?? ""
        trackPosition = Double(runAppleScript("tell application \"Spotify\" to player position") ?? "0") ?? 0
        trackDuration = Double(runAppleScript("tell application \"Spotify\" to duration of current track as string") ?? "1") ?? 1
        // Spotify returns duration in milliseconds
        trackDuration = trackDuration / 1000.0

        let artURL = runAppleScript("tell application \"Spotify\" to artwork url of current track") ?? ""
        if !artURL.isEmpty && artURL != lastArtworkURL {
            lastArtworkURL = artURL
            loadArtwork(from: artURL)
        }
    }

    private func loadArtwork(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        Task.detached {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = NSImage(data: data) else { return }
            await MainActor.run {
                self.albumArt = image
            }
        }
    }

    @discardableResult
    private func runAppleScript(_ source: String) -> String? {
        let script = NSAppleScript(source: source)
        var error: NSDictionary?
        let result = script?.executeAndReturnError(&error)
        return result?.stringValue
    }
}
