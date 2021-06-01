import 'package:json_annotation/json_annotation.dart';
import 'PackageModels.dart';
import 'VehicleModels.dart';

part 'UserModels.g.dart';

@JsonSerializable()
class Balances{

  double account;
  int points;
  double bundle;

  Balances({this.account, this.points, this.bundle});

  factory Balances.fromJson(Map<String,dynamic> json) => _$BalancesFromJson(json);

  Map<String,dynamic> toJson() => _$BalancesToJson(this);

  @override
  String toString() {
    return 'Balances{_account: $account, _points: $points, _bundle: $bundle}';
  }

  Balances.empty();
}

@JsonSerializable(explicitToJson: true)
class MobileUser{

  int id;
  String firstName;
  String lastName;
  String phone;
  String pin;
  String email;
  String role;
  String userfeedback;
  bool ratedapp;
  bool active;
  double rating;
  String accountPassword;
  Balances balances;
  List<Vehicle> vehicles;
  List<Purchase> purchases;
  List<FuelCar> usages;

  MobileUser({this.id, this.firstName, this.lastName, this.phone, this.pin,
    this.email, this.userfeedback, this.role, this.ratedapp, this.active, this.rating,
    this.accountPassword, this.balances, this.vehicles});

  factory MobileUser.fromJson(Map<String,dynamic> json) => _$MobileUserFromJson(json);

  MobileUser.empty();

  Map<String,dynamic> toJson() => _$MobileUserToJson(this);

  @override
  String toString() {
    return 'MobileUser{_id: $id, _firstName: $firstName, _lastName: $lastName, _phone: $phone, _pin: $pin, _email: $email, _userfeedback: $userfeedback, _ratedapp: $ratedapp, _rating: $rating, _accountPassword: $accountPassword, _balances: $balances, _vehicles: $vehicles, _purchases: $purchases, _usages: $usages,_role: $role}';
  }
}

@JsonSerializable(explicitToJson: true)
class MobileRedemption{
  int id;
  MobileUser user;
  String stationId;
  OffersForMobile offer;
  String datepurchased;

  MobileRedemption({this.id, this.user, this.stationId, this.offer,
    this.datepurchased});

  Map<String,dynamic> toJson() => _$MobileRedemptionToJson(this);
  
  factory MobileRedemption.fromJson(Map<String,dynamic> json) => _$MobileRedemptionFromJson(json);

  MobileRedemption.empty();

  @override
  String toString() {
    return 'MobileRedemption{_id: $id, _user: $user, _stationId: $stationId, _offer: $offer, _datepurchased: $datepurchased}';
  }
}