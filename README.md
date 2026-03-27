# Spotify Miniplayer

A minimal, borderless macOS miniplayer for Spotify. Shows borderless album art in a square window with playback controls that appear on hover.

![Untitled](https://github.com/user-attachments/assets/1a7c0c2e-8823-4a9e-bf46-4abbc22a36c7)

## Features

- Square, resizable, borderless window
- Borderless album art from the currently playing Spotify track
- Play/pause and skip controls
- Controls Spotify via AppleScript — no API keys needed

## Requirements

- macOS 15+
- Spotify desktop app

## Install

Download the latest `miniplayer.zip` from [Releases](../../releases), unzip, and drag to Applications.

On first launch, macOS will also ask to allow the app to control Spotify — click **OK**.

## Build from source

1. Clone the repo
2. Open `miniplayer.xcodeproj` in Xcode
3. Set your development team in Signing & Capabilities
4. Build & Run (Cmd+R)
