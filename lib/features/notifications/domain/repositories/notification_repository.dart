import 'package:dartz/dartz.dart';
import 'package:ifind/core/errors/failures.dart';
import 'package:ifind/features/notifications/domain/entities/notification.dart';

abstract class NotificationRepository {
  /// Stream notifications for a specific business
  Stream<List<AppNotification>> watchNotifications(String businessId);

  /// Mark a notification as read
  Future<Either<Failure, void>> markAsRead(String notificationId);
}
