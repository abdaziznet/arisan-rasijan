// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PeriodHistoryModelImpl _$$PeriodHistoryModelImplFromJson(
        Map<String, dynamic> json) =>
    _$PeriodHistoryModelImpl(
      periodId: json['periodId'] as String,
      periodNumber: (json['periodNumber'] as num).toInt(),
      hostId: json['hostId'] as String,
      hostName: json['hostName'] as String,
      winnerId: json['winnerId'] as String,
      winnerName: json['winnerName'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalCollected: (json['totalCollected'] as num).toDouble(),
    );

Map<String, dynamic> _$$PeriodHistoryModelImplToJson(
        _$PeriodHistoryModelImpl instance) =>
    <String, dynamic>{
      'periodId': instance.periodId,
      'periodNumber': instance.periodNumber,
      'hostId': instance.hostId,
      'hostName': instance.hostName,
      'winnerId': instance.winnerId,
      'winnerName': instance.winnerName,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'totalCollected': instance.totalCollected,
    };
