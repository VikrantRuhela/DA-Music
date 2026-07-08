import '../../domain/entities/song.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/queue.dart';
import '../../domain/entities/repeat_mode.dart';
import '../../domain/entities/value_objects.dart';
import '../../shared/models/music_models.dart' as shared;

/// Abstract base event representing a typed application notification.
abstract class AppEvent {
  final DateTime timestamp;
  final String source;
  final String id;
  final int priority;

  AppEvent({
    required this.source,
    required this.id,
    this.priority = 0,
  }) : timestamp = DateTime.now();
}

// --- Playback Events ---

class PlaybackStarted extends AppEvent {
  final Song song;
  PlaybackStarted({required super.source, required this.song})
      : super(id: 'playback_started_${song.id}');
}

class PlaybackPaused extends AppEvent {
  PlaybackPaused({required super.source}) : super(id: 'playback_paused');
}

class PlaybackStopped extends AppEvent {
  PlaybackStopped({required super.source}) : super(id: 'playback_stopped');
}

class PlaybackResumed extends AppEvent {
  PlaybackResumed({required super.source}) : super(id: 'playback_resumed');
}

class SongChanged extends AppEvent {
  final Song? song;
  SongChanged({required super.source, this.song})
      : super(id: 'song_changed_${song?.id ?? "none"}');
}

class PositionChanged extends AppEvent {
  final Duration position;
  PositionChanged({required super.source, required this.position})
      : super(id: 'position_changed_${position.inSeconds}');
}

class DurationChanged extends AppEvent {
  final Duration duration;
  DurationChanged({required super.source, required this.duration})
      : super(id: 'duration_changed_${duration.inSeconds}');
}

class QueueChanged extends AppEvent {
  final Queue queue;
  QueueChanged({required super.source, required this.queue})
      : super(id: 'queue_changed');
}

class ShuffleChanged extends AppEvent {
  final bool shuffleEnabled;
  ShuffleChanged({required super.source, required this.shuffleEnabled})
      : super(id: 'shuffle_changed_$shuffleEnabled');
}

class RepeatChanged extends AppEvent {
  final RepeatMode repeatMode;
  RepeatChanged({required super.source, required this.repeatMode})
      : super(id: 'repeat_changed_${repeatMode.name}');
}

class VolumeChanged extends AppEvent {
  final double volume;
  VolumeChanged({required super.source, required this.volume})
      : super(id: 'volume_changed_$volume');
}

class PlaybackCompleted extends AppEvent {
  PlaybackCompleted({required super.source}) : super(id: 'playback_completed');
}

class PlaybackError extends AppEvent {
  final String errorMessage;
  PlaybackError({required super.source, required this.errorMessage})
      : super(id: 'playback_error');
}

// --- Library Events ---

class SongLiked extends AppEvent {
  final Song song;
  SongLiked({required super.source, required this.song})
      : super(id: 'song_liked_${song.id}');
}

class SongUnliked extends AppEvent {
  final String songId;
  SongUnliked({required super.source, required this.songId})
      : super(id: 'song_unliked_$songId');
}

class PlaylistCreated extends AppEvent {
  final Playlist playlist;
  PlaylistCreated({required super.source, required this.playlist})
      : super(id: 'playlist_created_${playlist.id}');
}

class PlaylistDeleted extends AppEvent {
  final String playlistId;
  PlaylistDeleted({required super.source, required this.playlistId})
      : super(id: 'playlist_deleted_$playlistId');
}

class PlaylistUpdated extends AppEvent {
  final Playlist playlist;
  PlaylistUpdated({required super.source, required this.playlist})
      : super(id: 'playlist_updated_${playlist.id}');
}

class LibraryUpdated extends AppEvent {
  LibraryUpdated({required super.source}) : super(id: 'library_updated');
}

class DownloadAdded extends AppEvent {
  final Song song;
  DownloadAdded({required super.source, required this.song})
      : super(id: 'download_added_${song.id}');
}

class DownloadRemoved extends AppEvent {
  final String songId;
  DownloadRemoved({required super.source, required this.songId})
      : super(id: 'download_removed_$songId');
}

