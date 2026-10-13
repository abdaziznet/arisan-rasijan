// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gathering_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GatheringEventModelImpl _$$GatheringEventModelImplFromJson(
        Map<String, dynamic> json) =>
    _$GatheringEventModelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] as String? ?? 'voting',
      winningOptionId: json['winning_option_id'] as String?,
      eventDate: json['event_date'] == null
          ? null
          : DateTime.parse(json['event_date'] as String),
      fundUsed: (json['fund_used'] as num?)?.toDouble() ?? 0,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      closedAt: json['closed_at'] == null
          ? null
          : DateTime.parse(json['closed_at'] as String),
    );

Map<String, dynamic> _$$GatheringEventModelImplToJson(
        _$GatheringEventModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': instance.status,
      'winning_option_id': instance.winningOptionId,
      'event_date': instance.eventDate?.toIso8601String(),
      'fund_used': instance.fundUsed,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'closed_at': instance.closedAt?.toIso8601String(),
    };
