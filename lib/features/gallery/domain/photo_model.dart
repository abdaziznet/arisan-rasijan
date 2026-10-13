import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_model.freezed.dart';
part 'photo_model.g.dart';

@freezed
class PhotoModel with _$PhotoModel {
  const factory PhotoModel({
    required String id,
    @JsonKey(name: 'period_id') required String periodId,
    @JsonKey(name: 'photo_url') required String photoUrl,
    @JsonKey(name: 'uploaded_by') required String uploadedBy,
    @JsonKey(name: 'uploaded_at') DateTime? uploadedAt,
  }) = _PhotoModel;

  factory PhotoModel.fromJson(Map<String, dynamic> json) =>
      _$PhotoModelFromJson(json);
}