class HistoryUpdated extends AppEvent {
  HistoryUpdated({required super.source}) : super(id: 'history_updated');
}

// --- Search Events ---

class SearchStarted extends AppEvent {
  final String query;
  SearchStarted({required super.source, required this.query})
      : super(id: 'search_started_$query');
}

class SearchCompleted extends AppEvent {
  final String query;
  SearchCompleted({required super.source, required this.query})
      : super(id: 'search_completed_$query');
}

class SearchCancelled extends AppEvent {
  SearchCancelled({required super.source}) : super(id: 'search_cancelled');
}

class SearchFailed extends AppEvent {
  final String query;
  final String error;
  SearchFailed({required super.source, required this.query, required this.error})
      : super(id: 'search_failed_$query');
}

class SuggestionsUpdated extends AppEvent {
  final List<String> suggestions;
  SuggestionsUpdated({required super.source, required this.suggestions})
      : super(id: 'suggestions_updated');
}

// --- Provider Events ---

class ProviderConnected extends AppEvent {
  final String providerId;
  ProviderConnected({required super.source, required this.providerId})
      : super(id: 'provider_connected_$providerId');
}

class ProviderDisconnected extends AppEvent {
  final String providerId;
  ProviderDisconnected({required super.source, required this.providerId})
      : super(id: 'provider_disconnected_$providerId');
}

class ProviderFailed extends AppEvent {
  final String providerId;
  final String error;
  ProviderFailed({required super.source, required this.providerId, required this.error})
      : super(id: 'provider_failed_$providerId');
}

class ProviderSwitched extends AppEvent {
  final String fromProviderId;
  final String toProviderId;
  ProviderSwitched({required super.source, required this.fromProviderId, required this.toProviderId})
      : super(id: 'provider_switched_$toProviderId');
}

// --- Theme Events ---

class AccentChanged extends AppEvent {
  final ThemeColor color;
  AccentChanged({required super.source, required this.color})
      : super(id: 'accent_changed_$color');
}

class ThemeChanged extends AppEvent {
  final bool isDark;
  ThemeChanged({required super.source, required this.isDark})
      : super(id: 'theme_changed_$isDark');
}

class WallpaperChanged extends AppEvent {
  final String wallpaperPath;
  WallpaperChanged({required super.source, required this.wallpaperPath})
      : super(id: 'wallpaper_changed');
}

class DynamicColorGenerated extends AppEvent {
  final ThemeColor color;
  DynamicColorGenerated({required super.source, required this.color})
      : super(id: 'dynamic_color_generated');
}

// --- Settings Events ---

class SettingsChanged extends AppEvent {
  final shared.PlayerSettings settings;
  SettingsChanged({required super.source, required this.settings})
      : super(id: 'settings_changed');
}

class AnimationSpeedChanged extends AppEvent {
  final double speed;
  AnimationSpeedChanged({required super.source, required this.speed})
      : super(id: 'animation_speed_changed_$speed');
}

class ReduceMotionChanged extends AppEvent {
  final bool reduceMotion;
  ReduceMotionChanged({required super.source, required this.reduceMotion})
      : super(id: 'reduce_motion_changed_$reduceMotion');
}

class LanguageChanged extends AppEvent {
  final String language;
  LanguageChanged({required super.source, required this.language})
      : super(id: 'language_changed_$language');
}

// --- Lifecycle Events ---

class AppStarted extends AppEvent {
  AppStarted({required super.source}) : super(id: 'app_started');
}

class AppPaused extends AppEvent {
  AppPaused({required super.source}) : super(id: 'app_paused');
}

class AppResumed extends AppEvent {
  AppResumed({required super.source}) : super(id: 'app_resumed');
}

class AppClosed extends AppEvent {
  AppClosed({required super.source}) : super(id: 'app_closed');
}

class WindowFocused extends AppEvent {
  WindowFocused({required super.source}) : super(id: 'window_focused');
}

class WindowBlurred extends AppEvent {
  WindowBlurred({required super.source}) : super(id: 'window_blurred');
}
