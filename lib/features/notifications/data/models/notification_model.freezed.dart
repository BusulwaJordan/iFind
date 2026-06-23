// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) {
  return _NotificationModel.fromJson(json);
}

/// @nodoc
mixin _$NotificationModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'business_id')
  String? get businessId => throw _privateConstructorUsedError;
  @JsonKey(name: 'need_id')
  String? get needId => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_read')
  bool get isRead => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this NotificationModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationModelCopyWith<NotificationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationModelCopyWith<$Res> {
  factory $NotificationModelCopyWith(
          NotificationModel value, $Res Function(NotificationModel) then) =
      _$NotificationModelCopyWithImpl<$Res, NotificationModel>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'business_id') String? businessId,
      @JsonKey(name: 'need_id') String? needId,
      String type,
      Map<String, dynamic> data,
      String title,
      String body,
      @JsonKey(name: 'is_read') bool isRead,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$NotificationModelCopyWithImpl<$Res, $Val extends NotificationModel>
    implements $NotificationModelCopyWith<$Res> {
  _$NotificationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? businessId = freezed,
    Object? needId = freezed,
    Object? type = null,
    Object? data = null,
    Object? title = null,
    Object? body = null,
    Object? isRead = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      businessId: freezed == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as String?,
      needId: freezed == needId
          ? _value.needId
          : needId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationModelImplCopyWith<$Res>
    implements $NotificationModelCopyWith<$Res> {
  factory _$$NotificationModelImplCopyWith(_$NotificationModelImpl value,
          $Res Function(_$NotificationModelImpl) then) =
      __$$NotificationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'business_id') String? businessId,
      @JsonKey(name: 'need_id') String? needId,
      String type,
      Map<String, dynamic> data,
      String title,
      String body,
      @JsonKey(name: 'is_read') bool isRead,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$NotificationModelImplCopyWithImpl<$Res>
    extends _$NotificationModelCopyWithImpl<$Res, _$NotificationModelImpl>
    implements _$$NotificationModelImplCopyWith<$Res> {
  __$$NotificationModelImplCopyWithImpl(_$NotificationModelImpl _value,
      $Res Function(_$NotificationModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? businessId = freezed,
    Object? needId = freezed,
    Object? type = null,
    Object? data = null,
    Object? title = null,
    Object? body = null,
    Object? isRead = null,
    Object? createdAt = null,
  }) {
    return _then(_$NotificationModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      businessId: freezed == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as String?,
      needId: freezed == needId
          ? _value.needId
          : needId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationModelImpl extends _NotificationModel {
  const _$NotificationModelImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'business_id') this.businessId,
      @JsonKey(name: 'need_id') this.needId,
      required this.type,
      final Map<String, dynamic> data = const {},
      required this.title,
      required this.body,
      @JsonKey(name: 'is_read') this.isRead = false,
      @JsonKey(name: 'created_at') required this.createdAt})
      : _data = data,
        super._();

  factory _$NotificationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'business_id')
  final String? businessId;
  @override
  @JsonKey(name: 'need_id')
  final String? needId;
  @override
  final String type;
  final Map<String, dynamic> _data;
  @override
  @JsonKey()
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  final String title;
  @override
  final String body;
  @override
  @JsonKey(name: 'is_read')
  final bool isRead;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, businessId: $businessId, needId: $needId, type: $type, data: $data, title: $title, body: $body, isRead: $isRead, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.needId, needId) || other.needId == needId) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      businessId,
      needId,
      type,
      const DeepCollectionEquality().hash(_data),
      title,
      body,
      isRead,
      createdAt);

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationModelImplCopyWith<_$NotificationModelImpl> get copyWith =>
      __$$NotificationModelImplCopyWithImpl<_$NotificationModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationModelImplToJson(
      this,
    );
  }
}

abstract class _NotificationModel extends NotificationModel {
  const factory _NotificationModel(
          {required final String id,
          @JsonKey(name: 'user_id') required final String userId,
          @JsonKey(name: 'business_id') final String? businessId,
          @JsonKey(name: 'need_id') final String? needId,
          required final String type,
          final Map<String, dynamic> data,
          required final String title,
          required final String body,
          @JsonKey(name: 'is_read') final bool isRead,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$NotificationModelImpl;
  const _NotificationModel._() : super._();

  factory _NotificationModel.fromJson(Map<String, dynamic> json) =
      _$NotificationModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'business_id')
  String? get businessId;
  @override
  @JsonKey(name: 'need_id')
  String? get needId;
  @override
  String get type;
  @override
  Map<String, dynamic> get data;
  @override
  String get title;
  @override
  String get body;
  @override
  @JsonKey(name: 'is_read')
  bool get isRead;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of NotificationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationModelImplCopyWith<_$NotificationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
