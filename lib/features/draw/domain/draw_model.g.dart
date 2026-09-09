// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draw_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DrawModelImpl _$$DrawModelImplFromJson(Map<String, dynamic> json) =>
    _$DrawModelImpl(
      id: json['id'] as String,
      periodId: json['periodId'] as String,
      winnerId: json['winnerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      winnerName: json['winnerName'] as String?,
      totalCollected: (json['totalCollected'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$DrawModelImplToJson(_$DrawModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'periodId': instance.periodId,
      'winnerId': instance.winnerId,
      'createdAt': instance.createdAt.toIso8601String(),
      'winnerName': instance.winnerName,
      'totalCollected': instance.totalCollected,
    };
