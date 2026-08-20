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
      periodId: json['periodId'] as String?,
      gatheringEventId: json['gatheringEventId'] as String?,
      description: json['description'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$FundLedgerModelImplToJson(
        _$FundLedgerModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'periodId': instance.periodId,
      'gatheringEventId': instance.gatheringEventId,
      'description': instance.description,
      'createdBy': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };
