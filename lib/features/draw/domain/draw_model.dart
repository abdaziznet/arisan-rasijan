import 'package:freezed_annotation/freezed_annotation.dart';

part 'draw_model.freezed.dart';
part 'draw_model.g.dart';

@freezed
class DrawModel with _$DrawModel {
  const factory DrawModel({
    required String id,
    required String periodId,
    required String winnerId,
    required DateTime createdAt,
    String? winnerName,
    double? totalCollected,
  }) = _DrawModel;

  factory DrawModel.fromJson(Map<String, dynamic> json) =>
      _$DrawModelFromJson(json);
}

class DrawHistoryModel {
  const DrawHistoryModel({
    required this.id,
    required this.periodId,
    required this.periodNumber,
    required this.winnerId,
    required this.winnerName,
    required this.createdAt,
  });

  factory DrawHistoryModel.fromJson(Map<String, dynamic> json) {
    final period = json['periods'] as Map<String, dynamic>;
    final winner = json['winner'] as Map<String, dynamic>;
    return DrawHistoryModel(
      id: json['id'] as String,
      periodId: json['period_id'] as String,
      periodNumber: period['period_number'] as int,
      winnerId: json['winner_id'] as String,
      winnerName: winner['full_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String periodId;
  final int periodNumber;
  final String winnerId;
  final String winnerName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'period_id': periodId,
        'period_number': periodNumber,
        'winner_id': winnerId,
        'winner_name': winnerName,
        'created_at': createdAt.toIso8601String(),
      };
}
