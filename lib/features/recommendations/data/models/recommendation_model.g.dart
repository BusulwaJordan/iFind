// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecommendationModelImpl _$$RecommendationModelImplFromJson(
        Map<String, dynamic> json) =>
    _$RecommendationModelImpl(
      businessId: json['business_id'] as String,
      aiReasoning: json['reason'] as String,
    );

Map<String, dynamic> _$$RecommendationModelImplToJson(
        _$RecommendationModelImpl instance) =>
    <String, dynamic>{
      'business_id': instance.businessId,
      'reason': instance.aiReasoning,
    };
