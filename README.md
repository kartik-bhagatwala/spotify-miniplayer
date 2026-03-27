# Spotify Miniplayer

A minimal, borderless macOS miniplayer for Spotify. Shows album art full-bleed in a square window with playback controls that appear on hover.

## Features

- Square, resizable, borderless window
- Full-bleed album art from the currently playing Spotify track
- Play/pause and skip controls appear on hover, fade after 2 seconds
- Native traffic light buttons (close/minimize) overlaid on artwork
- Controls Spotify via AppleScript — no API keys needed

## Requirements

- macOS 15+
- Spotify desktop app

## Install

Download the latest `.app` from [Releases](../../releases), unzip, and drag to Applications.

On first launch, macOS will ask to allow the app to control Spotify — click **OK**.

## Build from source

1. Clone the repo
2. Open `miniplayer.xcodeproj` in Xcode
3. Set your development team in Signing & Capabilities
4. Build & Run (Cmd+R)
