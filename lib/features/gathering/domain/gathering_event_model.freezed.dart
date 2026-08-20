// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gathering_event_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GatheringEventModel _$GatheringEventModelFromJson(Map<String, dynamic> json) {
  return _GatheringEventModel.fromJson(json);
}

/// @nodoc
mixin _$GatheringEventModel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get winningOptionId => throw _privateConstructorUsedError;
  DateTime? get eventDate => throw _privateConstructorUsedError;
  double get fundUsed => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get closedAt => throw _privateConstructorUsedError;

  /// Serializes this GatheringEventModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GatheringEventModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GatheringEventModelCopyWith<GatheringEventModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GatheringEventModelCopyWith<$Res> {
  factory $GatheringEventModelCopyWith(
          GatheringEventModel value, $Res Function(GatheringEventModel) then) =
      _$GatheringEventModelCopyWithImpl<$Res, GatheringEventModel>;
  @useResult
  $Res call(
      {String id,
      String title,
      String status,
      String? winningOptionId,
      DateTime? eventDate,
      double fundUsed,
      String createdBy,
      @JsonKey(name: 'created_at') DateTime createdAt,
      DateTime? closedAt});
}

/// @nodoc
class _$GatheringEventModelCopyWithImpl<$Res, $Val extends GatheringEventModel>
    implements $GatheringEventModelCopyWith<$Res> {
  _$GatheringEventModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GatheringEventModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? status = null,
    Object? winningOptionId = freezed,
    Object? eventDate = freezed,
    Object? fundUsed = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? closedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      winningOptionId: freezed == winningOptionId
          ? _value.winningOptionId
          : winningOptionId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventDate: freezed == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fundUsed: null == fundUsed
          ? _value.fundUsed
          : fundUsed // ignore: cast_nullable_to_non_nullable
              as double,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      closedAt: freezed == closedAt
          ? _value.closedAt
          : closedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GatheringEventModelImplCopyWith<$Res>
    implements $GatheringEventModelCopyWith<$Res> {
  factory _$$GatheringEventModelImplCopyWith(_$GatheringEventModelImpl value,
          $Res Function(_$GatheringEventModelImpl) then) =
      __$$GatheringEventModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String status,
      String? winningOptionId,
      DateTime? eventDate,
      double fundUsed,
      String createdBy,
      @JsonKey(name: 'created_at') DateTime createdAt,
      DateTime? closedAt});
}

/// @nodoc
class __$$GatheringEventModelImplCopyWithImpl<$Res>
    extends _$GatheringEventModelCopyWithImpl<$Res, _$GatheringEventModelImpl>
    implements _$$GatheringEventModelImplCopyWith<$Res> {
  __$$GatheringEventModelImplCopyWithImpl(_$GatheringEventModelImpl _value,
      $Res Function(_$GatheringEventModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of GatheringEventModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? status = null,
    Object? winningOptionId = freezed,
    Object? eventDate = freezed,
    Object? fundUsed = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? closedAt = freezed,
  }) {
    return _then(_$GatheringEventModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      winningOptionId: freezed == winningOptionId
          ? _value.winningOptionId
          : winningOptionId // ignore: cast_nullable_to_non_nullable
              as String?,
      eventDate: freezed == eventDate
          ? _value.eventDate
          : eventDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fundUsed: null == fundUsed
          ? _value.fundUsed
          : fundUsed // ignore: cast_nullable_to_non_nullable
              as double,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      closedAt: freezed == closedAt
          ? _value.closedAt
          : closedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GatheringEventModelImpl implements _GatheringEventModel {
  const _$GatheringEventModelImpl(
      {required this.id,
      required this.title,
      this.status = 'voting',
      this.winningOptionId,
      this.eventDate,
      this.fundUsed = 0,
      required this.createdBy,
      @JsonKey(name: 'created_at') required this.createdAt,
      this.closedAt});

  factory _$GatheringEventModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GatheringEventModelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey()
  final String status;
  @override
  final String? winningOptionId;
  @override
  final DateTime? eventDate;
  @override
  @JsonKey()
  final double fundUsed;
  @override
  final String createdBy;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  final DateTime? closedAt;

  @override
  String toString() {
    return 'GatheringEventModel(id: $id, title: $title, status: $status, winningOptionId: $winningOptionId, eventDate: $eventDate, fundUsed: $fundUsed, createdBy: $createdBy, createdAt: $createdAt, closedAt: $closedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GatheringEventModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.winningOptionId, winningOptionId) ||
                other.winningOptionId == winningOptionId) &&
            (identical(other.eventDate, eventDate) ||
                other.eventDate == eventDate) &&
            (identical(other.fundUsed, fundUsed) ||
                other.fundUsed == fundUsed) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.closedAt, closedAt) ||
                other.closedAt == closedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, status,
      winningOptionId, eventDate, fundUsed, createdBy, createdAt, closedAt);

  /// Create a copy of GatheringEventModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GatheringEventModelImplCopyWith<_$GatheringEventModelImpl> get copyWith =>
      __$$GatheringEventModelImplCopyWithImpl<_$GatheringEventModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GatheringEventModelImplToJson(
      this,
    );
  }
}

abstract class _GatheringEventModel implements GatheringEventModel {
  const factory _GatheringEventModel(
      {required final String id,
      required final String title,
      final String status,
      final String? winningOptionId,
      final DateTime? eventDate,
      final double fundUsed,
      required final String createdBy,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      final DateTime? closedAt}) = _$GatheringEventModelImpl;

  factory _GatheringEventModel.fromJson(Map<String, dynamic> json) =
      _$GatheringEventModelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get status;
  @override
  String? get winningOptionId;
  @override
  DateTime? get eventDate;
  @override
  double get fundUsed;
  @override
  String get createdBy;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  DateTime? get closedAt;

  /// Create a copy of GatheringEventModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GatheringEventModelImplCopyWith<_$GatheringEventModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
