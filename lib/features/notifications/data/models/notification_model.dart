import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ifind/features/notifications/domain/entities/notification.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'business_id') String? businessId,
    @JsonKey(name: 'need_id') String? needId,
    required String type,
    @Default({}) Map<String, dynamic> data,
    required String title,
    required String body,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  const NotificationModel._();

  AppNotification toEntity() => AppNotification(
        id: id,
        userId: userId,
        businessId: businessId,
        needId: needId,
        type: type,
        data: data,
        title: title,
        body: body,
        isRead: isRead,
        createdAt: createdAt,
      );

  factory NotificationModel.fromEntity(AppNotification notification) =>
      NotificationModel(
        id: notification.id,
        userId: notification.userId,
        businessId: notification.businessId,
        needId: notification.needId,
        type: notification.type,
        data: notification.data,
        title: notification.title,
        body: notification.body,
        isRead: notification.isRead,
        createdAt: notification.createdAt,
      );
}
