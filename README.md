# Auto Screenshooter

A powerful macOS app for automating screenshot capture with advanced features.

## Features

- **Automated Screenshot Capture**: Set the number of screenshots to take automatically
- **Timed Intervals**: Configure wait time between screenshots (in milliseconds)
- **Custom Keypress Automation**: 
  - Click the keypress button to capture any key combination
  - Automatically simulate the captured keyboard shortcut between screenshots
  - Default: ⌘+] (commonly used for next tab/page)
- **Multiple Capture Modes**:
  - Entire Screen
  - Specific Window
  - Custom Area Selection
- **Hands-Free Operation**: 3-second countdown before capture starts

## Requirements

- macOS 13.0 or later
- Screen Recording permission (will be requested on first launch)
- Accessibility permission for keypress automation (optional, only if using auto-keypress)

## Building and Running

1. Make sure you have Xcode installed
2. Clone the repository
3. Build and run:

```bash
swift build
swift run
./make_app.sh # produce .app bundle
```

Or open in Xcode:
```bash
open Package.swift
```

## Usage

1. Launch Auto Screenshooter
2. Configure your settings:
   - Number of screenshots to take
   - Enable/disable automatic keypress (⌘+])
   - Set interval between screenshots
   - Choose save location
3. Select capture mode:
   - Click "Select screen" to choose a display or window
   - Click "Custom Area" to draw a selection rectangle
4. The app will show a 3-second countdown
5. Screenshots will be taken automatically and saved to your specified location

## Permissions

The app requires Screen Recording permission to function. You'll be prompted to grant this permission when you first run the app. To enable it manually:

1. Open System Preferences > Security & Privacy
2. Go to Privacy tab > Screen Recording
3. Check the box next to Auto Screenshooter

## File Naming

Screenshots are saved with the following format:
`Screenshot [Date] [Time] - [Index].png`

Example: `Screenshot 2024-01-15 3-45-30 PM - 1.png`
