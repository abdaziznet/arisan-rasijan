// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_ledger_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FundLedgerModel _$FundLedgerModelFromJson(Map<String, dynamic> json) {
  return _FundLedgerModel.fromJson(json);
}

/// @nodoc
mixin _$FundLedgerModel {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String? get periodId => throw _privateConstructorUsedError;
  String? get gatheringEventId => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this FundLedgerModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FundLedgerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FundLedgerModelCopyWith<FundLedgerModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FundLedgerModelCopyWith<$Res> {
  factory $FundLedgerModelCopyWith(
          FundLedgerModel value, $Res Function(FundLedgerModel) then) =
      _$FundLedgerModelCopyWithImpl<$Res, FundLedgerModel>;
  @useResult
  $Res call(
      {String id,
      String type,
      double amount,
      String? periodId,
      String? gatheringEventId,
      String? description,
      String createdBy,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$FundLedgerModelCopyWithImpl<$Res, $Val extends FundLedgerModel>
    implements $FundLedgerModelCopyWith<$Res> {
  _$FundLedgerModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FundLedgerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amount = null,
    Object? periodId = freezed,
    Object? gatheringEventId = freezed,
    Object? description = freezed,
    Object? createdBy = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      periodId: freezed == periodId
          ? _value.periodId
          : periodId // ignore: cast_nullable_to_non_nullable
              as String?,
      gatheringEventId: freezed == gatheringEventId
          ? _value.gatheringEventId
          : gatheringEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FundLedgerModelImplCopyWith<$Res>
    implements $FundLedgerModelCopyWith<$Res> {
  factory _$$FundLedgerModelImplCopyWith(_$FundLedgerModelImpl value,
          $Res Function(_$FundLedgerModelImpl) then) =
      __$$FundLedgerModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String type,
      double amount,
      String? periodId,
      String? gatheringEventId,
      String? description,
      String createdBy,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$FundLedgerModelImplCopyWithImpl<$Res>
    extends _$FundLedgerModelCopyWithImpl<$Res, _$FundLedgerModelImpl>
    implements _$$FundLedgerModelImplCopyWith<$Res> {
  __$$FundLedgerModelImplCopyWithImpl(
      _$FundLedgerModelImpl _value, $Res Function(_$FundLedgerModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FundLedgerModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amount = null,
    Object? periodId = freezed,
    Object? gatheringEventId = freezed,
    Object? description = freezed,
    Object? createdBy = null,
    Object? createdAt = null,
  }) {
    return _then(_$FundLedgerModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      periodId: freezed == periodId
          ? _value.periodId
          : periodId // ignore: cast_nullable_to_non_nullable
              as String?,
      gatheringEventId: freezed == gatheringEventId
          ? _value.gatheringEventId
          : gatheringEventId // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FundLedgerModelImpl implements _FundLedgerModel {
  const _$FundLedgerModelImpl(
      {required this.id,
      required this.type,
      required this.amount,
      this.periodId,
      this.gatheringEventId,
      this.description,
      required this.createdBy,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$FundLedgerModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FundLedgerModelImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
  @override
  final double amount;
  @override
  final String? periodId;
  @override
  final String? gatheringEventId;
  @override
  final String? description;
  @override
  final String createdBy;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'FundLedgerModel(id: $id, type: $type, amount: $amount, periodId: $periodId, gatheringEventId: $gatheringEventId, description: $description, createdBy: $createdBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FundLedgerModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.periodId, periodId) ||
                other.periodId == periodId) &&
            (identical(other.gatheringEventId, gatheringEventId) ||
                other.gatheringEventId == gatheringEventId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, type, amount, periodId,
      gatheringEventId, description, createdBy, createdAt);

  /// Create a copy of FundLedgerModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FundLedgerModelImplCopyWith<_$FundLedgerModelImpl> get copyWith =>
      __$$FundLedgerModelImplCopyWithImpl<_$FundLedgerModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FundLedgerModelImplToJson(
      this,
    );
  }
}

abstract class _FundLedgerModel implements FundLedgerModel {
  const factory _FundLedgerModel(
          {required final String id,
          required final String type,
          required final double amount,
          final String? periodId,
          final String? gatheringEventId,
          final String? description,
          required final String createdBy,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$FundLedgerModelImpl;

  factory _FundLedgerModel.fromJson(Map<String, dynamic> json) =
      _$FundLedgerModelImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  double get amount;
  @override
  String? get periodId;
  @override
  String? get gatheringEventId;
  @override
  String? get description;
  @override
  String get createdBy;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of FundLedgerModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FundLedgerModelImplCopyWith<_$FundLedgerModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
