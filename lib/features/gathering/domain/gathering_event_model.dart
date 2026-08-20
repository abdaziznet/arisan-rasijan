import 'package:freezed_annotation/freezed_annotation.dart';

part 'gathering_event_model.freezed.dart';
part 'gathering_event_model.g.dart';

@freezed
class GatheringEventModel with _$GatheringEventModel {
  const factory GatheringEventModel({
    required String id,
    required String title,
    @Default('voting') String status,
    String? winningOptionId,
    DateTime? eventDate,
    @Default(0) double fundUsed,
    required String createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    DateTime? closedAt,
  }) = _GatheringEventModel;

  factory GatheringEventModel.fromJson(Map<String, dynamic> json) =>
      _$GatheringEventModelFromJson(json);
}