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
      winningOptionId: json['winningOptionId'] as String?,
      eventDate: json['eventDate'] == null
          ? null
          : DateTime.parse(json['eventDate'] as String),
      fundUsed: (json['fundUsed'] as num?)?.toDouble() ?? 0,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
    );

Map<String, dynamic> _$$GatheringEventModelImplToJson(
        _$GatheringEventModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': instance.status,
      'winningOptionId': instance.winningOptionId,
      'eventDate': instance.eventDate?.toIso8601String(),
      'fundUsed': instance.fundUsed,
      'createdBy': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'closedAt': instance.closedAt?.toIso8601String(),
    };
