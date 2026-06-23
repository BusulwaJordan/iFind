import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String userId,
    String? businessId,
    String? needId,
    required String type,
    @Default({}) Map<String, dynamic> data,
    required String title,
    required String body,
    @Default(false) bool isRead,
    required DateTime createdAt,
  }) = _AppNotification;
}
