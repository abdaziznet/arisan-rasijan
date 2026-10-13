// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gathering_poll_option_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GatheringPollOptionModelImpl _$$GatheringPollOptionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$GatheringPollOptionModelImpl(
      id: json['id'] as String,
      gatheringEventId: json['gathering_event_id'] as String,
      optionLabel: json['option_label'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$GatheringPollOptionModelImplToJson(
        _$GatheringPollOptionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gathering_event_id': instance.gatheringEventId,
      'option_label': instance.optionLabel,
      'created_at': instance.createdAt.toIso8601String(),
    };
