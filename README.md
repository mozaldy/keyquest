# KeyQuest 🎹

A single-screen iOS app for learning piano notes. Press keys on a virtual piano, hear sounds, and see notes appear on a grand staff in real time.

## Features

- **Grand Staff Rendering** — treble and bass clef with proper note placement, ledger lines, and accidentals
- **88-Key Piano** — mini overview strip showing all octaves; tap to switch the active octave
- **Realistic Piano Keys** — 3D styled keys with gradients, shadows, and press animations
- **Audio Playback** — SoundFont-based piano sounds via AudioKit
- **Page-Based Score** — 6 notes per page with smooth page-turn animation
- **State Restoration** — notes persist across app launches
- **Accessibility** — VoiceOver labels, Dynamic Type scaling, Reduce Motion support

## Architecture

```
KeyQuest/
├── App/                  # AppDelegate, SceneDelegate
├── Model/                # PitchClass, StaffNote, ScoreViewModel
├── Audio/                # NoteAudioEngine (AudioKit MIDISampler)
├── Views/                # StaffView (Core Graphics grand staff)
├── Controllers/          # MainViewController, KeyboardViewController
└── Resources/            # Piano.sf2 SoundFont
```

- **UIKit** app with `@main` AppDelegate lifecycle
- **SwiftUI** used only for the AudioKit `Keyboard` view (wrapped in `UIHostingController`)
- **Core Graphics** for all staff/note rendering via `UIView.draw(_:)`
- **Combine** for `ScoreViewModel` → `StaffView` data flow

## Requirements

- iOS 16.0+
- Xcode 15+
- Swift 5.9+

## Dependencies (SPM)

| Package | Purpose |
|---|---|
| [AudioKit](https://github.com/AudioKit/AudioKit) | Audio engine and MIDISampler |
| [Keyboard](https://github.com/AudioKit/Keyboard) | SwiftUI piano keyboard view |
| [Tonic](https://github.com/AudioKit/Tonic) | Music theory types (Pitch) |

## Setup

1. Open `KeyQuest.xcodeproj` in Xcode
2. Wait for SPM to resolve package dependencies
3. Add **Background Audio** capability: Target → Signing & Capabilities → + → Background Modes → ✓ Audio
4. Place a piano SoundFont at `KeyQuest/Resources/Piano.sf2` (one is included)
5. Build and run on a simulator or device

## License

MIT
