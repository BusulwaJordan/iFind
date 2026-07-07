// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Chat {
  String get id =>
      throw _privateConstructorUsedError; // B2C fields (nullable for B2B)
  String? get customerId => throw _privateConstructorUsedError;
  String? get businessId =>
      throw _privateConstructorUsedError; // B2B fields (nullable for B2C)
  String? get businessAId => throw _privateConstructorUsedError;
  String? get businessBId =>
      throw _privateConstructorUsedError; // Flag to distinguish chat type
  bool get isB2B => throw _privateConstructorUsedError; // Common fields
  String? get lastMessage => throw _privateConstructorUsedError;
  DateTime? get lastMessageAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt =>
      throw _privateConstructorUsedError; // Transient UI fields (for B2C)
  String? get businessName => throw _privateConstructorUsedError;
  String? get businessLogoUrl => throw _privateConstructorUsedError;
  String? get customerName => throw _privateConstructorUsedError;
  String? get customerAvatarUrl =>
      throw _privateConstructorUsedError; // Transient UI fields (for B2B)
  String? get partnerBusinessName => throw _privateConstructorUsedError;
  String? get partnerBusinessLogo =>
      throw _privateConstructorUsedError; // The business_id "View Shop" should open for this chat, resolved
// per-viewer: the partner's business for B2B, the shop for a customer's
// B2C view, or the customer's own business (if they own one) for a
// business owner's B2C view. Null when there's no business to show
// (e.g. a plain customer with no business of their own).
  String? get otherPartyBusinessId =>
      throw _privateConstructorUsedError; // Number of messages in this chat sent by the other party that this
// user hasn't read yet. Computed separately (not a raw chats column).
  int get unreadCount => throw _privateConstructorUsedError;

  /// Create a copy of Chat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatCopyWith<Chat> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatCopyWith<$Res> {
  factory $ChatCopyWith(Chat value, $Res Function(Chat) then) =
      _$ChatCopyWithImpl<$Res, Chat>;
  @useResult
  $Res call(
      {String id,
      String? customerId,
      String? businessId,
      String? businessAId,
      String? businessBId,
      bool isB2B,
      String? lastMessage,
      DateTime? lastMessageAt,
      DateTime createdAt,
      DateTime updatedAt,
      String? businessName,
      String? businessLogoUrl,
      String? customerName,
      String? customerAvatarUrl,
      String? partnerBusinessName,
      String? partnerBusinessLogo,
      String? otherPartyBusinessId,
      int unreadCount});
}

/// @nodoc
class _$ChatCopyWithImpl<$Res, $Val extends Chat>
    implements $ChatCopyWith<$Res> {
  _$ChatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Chat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = freezed,
    Object? businessId = freezed,
    Object? businessAId = freezed,
    Object? businessBId = freezed,
    Object? isB2B = null,
    Object? lastMessage = freezed,
    Object? lastMessageAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? businessName = freezed,
    Object? businessLogoUrl = freezed,
    Object? customerName = freezed,
    Object? customerAvatarUrl = freezed,
    Object? partnerBusinessName = freezed,
    Object? partnerBusinessLogo = freezed,
    Object? otherPartyBusinessId = freezed,
    Object? unreadCount = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: freezed == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String?,
      businessId: freezed == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as String?,
      businessAId: freezed == businessAId
          ? _value.businessAId
          : businessAId // ignore: cast_nullable_to_non_nullable
              as String?,
      businessBId: freezed == businessBId
          ? _value.businessBId
          : businessBId // ignore: cast_nullable_to_non_nullable
              as String?,
      isB2B: null == isB2B
          ? _value.isB2B
          : isB2B // ignore: cast_nullable_to_non_nullable
              as bool,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      businessName: freezed == businessName
          ? _value.businessName
          : businessName // ignore: cast_nullable_to_non_nullable
              as String?,
      businessLogoUrl: freezed == businessLogoUrl
          ? _value.businessLogoUrl
          : businessLogoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      customerName: freezed == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerAvatarUrl: freezed == customerAvatarUrl
          ? _value.customerAvatarUrl
          : customerAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      partnerBusinessName: freezed == partnerBusinessName
          ? _value.partnerBusinessName
          : partnerBusinessName // ignore: cast_nullable_to_non_nullable
              as String?,
      partnerBusinessLogo: freezed == partnerBusinessLogo
          ? _value.partnerBusinessLogo
          : partnerBusinessLogo // ignore: cast_nullable_to_non_nullable
              as String?,
      otherPartyBusinessId: freezed == otherPartyBusinessId
          ? _value.otherPartyBusinessId
          : otherPartyBusinessId // ignore: cast_nullable_to_non_nullable
              as String?,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatImplCopyWith<$Res> implements $ChatCopyWith<$Res> {
  factory _$$ChatImplCopyWith(
          _$ChatImpl value, $Res Function(_$ChatImpl) then) =
      __$$ChatImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? customerId,
      String? businessId,
      String? businessAId,
      String? businessBId,
      bool isB2B,
      String? lastMessage,
      DateTime? lastMessageAt,
      DateTime createdAt,
      DateTime updatedAt,
      String? businessName,
      String? businessLogoUrl,
      String? customerName,
      String? customerAvatarUrl,
      String? partnerBusinessName,
      String? partnerBusinessLogo,
      String? otherPartyBusinessId,
      int unreadCount});
}

