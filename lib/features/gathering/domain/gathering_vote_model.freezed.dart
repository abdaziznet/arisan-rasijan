// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gathering_vote_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GatheringVoteModel _$GatheringVoteModelFromJson(Map<String, dynamic> json) {
  return _GatheringVoteModel.fromJson(json);
}

/// @nodoc
mixin _$GatheringVoteModel {
  String get id => throw _privateConstructorUsedError;
  String get gatheringEventId => throw _privateConstructorUsedError;
  String get optionId => throw _privateConstructorUsedError;
  String get memberId => throw _privateConstructorUsedError;
  @JsonKey(name: 'voted_at')
  DateTime get votedAt => throw _privateConstructorUsedError;

  /// Serializes this GatheringVoteModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GatheringVoteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GatheringVoteModelCopyWith<GatheringVoteModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GatheringVoteModelCopyWith<$Res> {
  factory $GatheringVoteModelCopyWith(
          GatheringVoteModel value, $Res Function(GatheringVoteModel) then) =
      _$GatheringVoteModelCopyWithImpl<$Res, GatheringVoteModel>;
  @useResult
  $Res call(
      {String id,
      String gatheringEventId,
      String optionId,
      String memberId,
      @JsonKey(name: 'voted_at') DateTime votedAt});
}

/// @nodoc
class _$GatheringVoteModelCopyWithImpl<$Res, $Val extends GatheringVoteModel>
    implements $GatheringVoteModelCopyWith<$Res> {
  _$GatheringVoteModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GatheringVoteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gatheringEventId = null,
    Object? optionId = null,
    Object? memberId = null,
    Object? votedAt = null,
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
      optionId: null == optionId
          ? _value.optionId
          : optionId // ignore: cast_nullable_to_non_nullable
              as String,
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      votedAt: null == votedAt
          ? _value.votedAt
          : votedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GatheringVoteModelImplCopyWith<$Res>
    implements $GatheringVoteModelCopyWith<$Res> {
  factory _$$GatheringVoteModelImplCopyWith(_$GatheringVoteModelImpl value,
          $Res Function(_$GatheringVoteModelImpl) then) =
      __$$GatheringVoteModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String gatheringEventId,
      String optionId,
      String memberId,
      @JsonKey(name: 'voted_at') DateTime votedAt});
}

/// @nodoc
class __$$GatheringVoteModelImplCopyWithImpl<$Res>
    extends _$GatheringVoteModelCopyWithImpl<$Res, _$GatheringVoteModelImpl>
    implements _$$GatheringVoteModelImplCopyWith<$Res> {
  __$$GatheringVoteModelImplCopyWithImpl(_$GatheringVoteModelImpl _value,
      $Res Function(_$GatheringVoteModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of GatheringVoteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gatheringEventId = null,
    Object? optionId = null,
    Object? memberId = null,
    Object? votedAt = null,
  }) {
    return _then(_$GatheringVoteModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      gatheringEventId: null == gatheringEventId
          ? _value.gatheringEventId
          : gatheringEventId // ignore: cast_nullable_to_non_nullable
              as String,
      optionId: null == optionId
          ? _value.optionId
          : optionId // ignore: cast_nullable_to_non_nullable
              as String,
      memberId: null == memberId
          ? _value.memberId
          : memberId // ignore: cast_nullable_to_non_nullable
              as String,
      votedAt: null == votedAt
          ? _value.votedAt
          : votedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GatheringVoteModelImpl implements _GatheringVoteModel {
  const _$GatheringVoteModelImpl(
      {required this.id,
      required this.gatheringEventId,
      required this.optionId,
      required this.memberId,
      @JsonKey(name: 'voted_at') required this.votedAt});

  factory _$GatheringVoteModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GatheringVoteModelImplFromJson(json);

  @override
  final String id;
  @override
  final String gatheringEventId;
  @override
  final String optionId;
  @override
  final String memberId;
  @override
  @JsonKey(name: 'voted_at')
  final DateTime votedAt;

  @override
  String toString() {
    return 'GatheringVoteModel(id: $id, gatheringEventId: $gatheringEventId, optionId: $optionId, memberId: $memberId, votedAt: $votedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GatheringVoteModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.gatheringEventId, gatheringEventId) ||
                other.gatheringEventId == gatheringEventId) &&
            (identical(other.optionId, optionId) ||
                other.optionId == optionId) &&
            (identical(other.memberId, memberId) ||
                other.memberId == memberId) &&
            (identical(other.votedAt, votedAt) || other.votedAt == votedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, gatheringEventId, optionId, memberId, votedAt);

  /// Create a copy of GatheringVoteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GatheringVoteModelImplCopyWith<_$GatheringVoteModelImpl> get copyWith =>
      __$$GatheringVoteModelImplCopyWithImpl<_$GatheringVoteModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GatheringVoteModelImplToJson(
      this,
    );
  }
}

abstract class _GatheringVoteModel implements GatheringVoteModel {
  const factory _GatheringVoteModel(
          {required final String id,
          required final String gatheringEventId,
          required final String optionId,
          required final String memberId,
          @JsonKey(name: 'voted_at') required final DateTime votedAt}) =
      _$GatheringVoteModelImpl;

  factory _GatheringVoteModel.fromJson(Map<String, dynamic> json) =
      _$GatheringVoteModelImpl.fromJson;

  @override
  String get id;
  @override
  String get gatheringEventId;
  @override
  String get optionId;
  @override
  String get memberId;
  @override
  @JsonKey(name: 'voted_at')
  DateTime get votedAt;

  /// Create a copy of GatheringVoteModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GatheringVoteModelImplCopyWith<_$GatheringVoteModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
