// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_ledger_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FundLedgerModelImpl _$$FundLedgerModelImplFromJson(
        Map<String, dynamic> json) =>
    _$FundLedgerModelImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      periodId: json['period_id'] as String?,
      gatheringEventId: json['gathering_event_id'] as String?,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$FundLedgerModelImplToJson(
        _$FundLedgerModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'period_id': instance.periodId,
      'gathering_event_id': instance.gatheringEventId,
      'description': instance.description,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
