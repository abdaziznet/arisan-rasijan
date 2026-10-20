import 'package:freezed_annotation/freezed_annotation.dart';

part 'draw_model.freezed.dart';

@freezed
class DrawModel with _$DrawModel {
  const factory DrawModel({
    required String id,
    @JsonKey(name: 'period_id') required String periodId,
    @JsonKey(name: 'winner_id') required String winnerId,
    @JsonKey(name: 'conducted_at') required DateTime createdAt,
    @JsonKey(name: 'winner_name') String? winnerName,
    @JsonKey(name: 'total_collected') double? totalCollected,
  }) = _DrawModel;

  factory DrawModel.fromJson(Map<String, dynamic> json) {
    final rawPeriodId = json['period_id'] ?? json['periodId'];
    final rawWinnerId = json['winner_id'] ?? json['winnerId'];
    final rawWinnerName = json['winner_name'] ?? json['winnerName'];
    final rawCreatedAt =
        json['conducted_at'] ?? json['created_at'] ?? json['createdAt'];
    final rawTotalCollected = json['total_collected'] ?? json['totalCollected'];

    return DrawModel(
      id: json['id'] as String? ?? '',
      periodId: rawPeriodId as String? ?? '',
      winnerId: rawWinnerId as String? ?? '',
      createdAt: rawCreatedAt is String
          ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now()
          : DateTime.now(),
      winnerName: rawWinnerName as String?,
      totalCollected: rawTotalCollected == null
          ? null
          : (rawTotalCollected as num).toDouble(),
    );
  }
}

class DrawHistoryModel {
  const DrawHistoryModel({
    required this.id,
    required this.periodId,
    required this.periodNumber,
    required this.winnerId,
    required this.winnerName,
    required this.createdAt,
    this.drawMethod = 'random',
  });

  factory DrawHistoryModel.fromJson(Map<String, dynamic> json) {
    final period =
        (json['arisan_periods'] ?? json['periods']) as Map<String, dynamic>;
    final winner = json['winner'] as Map<String, dynamic>;
    final rawCreatedAt = json['conducted_at'] ?? json['created_at'];
    return DrawHistoryModel(
      id: json['id'] as String,
      periodId: json['period_id'] as String,
      periodNumber: period['period_number'] as int,
      winnerId: json['winner_id'] as String,
      winnerName: winner['full_name'] as String,
      createdAt: DateTime.parse(rawCreatedAt as String),
      drawMethod: json['draw_method'] as String? ?? 'random',
    );
  }

  final String id;
  final String periodId;
  final int periodNumber;
  final String winnerId;
  final String winnerName;
  final DateTime createdAt;
  final String drawMethod;

  Map<String, dynamic> toJson() => {
        'id': id,
        'period_id': periodId,
        'period_number': periodNumber,
        'winner_id': winnerId,
        'winner_name': winnerName,
        'created_at': createdAt.toIso8601String(),
        'draw_method': drawMethod,
      };
}
