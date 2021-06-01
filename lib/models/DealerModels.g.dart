// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DealerModels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DealerRating _$DealerRatingFromJson(Map<String, dynamic> json) {
  return DealerRating(
      id: json['id'] as int,
      dealer: json['dealer'] as int,
      user: json['user'] as int,
      comments: json['comments'] as String,
      rating: (json['rating'] as num)?.toDouble(),
      overallSatisfaction: json['overallSatisfaction'] as String,
      generalSatisfactionVal: json['generalSatisfactionVal'] as int,
      cleanBrightStation: json['cleanBrightStation'] as String,
      everythingWorks: json['everythingWorks'] as String,
      greatExperience: json['greatExperience'] as String,
      quickAndEasy: json['quickAndEasy'] as String,
      areaToImprove: json['areaToImprove'] as String);
}

Map<String, dynamic> _$DealerRatingToJson(DealerRating instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dealer': instance.dealer,
      'user': instance.user,
      'comments': instance.comments,
      'rating': instance.rating,
      'generalSatisfactionVal': instance.generalSatisfactionVal,
      'overallSatisfaction': instance.overallSatisfaction,
      'cleanBrightStation': instance.cleanBrightStation,
      'everythingWorks': instance.everythingWorks,
      'greatExperience': instance.greatExperience,
      'quickAndEasy': instance.quickAndEasy,
      'areaToImprove': instance.areaToImprove
    };

MobileDealer _$MobileDealerFromJson(Map<String, dynamic> json) {
  return MobileDealer(
      id: json['id'] as int,
      name: json['name'] as String,
      stationid: json['stationid'] as String,
      latitude: (json['latitude'] as num)?.toDouble(),
      userrating: (json['userrating'] as num)?.toDouble(),
      longitude: (json['longitude'] as num)?.toDouble());
}

Map<String, dynamic> _$MobileDealerToJson(MobileDealer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'stationid': instance.stationid,
      'latitude': instance.latitude,
      'userrating': instance.userrating,
      'longitude': instance.longitude
    };
