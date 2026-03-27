import SwiftUI

@Observable
class SpotifyController {
    var isPlaying = false
    var trackName = ""
    var artistName = ""
    var albumArt: NSImage?

    private var timer: Timer?
    private var lastArtworkURL = ""

    func startPolling() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.update()
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
    }

    func nextTrack() {
        runAppleScript("tell application \"Spotify\" to next track")
        // Small delay to let Spotify update its state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.update() }
    }

    func previousTrack() {
        runAppleScript("tell application \"Spotify\" to previous track")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.update() }
    }

    private func update() {
        let state = runAppleScript("tell application \"Spotify\" to player state as string") ?? ""
        isPlaying = (state == "playing")

        trackName = runAppleScript("tell application \"Spotify\" to name of current track") ?? ""
        artistName = runAppleScript("tell application \"Spotify\" to artist of current track") ?? ""

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
