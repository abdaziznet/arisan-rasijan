// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'draw_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DrawModel _$DrawModelFromJson(Map<String, dynamic> json) {
  return _DrawModel.fromJson(json);
}

/// @nodoc
mixin _$DrawModel {
  String get id => throw _privateConstructorUsedError;
  String get periodId => throw _privateConstructorUsedError;
  String get winnerId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get winnerName => throw _privateConstructorUsedError;
  double? get totalCollected => throw _privateConstructorUsedError;

  /// Serializes this DrawModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DrawModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DrawModelCopyWith<DrawModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DrawModelCopyWith<$Res> {
  factory $DrawModelCopyWith(DrawModel value, $Res Function(DrawModel) then) =
      _$DrawModelCopyWithImpl<$Res, DrawModel>;
  @useResult
  $Res call(
      {String id,
      String periodId,
      String winnerId,
      DateTime createdAt,
      String? winnerName,
      double? totalCollected});
}

/// @nodoc
class _$DrawModelCopyWithImpl<$Res, $Val extends DrawModel>
    implements $DrawModelCopyWith<$Res> {
  _$DrawModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DrawModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? periodId = null,
    Object? winnerId = null,
    Object? createdAt = null,
    Object? winnerName = freezed,
    Object? totalCollected = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      periodId: null == periodId
          ? _value.periodId
          : periodId // ignore: cast_nullable_to_non_nullable
              as String,
      winnerId: null == winnerId
          ? _value.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      winnerName: freezed == winnerName
          ? _value.winnerName
          : winnerName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalCollected: freezed == totalCollected
          ? _value.totalCollected
          : totalCollected // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DrawModelImplCopyWith<$Res>
    implements $DrawModelCopyWith<$Res> {
  factory _$$DrawModelImplCopyWith(
          _$DrawModelImpl value, $Res Function(_$DrawModelImpl) then) =
      __$$DrawModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String periodId,
      String winnerId,
      DateTime createdAt,
      String? winnerName,
      double? totalCollected});
}

/// @nodoc
class __$$DrawModelImplCopyWithImpl<$Res>
    extends _$DrawModelCopyWithImpl<$Res, _$DrawModelImpl>
    implements _$$DrawModelImplCopyWith<$Res> {
  __$$DrawModelImplCopyWithImpl(
      _$DrawModelImpl _value, $Res Function(_$DrawModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DrawModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? periodId = null,
    Object? winnerId = null,
    Object? createdAt = null,
    Object? winnerName = freezed,
    Object? totalCollected = freezed,
  }) {
    return _then(_$DrawModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      periodId: null == periodId
          ? _value.periodId
          : periodId // ignore: cast_nullable_to_non_nullable
              as String,
      winnerId: null == winnerId
          ? _value.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      winnerName: freezed == winnerName
          ? _value.winnerName
          : winnerName // ignore: cast_nullable_to_non_nullable
              as String?,
      totalCollected: freezed == totalCollected
          ? _value.totalCollected
          : totalCollected // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DrawModelImpl implements _DrawModel {
  const _$DrawModelImpl(
      {required this.id,
      required this.periodId,
      required this.winnerId,
      required this.createdAt,
      this.winnerName,
      this.totalCollected});

  factory _$DrawModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DrawModelImplFromJson(json);

  @override
  final String id;
  @override
  final String periodId;
  @override
  final String winnerId;
  @override
  final DateTime createdAt;
  @override
  final String? winnerName;
  @override
  final double? totalCollected;

  @override
  String toString() {
    return 'DrawModel(id: $id, periodId: $periodId, winnerId: $winnerId, createdAt: $createdAt, winnerName: $winnerName, totalCollected: $totalCollected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DrawModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.periodId, periodId) ||
                other.periodId == periodId) &&
            (identical(other.winnerId, winnerId) ||
                other.winnerId == winnerId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.winnerName, winnerName) ||
                other.winnerName == winnerName) &&
            (identical(other.totalCollected, totalCollected) ||
                other.totalCollected == totalCollected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, periodId, winnerId,
      createdAt, winnerName, totalCollected);

  /// Create a copy of DrawModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DrawModelImplCopyWith<_$DrawModelImpl> get copyWith =>
      __$$DrawModelImplCopyWithImpl<_$DrawModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DrawModelImplToJson(
      this,
    );
  }
}

abstract class _DrawModel implements DrawModel {
  const factory _DrawModel(
      {required final String id,
      required final String periodId,
      required final String winnerId,
      required final DateTime createdAt,
      final String? winnerName,
      final double? totalCollected}) = _$DrawModelImpl;

  factory _DrawModel.fromJson(Map<String, dynamic> json) =
      _$DrawModelImpl.fromJson;

  @override
  String get id;
  @override
  String get periodId;
  @override
  String get winnerId;
  @override
  DateTime get createdAt;
  @override
  String? get winnerName;
  @override
  double? get totalCollected;

  /// Create a copy of DrawModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DrawModelImplCopyWith<_$DrawModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