/// @nodoc
class __$$ChatImplCopyWithImpl<$Res>
    extends _$ChatCopyWithImpl<$Res, _$ChatImpl>
    implements _$$ChatImplCopyWith<$Res> {
  __$$ChatImplCopyWithImpl(_$ChatImpl _value, $Res Function(_$ChatImpl) _then)
      : super(_value, _then);

  /// Create a copy of Chat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? customerId = freezed,
    Object? businessId = freezed,
    Object? businessAId = freezed,
    Object? businessBId = freezed,
    Object? isB2B = null,
    Object? lastMessage = freezed,
    Object? lastMessageAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? businessName = freezed,
    Object? businessLogoUrl = freezed,
    Object? customerName = freezed,
    Object? customerAvatarUrl = freezed,
    Object? partnerBusinessName = freezed,
    Object? partnerBusinessLogo = freezed,
    Object? otherPartyBusinessId = freezed,
    Object? unreadCount = null,
  }) {
    return _then(_$ChatImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      customerId: freezed == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as String?,
      businessId: freezed == businessId
          ? _value.businessId
          : businessId // ignore: cast_nullable_to_non_nullable
              as String?,
      businessAId: freezed == businessAId
          ? _value.businessAId
          : businessAId // ignore: cast_nullable_to_non_nullable
              as String?,
      businessBId: freezed == businessBId
          ? _value.businessBId
          : businessBId // ignore: cast_nullable_to_non_nullable
              as String?,
      isB2B: null == isB2B
          ? _value.isB2B
          : isB2B // ignore: cast_nullable_to_non_nullable
              as bool,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageAt: freezed == lastMessageAt
          ? _value.lastMessageAt
          : lastMessageAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      businessName: freezed == businessName
          ? _value.businessName
          : businessName // ignore: cast_nullable_to_non_nullable
              as String?,
      businessLogoUrl: freezed == businessLogoUrl
          ? _value.businessLogoUrl
          : businessLogoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      customerName: freezed == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String?,
      customerAvatarUrl: freezed == customerAvatarUrl
          ? _value.customerAvatarUrl
          : customerAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      partnerBusinessName: freezed == partnerBusinessName
          ? _value.partnerBusinessName
          : partnerBusinessName // ignore: cast_nullable_to_non_nullable
              as String?,
      partnerBusinessLogo: freezed == partnerBusinessLogo
          ? _value.partnerBusinessLogo
          : partnerBusinessLogo // ignore: cast_nullable_to_non_nullable
              as String?,
      otherPartyBusinessId: freezed == otherPartyBusinessId
          ? _value.otherPartyBusinessId
          : otherPartyBusinessId // ignore: cast_nullable_to_non_nullable
              as String?,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$ChatImpl implements _Chat {
  const _$ChatImpl(
      {required this.id,
      this.customerId,
      this.businessId,
      this.businessAId,
      this.businessBId,
      this.isB2B = false,
      this.lastMessage,
      this.lastMessageAt,
      required this.createdAt,
      required this.updatedAt,
      this.businessName,
      this.businessLogoUrl,
      this.customerName,
      this.customerAvatarUrl,
      this.partnerBusinessName,
      this.partnerBusinessLogo,
      this.otherPartyBusinessId,
      this.unreadCount = 0});

  @override
  final String id;
// B2C fields (nullable for B2B)
  @override
  final String? customerId;
  @override
  final String? businessId;
// B2B fields (nullable for B2C)
  @override
  final String? businessAId;
  @override
  final String? businessBId;
// Flag to distinguish chat type
  @override
  @JsonKey()
  final bool isB2B;
// Common fields
  @override
  final String? lastMessage;
  @override
  final DateTime? lastMessageAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
// Transient UI fields (for B2C)
  @override
  final String? businessName;
  @override
  final String? businessLogoUrl;
  @override
  final String? customerName;
  @override
  final String? customerAvatarUrl;
// Transient UI fields (for B2B)
  @override
  final String? partnerBusinessName;
  @override
  final String? partnerBusinessLogo;
// The business_id "View Shop" should open for this chat, resolved
// per-viewer: the partner's business for B2B, the shop for a customer's
// B2C view, or the customer's own business (if they own one) for a
// business owner's B2C view. Null when there's no business to show
// (e.g. a plain customer with no business of their own).
  @override
  final String? otherPartyBusinessId;
// Number of messages in this chat sent by the other party that this
// user hasn't read yet. Computed separately (not a raw chats column).
  @override
  @JsonKey()
  final int unreadCount;

  @override
  String toString() {
    return 'Chat(id: $id, customerId: $customerId, businessId: $businessId, businessAId: $businessAId, businessBId: $businessBId, isB2B: $isB2B, lastMessage: $lastMessage, lastMessageAt: $lastMessageAt, createdAt: $createdAt, updatedAt: $updatedAt, businessName: $businessName, businessLogoUrl: $businessLogoUrl, customerName: $customerName, customerAvatarUrl: $customerAvatarUrl, partnerBusinessName: $partnerBusinessName, partnerBusinessLogo: $partnerBusinessLogo, otherPartyBusinessId: $otherPartyBusinessId, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.businessId, businessId) ||
                other.businessId == businessId) &&
            (identical(other.businessAId, businessAId) ||
                other.businessAId == businessAId) &&
            (identical(other.businessBId, businessBId) ||
                other.businessBId == businessBId) &&
            (identical(other.isB2B, isB2B) || other.isB2B == isB2B) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.lastMessageAt, lastMessageAt) ||
                other.lastMessageAt == lastMessageAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.businessName, businessName) ||
                other.businessName == businessName) &&
            (identical(other.businessLogoUrl, businessLogoUrl) ||
                other.businessLogoUrl == businessLogoUrl) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.customerAvatarUrl, customerAvatarUrl) ||
                other.customerAvatarUrl == customerAvatarUrl) &&
            (identical(other.partnerBusinessName, partnerBusinessName) ||
                other.partnerBusinessName == partnerBusinessName) &&
            (identical(other.partnerBusinessLogo, partnerBusinessLogo) ||
                other.partnerBusinessLogo == partnerBusinessLogo) &&
            (identical(other.otherPartyBusinessId, otherPartyBusinessId) ||
                other.otherPartyBusinessId == otherPartyBusinessId) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      customerId,
      businessId,
      businessAId,
      businessBId,
      isB2B,
      lastMessage,
      lastMessageAt,
      createdAt,
      updatedAt,
      businessName,
      businessLogoUrl,
      customerName,
      customerAvatarUrl,
      partnerBusinessName,
      partnerBusinessLogo,
      otherPartyBusinessId,
      unreadCount);

  /// Create a copy of Chat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatImplCopyWith<_$ChatImpl> get copyWith =>
      __$$ChatImplCopyWithImpl<_$ChatImpl>(this, _$identity);
}

