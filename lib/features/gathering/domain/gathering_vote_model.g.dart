// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gathering_vote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GatheringVoteModelImpl _$$GatheringVoteModelImplFromJson(
        Map<String, dynamic> json) =>
    _$GatheringVoteModelImpl(
      id: json['id'] as String,
      gatheringEventId: json['gatheringEventId'] as String,
      optionId: json['optionId'] as String,
      memberId: json['memberId'] as String,
      votedAt: DateTime.parse(json['voted_at'] as String),
    );

Map<String, dynamic> _$$GatheringVoteModelImplToJson(
        _$GatheringVoteModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gatheringEventId': instance.gatheringEventId,
      'optionId': instance.optionId,
      'memberId': instance.memberId,
      'voted_at': instance.votedAt.toIso8601String(),
    };
