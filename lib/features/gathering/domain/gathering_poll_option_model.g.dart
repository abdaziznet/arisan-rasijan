// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gathering_poll_option_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GatheringPollOptionModelImpl _$$GatheringPollOptionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$GatheringPollOptionModelImpl(
      id: json['id'] as String,
      gatheringEventId: json['gatheringEventId'] as String,
      optionLabel: json['optionLabel'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      voteCount: (json['voteCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$GatheringPollOptionModelImplToJson(
        _$GatheringPollOptionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gatheringEventId': instance.gatheringEventId,
      'optionLabel': instance.optionLabel,
      'created_at': instance.createdAt.toIso8601String(),
      'voteCount': instance.voteCount,
    };
