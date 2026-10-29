class BackupJob {
  const BackupJob({
    required this.id,
    required this.status,
    required this.triggerType,
    required this.scope,
    required this.createdAt,
    this.note,
    this.startedAt,
    this.finishedAt,
    this.sizeBytes,
    this.location,
    this.error,
  });

  final String id;
  final String status;
  final String triggerType;
  final String scope;
  final DateTime createdAt;
  final String? note;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? sizeBytes;
  final String? location;
  final String? error;

  bool get isActive => status == 'pending' || status == 'running';

  Duration? get duration => startedAt != null && finishedAt != null
      ? finishedAt!.difference(startedAt!)
      : null;

  factory BackupJob.fromMap(Map<String, dynamic> map) => BackupJob(
        id: map['id'] as String,
        status: map['status'] as String,
        triggerType: map['trigger_type'] as String,
        scope: map['scope'] as String,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
        note: map['note'] as String?,
        startedAt: map['started_at'] == null
            ? null
            : DateTime.parse(map['started_at'] as String).toLocal(),
        finishedAt: map['finished_at'] == null
            ? null
            : DateTime.parse(map['finished_at'] as String).toLocal(),
        sizeBytes: (map['size_bytes'] as num?)?.toInt(),
        location: map['location'] as String?,
        error: map['error'] as String?,
      );
}
