# DA Music 🎵

A premium,  audio player application built with Flutter and Riverpod. Featuring beautiful design elements (vibrant fluid dark theme colors, seamless layouts) and a fully pluggable, decoupled music source and playback architecture.

## Core Highlights

- 🖥️ **Responsive Three-Panel App Shell**: Seamless fluid transition between Desktop, Tablet, and Mobile viewports without layout jank.
- 💿 **Signature Fullscreen Vinyl Player**: Morphing shared-element transitions that scale artwork and center rotating vinyl disc grooves.
- 🎛️ **Decoupled Playback Engine**: Centralized event-driven controller coordinating volume, mute, repeat, shuffle, and queues.
- 🔌 **Pluggable Music Source Adapters**: Pluggable source adapters allowing standard media fetches from YouTube Music, JioSaavn, SoundCloud, or Spotify.
- 🏃‍♂️ **Premium Motion Tokens**: Fully integrated animation durations, curves, and accessibility scaling handlers (Reduced Motion, Disabled Motion).
- 📦 **Windows Integration**: Frameless window client decorations, layout position persistence, and custom title bars.
- 📱 **Android Customizations**: Pill-shaped floating Mini Player overlay supporting horizontal drag gestures.
- 📂 **Local Library & Offline Mode**: Liked songs, playlists, recently played lists, statistics, and simulation downloaders.

## Getting Started

### Prerequisites

- Flutter SDK `^3.12.0`
- Dart SDK `^3.12.2`

### Installation & Run

1. Clone or copy this directory structure.
2. Initialize packages:
   ```bash
   flutter pub get
   ```
3. Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Launch the application:
   ```bash
   flutter run
   ```

## Testing

Run the test suite:
```bash
flutter test
```
