# Changelog 📜

All notable changes to **DA Music** will be documented in this file.

## [1.0.0] - 2026-07-05

### Added
- **Sprint 0: Setup & Theme System**
  - Integrated GoRouter and Riverpod configurations.
  - Formulated custom `DAThemeExtension` with custom colors, spacings, radii, and typography.
- **Sprint 1: Three-Panel Desktop App Shell**
  - Created vertical Left Navigation Rail, center content panel, and right player column.
- **Sprint 2: Home Screen Visuals**
  - Staggered entrance animations.
  - Greeting header, lofi card grid, and horizontal recommended lists.
- **Sprint 3: Persistent Right Player Panel**
  - Modularized player panel: headers, rotatable vinyl artworks, progress sliders, and lyrics preview.
- **Sprint 4: Immersive Fullscreen Mode**
  - Morphing transitions from side panel to fullscreen.
  - Immersive blur backgrounds, timeline controls, and lyrics banners.
- **Sprint 5: Music Playback Engine**
  - Centralized `PlaybackController` and list `QueueManager`.
  - Event-driven streams with 60 FPS mock audio backend simulation.
- **Sprint 6: Pluggable Source Adapters**
  - Abstract `MusicSourceAdapter` and routing `SourceManager` with caching and retries.
  - Dynamic `YouTubeMusicAdapter` mock implementation.
- **Sprint 7: Premium Motion System**
  - Scale transition wrappers (`InteractiveScale`) and shimmer loaders (`ShimmerLoading`).
  - Accessibility providers (`motionScaleModeProvider`) scaling animations.
- **Sprint 8: Windows Native Features**
  - Frameless windows with client-side title bars and gesture dragging.
  - SharedPreferences window layout bounds persistence.
- **Sprint 9: Responsive Android Adaptations**
  - Breakpoint overlays for Desktop/Tablet/Phone viewports.
  - Swipe-enabled Mini Player card and fullscreen swipe-down gestures.
- **Sprint 10: Local Library Management**
  - Centralized `LibraryManager` supporting playlists, history tracking, favorites, and storage serializations.
  - State task `DownloadManager` simulator.
- **Sprint 11: Production Polish**
  - Centralized logs (`DALogger`) and complete Settings UI page.
