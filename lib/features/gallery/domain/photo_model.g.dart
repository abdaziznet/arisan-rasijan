// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PhotoModelImpl _$$PhotoModelImplFromJson(Map<String, dynamic> json) =>
    _$PhotoModelImpl(
      id: json['id'] as String,
      periodId: json['periodId'] as String,
      photoUrl: json['photoUrl'] as String,
      uploadedBy: json['uploadedBy'] as String,
      uploadedAt: json['uploaded_at'] == null
          ? null
          : DateTime.parse(json['uploaded_at'] as String),
    );

Map<String, dynamic> _$$PhotoModelImplToJson(_$PhotoModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'periodId': instance.periodId,
      'photoUrl': instance.photoUrl,
      'uploadedBy': instance.uploadedBy,
      'uploaded_at': instance.uploadedAt?.toIso8601String(),
    };
