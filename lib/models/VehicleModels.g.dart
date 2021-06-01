// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'VehicleModels.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FuelCar _$FuelCarFromJson(Map<String, dynamic> json) {
  return FuelCar(
      id: json['id'] as int,
      amount: (json['amount'] as num)?.toDouble(),
      vehicle: json['vehicle'] == null
          ? null
          : Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
      dateFueled: json['dateFueled'] as String,
      stationid: json['stationid'] as String,
      mileage: json['mileage'] as int,
      user: json['user'] == null
          ? null
          : MobileUser.fromJson(json['user'] as Map<String, dynamic>),
      feedBack: json['feedBack'] as String,
      balances: json['balances'] == null
          ? null
          : Balances.fromJson(json['balances'] as Map<String, dynamic>));
}

Map<String, dynamic> _$FuelCarToJson(FuelCar instance) => <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'vehicle': instance.vehicle?.toJson(),
      'dateFueled': instance.dateFueled,
      'stationid': instance.stationid,
      'mileage': instance.mileage,
      'user': instance.user?.toJson(),
      'feedBack': instance.feedBack,
      'balances': instance.balances?.toJson()
    };

VehicleModel _$VehicleModelFromJson(Map<String, dynamic> json) {
  return VehicleModel(id: json['id'] as int, model: json['model'] as String);
}

Map<String, dynamic> _$VehicleModelToJson(VehicleModel instance) =>
    <String, dynamic>{'id': instance.id, 'model': instance.model};

VehicleMake _$VehicleMakeFromJson(Map<String, dynamic> json) {
  return VehicleMake(
      id: json['id'] as int,
      vehiclemake: json['vehiclemake'] as String,
      models: (json['models'] as List)
          ?.map((e) => e == null
              ? null
              : VehicleModel.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$VehicleMakeToJson(VehicleMake instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehiclemake': instance.vehiclemake,
      'models': instance.models?.map((e) => e?.toJson())?.toList()
    };

Mileage _$MileageFromJson(Map<String, dynamic> json) {
  return Mileage(
      id: json['id'] as int,
      vehicle: json['vehicle'] == null
          ? null
          : Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
      dateReported: json['dateReported'] == null
          ? null
          : DateTime.parse(json['dateReported'] as String),
      distanceCovered: (json['distanceCovered'] as num)?.toDouble());
}

Map<String, dynamic> _$MileageToJson(Mileage instance) => <String, dynamic>{
      'id': instance.id,
      'vehicle': instance.vehicle,
      'dateReported': instance.dateReported?.toIso8601String(),
      'distanceCovered': instance.distanceCovered
    };

Vehicle _$VehicleFromJson(Map<String, dynamic> json) {
  return Vehicle(
      id: json['id'] as int,
      regno: json['regno'] as String,
      make: json['make'] as String,
      makeid: json['makeid'] as int,
      active: json['active'] as bool,
      modelid: json['modelid'] as int,
      mileage: json['mileage'] as int,
      owner: json['owner'] == null
          ? null
          : MobileUser.fromJson(json['owner'] as Map<String, dynamic>),
      CCs: json['CCs'] as String,
      enginetype: json['enginetype'] as String,
      fuelingInstances: (json['fuelingInstances'] as List)
          ?.map((e) =>
              e == null ? null : FuelCar.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      mileagereports: (json['mileagereports'] as List)
          ?.map((e) =>
              e == null ? null : Mileage.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      consumptionRate: json['consumptionRate'] as int);
}

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
      'id': instance.id,
      'regno': instance.regno,
      'make': instance.make,
      'makeid': instance.makeid,
      'active': instance.active,
      'modelid': instance.modelid,
      'mileage': instance.mileage,
      'consumptionRate': instance.consumptionRate,
      'owner': instance.owner?.toJson(),
      'CCs': instance.CCs,
      'enginetype': instance.enginetype,
      'fuelingInstances':
          instance.fuelingInstances?.map((e) => e?.toJson())?.toList(),
      'mileagereports':
          instance.mileagereports?.map((e) => e?.toJson())?.toList()
    };