abstract class _Chat implements Chat {
  const factory _Chat(
      {required final String id,
      final String? customerId,
      final String? businessId,
      final String? businessAId,
      final String? businessBId,
      final bool isB2B,
      final String? lastMessage,
      final DateTime? lastMessageAt,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final String? businessName,
      final String? businessLogoUrl,
      final String? customerName,
      final String? customerAvatarUrl,
      final String? partnerBusinessName,
      final String? partnerBusinessLogo,
      final String? otherPartyBusinessId,
      final int unreadCount}) = _$ChatImpl;

  @override
  String get id; // B2C fields (nullable for B2B)
  @override
  String? get customerId;
  @override
  String? get businessId; // B2B fields (nullable for B2C)
  @override
  String? get businessAId;
  @override
  String? get businessBId; // Flag to distinguish chat type
  @override
  bool get isB2B; // Common fields
  @override
  String? get lastMessage;
  @override
  DateTime? get lastMessageAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt; // Transient UI fields (for B2C)
  @override
  String? get businessName;
  @override
  String? get businessLogoUrl;
  @override
  String? get customerName;
  @override
  String? get customerAvatarUrl; // Transient UI fields (for B2B)
  @override
  String? get partnerBusinessName;
  @override
  String?
      get partnerBusinessLogo; // The business_id "View Shop" should open for this chat, resolved
// per-viewer: the partner's business for B2B, the shop for a customer's
// B2C view, or the customer's own business (if they own one) for a
// business owner's B2C view. Null when there's no business to show
// (e.g. a plain customer with no business of their own).
  @override
  String?
      get otherPartyBusinessId; // Number of messages in this chat sent by the other party that this
// user hasn't read yet. Computed separately (not a raw chats column).
  @override
  int get unreadCount;

