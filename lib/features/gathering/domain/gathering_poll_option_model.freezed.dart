// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gathering_poll_option_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GatheringPollOptionModel _$GatheringPollOptionModelFromJson(
    Map<String, dynamic> json) {
  return _GatheringPollOptionModel.fromJson(json);
}

/// @nodoc
mixin _$GatheringPollOptionModel {
  String get id => throw _privateConstructorUsedError;
  String get gatheringEventId => throw _privateConstructorUsedError;
  String get optionLabel => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  int get voteCount => throw _privateConstructorUsedError;

  /// Serializes this GatheringPollOptionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GatheringPollOptionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GatheringPollOptionModelCopyWith<GatheringPollOptionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GatheringPollOptionModelCopyWith<$Res> {
  factory $GatheringPollOptionModelCopyWith(GatheringPollOptionModel value,
          $Res Function(GatheringPollOptionModel) then) =
      _$GatheringPollOptionModelCopyWithImpl<$Res, GatheringPollOptionModel>;
  @useResult
  $Res call(
      {String id,
      String gatheringEventId,
      String optionLabel,
      @JsonKey(name: 'created_at') DateTime createdAt,
      int voteCount});
}

/// @nodoc
class _$GatheringPollOptionModelCopyWithImpl<$Res,
        $Val extends GatheringPollOptionModel>
    implements $GatheringPollOptionModelCopyWith<$Res> {
  _$GatheringPollOptionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GatheringPollOptionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gatheringEventId = null,
    Object? optionLabel = null,
    Object? createdAt = null,
    Object? voteCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      gatheringEventId: null == gatheringEventId
          ? _value.gatheringEventId
          : gatheringEventId // ignore: cast_nullable_to_non_nullable
              as String,
      optionLabel: null == optionLabel
          ? _value.optionLabel
          : optionLabel // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      voteCount: null == voteCount
          ? _value.voteCount
          : voteCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GatheringPollOptionModelImplCopyWith<$Res>
    implements $GatheringPollOptionModelCopyWith<$Res> {
  factory _$$GatheringPollOptionModelImplCopyWith(
          _$GatheringPollOptionModelImpl value,
          $Res Function(_$GatheringPollOptionModelImpl) then) =
      __$$GatheringPollOptionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String gatheringEventId,
      String optionLabel,
      @JsonKey(name: 'created_at') DateTime createdAt,
      int voteCount});
}

/// @nodoc
class __$$GatheringPollOptionModelImplCopyWithImpl<$Res>
    extends _$GatheringPollOptionModelCopyWithImpl<$Res,
        _$GatheringPollOptionModelImpl>
    implements _$$GatheringPollOptionModelImplCopyWith<$Res> {
  __$$GatheringPollOptionModelImplCopyWithImpl(
      _$GatheringPollOptionModelImpl _value,
      $Res Function(_$GatheringPollOptionModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of GatheringPollOptionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gatheringEventId = null,
    Object? optionLabel = null,
    Object? createdAt = null,
    Object? voteCount = null,
  }) {
    return _then(_$GatheringPollOptionModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      gatheringEventId: null == gatheringEventId
          ? _value.gatheringEventId
          : gatheringEventId // ignore: cast_nullable_to_non_nullable
              as String,
      optionLabel: null == optionLabel
          ? _value.optionLabel
          : optionLabel // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      voteCount: null == voteCount
          ? _value.voteCount
          : voteCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GatheringPollOptionModelImpl implements _GatheringPollOptionModel {
  const _$GatheringPollOptionModelImpl(
      {required this.id,
      required this.gatheringEventId,
      required this.optionLabel,
      @JsonKey(name: 'created_at') required this.createdAt,
      this.voteCount = 0});

  factory _$GatheringPollOptionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GatheringPollOptionModelImplFromJson(json);

  @override
  final String id;
  @override
  final String gatheringEventId;
  @override
  final String optionLabel;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey()
  final int voteCount;

  @override
  String toString() {
    return 'GatheringPollOptionModel(id: $id, gatheringEventId: $gatheringEventId, optionLabel: $optionLabel, createdAt: $createdAt, voteCount: $voteCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GatheringPollOptionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.gatheringEventId, gatheringEventId) ||
                other.gatheringEventId == gatheringEventId) &&
            (identical(other.optionLabel, optionLabel) ||
                other.optionLabel == optionLabel) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.voteCount, voteCount) ||
                other.voteCount == voteCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, gatheringEventId, optionLabel, createdAt, voteCount);

  /// Create a copy of GatheringPollOptionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GatheringPollOptionModelImplCopyWith<_$GatheringPollOptionModelImpl>
      get copyWith => __$$GatheringPollOptionModelImplCopyWithImpl<
          _$GatheringPollOptionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GatheringPollOptionModelImplToJson(
      this,
    );
  }
}

abstract class _GatheringPollOptionModel implements GatheringPollOptionModel {
  const factory _GatheringPollOptionModel(
      {required final String id,
      required final String gatheringEventId,
      required final String optionLabel,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      final int voteCount}) = _$GatheringPollOptionModelImpl;

  factory _GatheringPollOptionModel.fromJson(Map<String, dynamic> json) =
      _$GatheringPollOptionModelImpl.fromJson;

  @override
  String get id;
  @override
  String get gatheringEventId;
  @override
  String get optionLabel;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  int get voteCount;

  /// Create a copy of GatheringPollOptionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GatheringPollOptionModelImplCopyWith<_$GatheringPollOptionModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
