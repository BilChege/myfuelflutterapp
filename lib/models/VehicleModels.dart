import 'dart:collection';
import 'dart:ffi';
import 'package:json_annotation/json_annotation.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/screens/fuelcar.dart' as prefix0;
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix1;

part 'VehicleModels.g.dart';

@JsonSerializable(explicitToJson: true)
class FuelCar{
  int id;
  double amount;
  Vehicle vehicle;
  String dateFueled;
  String stationid;
  int mileage;
  MobileUser user;
  String feedBack;
  Balances balances;

  FuelCar({this.id, this.amount, this.vehicle, this.dateFueled,
    this.stationid, this.mileage, this.user, this.feedBack, this.balances});
  
  FuelCar.empty();
  
  factory FuelCar.fromJson(Map<String,dynamic> json) => _$FuelCarFromJson(json);

  Map<String,dynamic> toJson() => _$FuelCarToJson(this);

  @override
  String toString() {
    return 'FuelCar{_id: $id, _amount: $amount, _vehicle: $vehicle, _dateFueled: $dateFueled, _stationid: $stationid, _user: $user, _feedBack: $feedBack, _balances: $balances}';
  }
}

@JsonSerializable()
class VehicleModel{
  int id;
  String model;

  VehicleModel({this.id,this.model});
  VehicleModel.empty();

  factory VehicleModel.fromJson(Map<String,dynamic> json) => _$VehicleModelFromJson(json);

  Map<String,dynamic> toJson() => _$VehicleModelToJson(this);

  @override
  String toString() {
    return '$model';
  }
}

@JsonSerializable(explicitToJson: true)
class VehicleMake{
  int id;
  String vehiclemake;
  List<VehicleModel> models;

  VehicleMake({this.id, this.vehiclemake, this.models});
  
  VehicleMake.empty();
  
  factory VehicleMake.fromJson(Map<String,dynamic> json) => _$VehicleMakeFromJson(json);

  Map<String,dynamic> toJson() => _$VehicleMakeToJson(this);

  @override
  String toString() {
    return '$vehiclemake';
  }
}

@JsonSerializable()
class Mileage{
  int id;
  Vehicle vehicle;
  DateTime dateReported;
  double distanceCovered;

  Mileage({this.id, this.vehicle, this.dateReported, this.distanceCovered});

  factory Mileage.fromJson(Map<String,dynamic> json) => _$MileageFromJson(json);

  Map<String,dynamic> toJson() => _$MileageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Vehicle{

  int id;
  String regno;
  String make;
  int makeid;
  bool active;
  int modelid;
  int mileage;
  int consumptionRate;
  MobileUser owner;
  String CCs;
  String enginetype;
  List<FuelCar> fuelingInstances;
  List<Mileage> mileagereports;

  Vehicle({this.id, this.regno, this.make, this.makeid, this.active,
    this.modelid, this.mileage, this.owner, this.CCs, this.enginetype,
    this.fuelingInstances, this.mileagereports, this.consumptionRate});

  Vehicle.empty();

  factory Vehicle.fromJson(Map<String,dynamic> json) => _$VehicleFromJson(json);

  Map<String,dynamic> toJson() => _$VehicleToJson(this);

  @override
  String toString() {
    return '$regno ($make)';
  }
}