  /// Create a copy of Chat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatImplCopyWith<_$ChatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Message {
  String get id => throw _privateConstructorUsedError;
  String get chatId => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageCopyWith<Message> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageCopyWith<$Res> {
  factory $MessageCopyWith(Message value, $Res Function(Message) then) =
      _$MessageCopyWithImpl<$Res, Message>;
  @useResult
  $Res call(
      {String id,
      String chatId,
      String senderId,
      String content,
      bool isRead,
      DateTime createdAt});
}

/// @nodoc
class _$MessageCopyWithImpl<$Res, $Val extends Message>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? chatId = null,
    Object? senderId = null,
    Object? content = null,
    Object? isRead = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
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
abstract class _$$MessageImplCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$$MessageImplCopyWith(
          _$MessageImpl value, $Res Function(_$MessageImpl) then) =
      __$$MessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String chatId,
      String senderId,
      String content,
      bool isRead,
      DateTime createdAt});
}

/// @nodoc
class __$$MessageImplCopyWithImpl<$Res>
    extends _$MessageCopyWithImpl<$Res, _$MessageImpl>
    implements _$$MessageImplCopyWith<$Res> {
  __$$MessageImplCopyWithImpl(
      _$MessageImpl _value, $Res Function(_$MessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? chatId = null,
    Object? senderId = null,
    Object? content = null,
    Object? isRead = null,
    Object? createdAt = null,
  }) {
    return _then(_$MessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      chatId: null == chatId
          ? _value.chatId
          : chatId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
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

class _$MessageImpl implements _Message {
  const _$MessageImpl(
      {required this.id,
      required this.chatId,
      required this.senderId,
      required this.content,
      this.isRead = false,
      required this.createdAt});

  @override
  final String id;
  @override
  final String chatId;
  @override
  final String senderId;
  @override
  final String content;
  @override
  @JsonKey()
  final bool isRead;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Message(id: $id, chatId: $chatId, senderId: $senderId, content: $content, isRead: $isRead, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.chatId, chatId) || other.chatId == chatId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, chatId, senderId, content, isRead, createdAt);

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      __$$MessageImplCopyWithImpl<_$MessageImpl>(this, _$identity);
}

abstract class _Message implements Message {
  const factory _Message(
      {required final String id,
      required final String chatId,
      required final String senderId,
      required final String content,
      final bool isRead,
      required final DateTime createdAt}) = _$MessageImpl;

  @override
  String get id;
  @override
  String get chatId;
  @override
  String get senderId;
  @override
  String get content;
  @override
  bool get isRead;
  @override
  DateTime get createdAt;

  /// Create a copy of Message
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageImplCopyWith<_$MessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
