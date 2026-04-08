import 'package:freezed_annotation/freezed_annotation.dart';

part 'recommendation.freezed.dart';

@freezed
class Recommendation with _$Recommendation {
  const factory Recommendation({
    required String businessId,
    required String aiReasoning,
  }) = _Recommendation;
}
