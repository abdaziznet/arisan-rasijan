// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PhotoModelImpl _$$PhotoModelImplFromJson(Map<String, dynamic> json) =>
    _$PhotoModelImpl(
      id: json['id'] as String,
      periodId: json['period_id'] as String,
      photoUrl: json['photo_url'] as String,
      uploadedBy: json['uploaded_by'] as String,
      uploadedAt: json['uploaded_at'] == null
          ? null
          : DateTime.parse(json['uploaded_at'] as String),
    );

Map<String, dynamic> _$$PhotoModelImplToJson(_$PhotoModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'period_id': instance.periodId,
      'photo_url': instance.photoUrl,
      'uploaded_by': instance.uploadedBy,
      'uploaded_at': instance.uploadedAt?.toIso8601String(),
    };
