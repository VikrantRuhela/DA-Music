// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlaybackStateImpl _$$PlaybackStateImplFromJson(Map<String, dynamic> json) =>
    _$PlaybackStateImpl(
      status: $enumDecode(_$PlaybackStatusEnumMap, json['status']),
      errorMessage: json['errorMessage'] as String?,
      bufferingProgress: (json['bufferingProgress'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$PlaybackStateImplToJson(_$PlaybackStateImpl instance) =>
    <String, dynamic>{
      'status': _$PlaybackStatusEnumMap[instance.status]!,
      'errorMessage': instance.errorMessage,
      'bufferingProgress': instance.bufferingProgress,
    };

const _$PlaybackStatusEnumMap = {
  PlaybackStatus.idle: 'idle',
  PlaybackStatus.loading: 'loading',
  PlaybackStatus.playing: 'playing',
  PlaybackStatus.paused: 'paused',
  PlaybackStatus.buffering: 'buffering',
  PlaybackStatus.completed: 'completed',
  PlaybackStatus.error: 'error',
};
