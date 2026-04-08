import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ifind/features/media/services/media_service.dart';

final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});
