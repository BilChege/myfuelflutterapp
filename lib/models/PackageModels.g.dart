// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'PackageModels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FuelPackage _$FuelPackageFromJson(Map<String, dynamic> json) {
  return FuelPackage(
      id: json['id'] as int,
      amount: (json['amount'] as num)?.toDouble(),
      expiryDays: json['expiryDays'] as int,
      priceOfPackage: (json['priceOfPackage'] as num)?.toDouble(),
      points: json['points'] as int,
      typeOfPackage: json['typeOfPackage'] as String,
      purchases: (json['purchases'] as List)
          ?.map((e) =>
              e == null ? null : Purchase.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$FuelPackageToJson(FuelPackage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'expiryDays': instance.expiryDays,
      'priceOfPackage': instance.priceOfPackage,
      'points': instance.points,
      'typeOfPackage': instance.typeOfPackage,
      'purchases': instance.purchases?.map((e) => e?.toJson())?.toList()
    };

OffersForMobile _$OffersForMobileFromJson(Map<String, dynamic> json) {
  return OffersForMobile(
      id: json['id'] as int,
      promoname: json['promoname'] as String,
      promocode: json['promocode'] as String,
      promodesc: json['promodesc'] as String,
      points: json['points'] as int);
}

Map<String, dynamic> _$OffersForMobileToJson(OffersForMobile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'promoname': instance.promoname,
      'promocode': instance.promocode,
      'promodesc': instance.promodesc,
      'points': instance.points
    };

MobileSambaza _$MobileSambazaFromJson(Map<String, dynamic> json) {
  return MobileSambaza(
      id: json['id'] as int,
      dateSent: json['dateSent'] as String,
      amountSent: (json['amountSent'] as num)?.toDouble(),
      userSentTo: json['userSentTo'] == null
          ? null
          : MobileUser.fromJson(json['userSentTo'] as Map<String, dynamic>));
}

Map<String, dynamic> _$MobileSambazaToJson(MobileSambaza instance) =>
    <String, dynamic>{
      'id': instance.id,
      'dateSent': instance.dateSent,
      'amountSent': instance.amountSent,
      'userSentTo': instance.userSentTo?.toJson()
    };

PromoCode _$PromoCodeFromJson(Map<String, dynamic> json) {
  return PromoCode(
      id: json['id'] as int,
      code: json['code'] as String,
      percentageDiscount: (json['percentageDiscount'] as num)?.toDouble(),
      expired: json['expired'] as bool,
      numberOfTimesApplied: json['numberOfTimesApplied'] as int);
}

Map<String, dynamic> _$PromoCodeToJson(PromoCode instance) => <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'percentageDiscount': instance.percentageDiscount,
      'expired': instance.expired,
      'numberOfTimesApplied': instance.numberOfTimesApplied
    };

CashBack _$CashBackFromJson(Map<String, dynamic> json) {
  return CashBack(
      id: json['id'] as int,
      threshold: (json['threshold'] as num)?.toDouble(),
      cashDiscPerLitre: (json['cashDiscPerLitre'] as num)?.toDouble(),
      amtAchieved: (json['amtAchieved'] as num)?.toDouble(),
      title: json['title'] as String,
      subscribed: json['subscribed'] as bool,
      description: json['description'] as String,
      dateCreated: json['dateCreated'] as String,
      expiryDate: json['expiryDate'] as String);
}

Map<String, dynamic> _$CashBackToJson(CashBack instance) => <String, dynamic>{
      'id': instance.id,
      'threshold': instance.threshold,
      'cashDiscPerLitre': instance.cashDiscPerLitre,
      'amtAchieved': instance.amtAchieved,
      'title': instance.title,
      'subscribed': instance.subscribed,
      'description': instance.description,
      'dateCreated': instance.dateCreated,
      'expiryDate': instance.expiryDate
    };

Purchase _$PurchaseFromJson(Map<String, dynamic> json) {
  return Purchase(
      id: json['id'] as int,
      user: json['user'] == null
          ? null
          : MobileUser.fromJson(json['user'] as Map<String, dynamic>),
      aPackage: json['aPackage'] == null
          ? null
          : FuelPackage.fromJson(json['aPackage'] as Map<String, dynamic>),
      datePurchased: json['datePurchased'] as String,
      expiryDate: json['expiryDate'] as String,
      balances: json['balances'] == null
          ? null
          : Balances.fromJson(json['balances'] as Map<String, dynamic>));
}

Map<String, dynamic> _$PurchaseToJson(Purchase instance) => <String, dynamic>{
      'id': instance.id,
      'user': instance.user?.toJson(),
      'aPackage': instance.aPackage?.toJson(),
      'datePurchased': instance.datePurchased,
      'expiryDate': instance.expiryDate,
      'balances': instance.balances?.toJson()
    };
