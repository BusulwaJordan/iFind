import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String businessId;
  final String? needId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.businessId,
    this.needId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        needId,
        title,
        body,
        isRead,
        createdAt,
      ];
}
