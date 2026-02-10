import 'package:equatable/equatable.dart';

enum NeedStatus { active, fulfilled, expired }

class Need extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final double latitude;
  final double longitude;
  final NeedStatus status;
  final DateTime createdAt;

  const Need({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, title, description, category, latitude, longitude, status, createdAt];

  factory Need.fromJson(Map<String, dynamic> json) {
    return Need(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: NeedStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NeedStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.name,
      // 'created_at' is handled by DB default
    };
  }
}
