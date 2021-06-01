// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserModels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Balances _$BalancesFromJson(Map<String, dynamic> json) {
  return Balances(
      account: (json['account'] as num)?.toDouble(),
      points: json['points'] as int,
      bundle: (json['bundle'] as num)?.toDouble());
}

Map<String, dynamic> _$BalancesToJson(Balances instance) => <String, dynamic>{
      'account': instance.account,
      'points': instance.points,
      'bundle': instance.bundle
    };

MobileUser _$MobileUserFromJson(Map<String, dynamic> json) {
  return MobileUser(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String,
      pin: json['pin'] as String,
      email: json['email'] as String,
      userfeedback: json['userfeedback'] as String,
      role: json['role'] as String,
      ratedapp: json['ratedapp'] as bool,
      active: json['active'] as bool,
      rating: (json['rating'] as num)?.toDouble(),
      accountPassword: json['accountPassword'] as String,
      balances: json['balances'] == null
          ? null
          : Balances.fromJson(json['balances'] as Map<String, dynamic>),
      vehicles: (json['vehicles'] as List)
          ?.map((e) =>
              e == null ? null : Vehicle.fromJson(e as Map<String, dynamic>))
          ?.toList())
    ..purchases = (json['purchases'] as List)
        ?.map((e) =>
            e == null ? null : Purchase.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..usages = (json['usages'] as List)
        ?.map((e) =>
            e == null ? null : FuelCar.fromJson(e as Map<String, dynamic>))
        ?.toList();
}

Map<String, dynamic> _$MobileUserToJson(MobileUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'phone': instance.phone,
      'pin': instance.pin,
      'email': instance.email,
      'role': instance.role,
      'userfeedback': instance.userfeedback,
      'ratedapp': instance.ratedapp,
      'active': instance.active,
      'rating': instance.rating,
      'accountPassword': instance.accountPassword,
      'balances': instance.balances?.toJson(),
      'vehicles': instance.vehicles?.map((e) => e?.toJson())?.toList(),
      'purchases': instance.purchases?.map((e) => e?.toJson())?.toList(),
      'usages': instance.usages?.map((e) => e?.toJson())?.toList()
    };

MobileRedemption _$MobileRedemptionFromJson(Map<String, dynamic> json) {
  return MobileRedemption(
      id: json['id'] as int,
      user: json['user'] == null
          ? null
          : MobileUser.fromJson(json['user'] as Map<String, dynamic>),
      stationId: json['stationId'] as String,
      offer: json['offer'] == null
          ? null
          : OffersForMobile.fromJson(json['offer'] as Map<String, dynamic>),
      datepurchased: json['datepurchased'] as String);
}

Map<String, dynamic> _$MobileRedemptionToJson(MobileRedemption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user?.toJson(),
      'stationId': instance.stationId,
      'offer': instance.offer?.toJson(),
      'datepurchased': instance.datepurchased
    };
