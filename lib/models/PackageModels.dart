import 'package:json_annotation/json_annotation.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';

part 'PackageModels.g.dart';

@JsonSerializable(explicitToJson: true)
class FuelPackage{

  int id;
  double amount;
  int expiryDays;
  double priceOfPackage;
  int points;
  String typeOfPackage;
  List<Purchase> purchases;

  FuelPackage({this.id, this.amount, this.expiryDays, this.priceOfPackage,
    this.points, this.typeOfPackage, this.purchases});

  factory FuelPackage.fromJson(Map<String,dynamic> json) => _$FuelPackageFromJson(json);

  Map<String,dynamic> toJson() => _$FuelPackageToJson(this);

  @override
  String toString() {
    return 'FuelPackage{_id: $id, _amount: $amount, _expirydays: $expiryDays, _priceOfPackage: $priceOfPackage, _points: $points, _typeOfPackage: $typeOfPackage, _purchases: $purchases}';
  }
}

@JsonSerializable()
class OffersForMobile {

  int id;
  String promoname;
  String promocode;
  String promodesc;
  int points;

  OffersForMobile({this.id, this.promoname, this.promocode, this.promodesc,
    this.points});

  factory OffersForMobile.fromJson(Map<String,dynamic> json) => _$OffersForMobileFromJson(json);

  Map<String,dynamic> toJson() => _$OffersForMobileToJson(this);

  @override
  String toString() {
    return 'OffersForMobile{_id: $id, _promoname: $promoname, _promocode: $promocode, _promodesc: $promodesc, _points: $points}';
  }
}

@JsonSerializable(explicitToJson: true)
class MobileSambaza{
  int id;
  String dateSent;
  double amountSent;
  MobileUser userSentTo;

  MobileSambaza({this.id, this.dateSent, this.amountSent, this.userSentTo});

  factory MobileSambaza.fromJson(Map<String,dynamic> json) => _$MobileSambazaFromJson(json);

  Map<String,dynamic> toJson() => _$MobileSambazaToJson(this);

  @override
  String toString() {
    return 'MobileSambaza{id: $id, dateSent: $dateSent, amountSent: $amountSent, userSentTo: $userSentTo}';
  }
}

@JsonSerializable()
class PromoCode{

  int id;
  String code;
  double percentageDiscount;
  bool expired;
  int numberOfTimesApplied;

  PromoCode({this.id,this.code,this.percentageDiscount,this.expired,this.numberOfTimesApplied});

  factory PromoCode.fromJson(Map<String,dynamic> json) => _$PromoCodeFromJson(json);

  Map<String,dynamic> toJson() => _$PromoCodeToJson(this);

  @override
  String toString() {
    return 'PromoCode{id: $id, code: $code, percentageDiscount: $percentageDiscount, expired: $expired, numberOfTimesApplied: $numberOfTimesApplied}';
  }


}

@JsonSerializable()
class CashBack{

  int id;
  double threshold;
  double cashDiscPerLitre;
  double amtAchieved;
  String title;
  bool subscribed;
  String description;
  String dateCreated;
  String expiryDate;

  CashBack({this.id, this.threshold, this.cashDiscPerLitre, this.amtAchieved, this.title, this.subscribed, this.description, this.dateCreated, this.expiryDate});

  factory CashBack.fromJson(Map<String,dynamic> json) => _$CashBackFromJson(json);
  Map<String,dynamic> toJson() => _$CashBackToJson(this);

  @override
  String toString() {
    return 'CashBack{id: $id, threshold: $threshold, cashDiscPerLitre: $cashDiscPerLitre, title: $title, description: $description, dateCreated: $dateCreated, expiryDate: $expiryDate}';
  }

}

@JsonSerializable(explicitToJson: true)
class Purchase{

  int id;
  MobileUser user;
  FuelPackage aPackage;
  String datePurchased;
  String expiryDate;
  Balances balances;

  Purchase({this.id, this.user, this.aPackage, this.datePurchased,
    this.expiryDate, this.balances});

  factory Purchase.fromJson(Map<String,dynamic> json) => _$PurchaseFromJson(json);

  Purchase.empty();

  Map<String,dynamic> toJson() => _$PurchaseToJson(this);

}