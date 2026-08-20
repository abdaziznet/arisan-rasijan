import '../../members/domain/member_model.dart';

class PeriodModel {
  const PeriodModel({
    required this.id,
    required this.periodNumber,
    required this.eventDate,
    this.hostId,
    this.hostAddress,
    this.contributionAmount,
    this.status = 'upcoming',
    this.winnerId,
    this.totalCollected,
    this.createdAt,
    this.host,
    this.winner,
  });

  final String id;
  final int periodNumber;
  final DateTime eventDate;
  final String? hostId;
  final String? hostAddress;
  final double? contributionAmount;
  final String status;
  final String? winnerId;
  final double? totalCollected;
  final DateTime? createdAt;
  final MemberModel? host;
  final MemberModel? winner;

  factory PeriodModel.fromJson(Map<String, dynamic> json) {
    return PeriodModel(
      id: json['id'] as String,
      periodNumber: (json['period_number'] as num).toInt(),
      eventDate: DateTime.parse(json['event_date'] as String),
      hostId: json['host_id'] as String?,
      hostAddress: json['host_address'] as String?,
      contributionAmount: json['contribution_amount'] != null
          ? (json['contribution_amount'] as num).toDouble()
          : null,
      status: (json['status'] as String?) ?? 'upcoming',
      winnerId: json['winner_id'] as String?,
      totalCollected: json['total_collected'] != null
          ? (json['total_collected'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      host: json['host'] != null
          ? MemberModel.fromJson(json['host'] as Map<String, dynamic>)
          : null,
      winner: json['winner'] != null
          ? MemberModel.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period_number': periodNumber,
      'event_date': eventDate.toIso8601String().split('T').first,
      if (hostId != null) 'host_id': hostId,
      if (hostAddress != null) 'host_address': hostAddress,
      if (contributionAmount != null)
        'contribution_amount': contributionAmount,
      'status': status,
      if (winnerId != null) 'winner_id': winnerId,
      if (totalCollected != null) 'total_collected': totalCollected,
    };
  }

  PeriodModel copyWith({
    String? id,
    int? periodNumber,
    DateTime? eventDate,
    String? hostId,
    String? hostAddress,
    double? contributionAmount,
    String? status,
    String? winnerId,
    double? totalCollected,
    DateTime? createdAt,
    MemberModel? host,
    MemberModel? winner,
  }) {
    return PeriodModel(
      id: id ?? this.id,
      periodNumber: periodNumber ?? this.periodNumber,
      eventDate: eventDate ?? this.eventDate,
      hostId: hostId ?? this.hostId,
      hostAddress: hostAddress ?? this.hostAddress,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      totalCollected: totalCollected ?? this.totalCollected,
      createdAt: createdAt ?? this.createdAt,
      host: host ?? this.host,
      winner: winner ?? this.winner,
    );
  }
}
