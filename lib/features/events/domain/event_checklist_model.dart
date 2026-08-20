class EventChecklistModel {
  const EventChecklistModel({
    required this.id,
    required this.periodId,
    required this.stepName,
    required this.stepOrder,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String periodId;
  final String stepName;
  final int stepOrder;
  final bool isCompleted;
  final DateTime? completedAt;

  factory EventChecklistModel.fromJson(Map<String, dynamic> json) {
    return EventChecklistModel(
      id: json['id'] as String,
      periodId: json['period_id'] as String,
      stepName: json['step_name'] as String,
      stepOrder: (json['step_order'] as num).toInt(),
      isCompleted: (json['is_completed'] as bool?) ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period_id': periodId,
      'step_name': stepName,
      'step_order': stepOrder,
      'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    };
  }

  EventChecklistModel copyWith({
    String? id,
    String? periodId,
    String? stepName,
    int? stepOrder,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return EventChecklistModel(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      stepName: stepName ?? this.stepName,
      stepOrder: stepOrder ?? this.stepOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}