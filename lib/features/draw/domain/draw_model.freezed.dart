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

/// @nodoc
mixin _$DrawModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'period_id')
  String get periodId => throw _privateConstructorUsedError;
  @JsonKey(name: 'winner_id')
  String get winnerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'conducted_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'winner_name')
  String? get winnerName => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_collected')
  double? get totalCollected => throw _privateConstructorUsedError;

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
      @JsonKey(name: 'period_id') String periodId,
      @JsonKey(name: 'winner_id') String winnerId,
      @JsonKey(name: 'conducted_at') DateTime createdAt,
      @JsonKey(name: 'winner_name') String? winnerName,
      @JsonKey(name: 'total_collected') double? totalCollected});
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
      @JsonKey(name: 'period_id') String periodId,
      @JsonKey(name: 'winner_id') String winnerId,
      @JsonKey(name: 'conducted_at') DateTime createdAt,
      @JsonKey(name: 'winner_name') String? winnerName,
      @JsonKey(name: 'total_collected') double? totalCollected});
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

class _$DrawModelImpl implements _DrawModel {
  const _$DrawModelImpl(
      {required this.id,
      @JsonKey(name: 'period_id') required this.periodId,
      @JsonKey(name: 'winner_id') required this.winnerId,
      @JsonKey(name: 'conducted_at') required this.createdAt,
      @JsonKey(name: 'winner_name') this.winnerName,
      @JsonKey(name: 'total_collected') this.totalCollected});

  @override
  final String id;
  @override
  @JsonKey(name: 'period_id')
  final String periodId;
  @override
  @JsonKey(name: 'winner_id')
  final String winnerId;
  @override
  @JsonKey(name: 'conducted_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'winner_name')
  final String? winnerName;
  @override
  @JsonKey(name: 'total_collected')
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
}

abstract class _DrawModel implements DrawModel {
  const factory _DrawModel(
          {required final String id,
          @JsonKey(name: 'period_id') required final String periodId,
          @JsonKey(name: 'winner_id') required final String winnerId,
          @JsonKey(name: 'conducted_at') required final DateTime createdAt,
          @JsonKey(name: 'winner_name') final String? winnerName,
          @JsonKey(name: 'total_collected') final double? totalCollected}) =
      _$DrawModelImpl;

  @override
  String get id;
  @override
  @JsonKey(name: 'period_id')
  String get periodId;
  @override
  @JsonKey(name: 'winner_id')
  String get winnerId;
  @override
  @JsonKey(name: 'conducted_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'winner_name')
  String? get winnerName;
  @override
  @JsonKey(name: 'total_collected')
  double? get totalCollected;

  /// Create a copy of DrawModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DrawModelImplCopyWith<_$DrawModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
