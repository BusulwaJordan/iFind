import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ifind/features/recommendations/domain/entities/recommendation.dart';

part 'recommendation_model.freezed.dart';
part 'recommendation_model.g.dart';

@freezed
class RecommendationModel with _$RecommendationModel {
  const factory RecommendationModel({
    @JsonKey(name: 'business_id') required String businessId,
    @JsonKey(name: 'reason') required String aiReasoning,
  }) = _RecommendationModel;

  factory RecommendationModel.fromJson(Map<String, dynamic> json) =>
      _$RecommendationModelFromJson(json);

  const RecommendationModel._();

  Recommendation toEntity() => Recommendation(
        businessId: businessId,
        aiReasoning: aiReasoning,
      );
}
