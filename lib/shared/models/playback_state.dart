import 'package:freezed_annotation/freezed_annotation.dart';

part 'playback_state.freezed.dart';
part 'playback_state.g.dart';

enum PlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  buffering,
  completed,
  error
}

@freezed
class PlaybackState with _$PlaybackState {
  const factory PlaybackState({
    required PlaybackStatus status,
    String? errorMessage,
    @Default(0.0) double bufferingProgress,
  }) = _PlaybackState;

  factory PlaybackState.fromJson(Map<String, dynamic> json) => _$PlaybackStateFromJson(json);
}
