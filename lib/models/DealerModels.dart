
import 'package:json_annotation/json_annotation.dart';

part 'DealerModels.g.dart';

@JsonSerializable()
class DealerRating {

  int id;
  int dealer;
  int user;
  String comments;
  double rating;
  int generalSatisfactionVal;
  String overallSatisfaction;
  String cleanBrightStation;
  String everythingWorks;
  String greatExperience;
  String quickAndEasy;
  String areaToImprove;

  DealerRating({this.id, this.dealer, this.user, this.comments,
    this.rating, this.overallSatisfaction, this.generalSatisfactionVal, this.cleanBrightStation, this.everythingWorks, this.greatExperience, this.quickAndEasy, this.areaToImprove});

  factory DealerRating.fromJson(Map<String,dynamic> json) => _$DealerRatingFromJson(json);
  Map<String,dynamic> toJson() => _$DealerRatingToJson(this);

  @override
  String toString() {
    return 'DealerRating{_id: $id, _dealer: $dealer, _user: $user, _comments: $comments, _rating: $rating}';
  }
}

@JsonSerializable()
class MobileDealer{

  int id;
  String name;
  String stationid;
  double latitude;
  double userrating;
  double longitude;

  MobileDealer({this.id, this.name, this.stationid, this.latitude,
    this.userrating, this.longitude});

  factory MobileDealer.fromJson(Map<String,dynamic> json) => _$MobileDealerFromJson(json);

  Map<String,dynamic> toJson() => _$MobileDealerToJson(this);

  MobileDealer.empty();

  @override
  String toString() {
    return '$stationid ($name)';
  }
}