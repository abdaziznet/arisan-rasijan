import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_history_model.freezed.dart';
part 'period_history_model.g.dart';

@freezed
class PeriodHistoryModel with _$PeriodHistoryModel {
  const factory PeriodHistoryModel({
    required String periodId,
    required int periodNumber,
    required String hostId,
    required String hostName,
    required String winnerId,
    required String winnerName,
    required DateTime startDate,
    required DateTime endDate,
    required double totalCollected,
  }) = _PeriodHistoryModel;

  factory PeriodHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$PeriodHistoryModelFromJson(json);
}
