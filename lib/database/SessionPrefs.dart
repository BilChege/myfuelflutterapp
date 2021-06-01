import 'package:intl/intl.dart';
import 'package:my_fuel_flutter_app/models/PackageModels.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionPrefs {

  final String _loggedInUserId = 'loggedInUserId';
  final String _loggedInFName = 'loggedInFName';
  final String _loggedInLName = 'loggedInLName';
  final String _loggedInPhone = 'loggedInPhone';
  final String _loggedInPin = 'loggedInPin';
  final String _loggedInEmail = 'loggedInEmail';
  final String _loggedInUserFeedback = 'loggedInUserFeedback';
  final String _loggedInRatedApp = 'loggedInRatedApp';
  final String _loggedInRating = 'loggedInRating';
  final String _loggedInPassword = 'loggedInPassword';
  final String _loggedInRole = 'loggedInRole';
  final String _bundle = 'bundle';
  final String _account = 'account';
  final String _points = 'points';
  final String _loggedInStatus = 'loggedInStatus';
  final String _purchaseUser = 'purchaseUser';
  final String _purchasedPackage = 'purchasedPackage';
  final String _purchaseDate = 'purchaseDate';
  final String  _expiryDate = 'expiryDate';

  final DateFormat _format = new DateFormat('yyyy-MM-dd');

  void setBalances(Balances balances) async{
    print('SetBalances '+balances.toString());
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setDouble(_bundle, balances.bundle);
    sharedPreferences.setDouble(_account, balances.account);
    sharedPreferences.setInt(_points, balances.points);
  }

  void setLoggedInStatus(bool status) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool(_loggedInStatus, status);
  }

  Future<bool> getLoggedInStatus() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(_loggedInStatus);
  }

  Future<Balances> getBalances() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    Balances balances = Balances.empty();
    balances.bundle = sharedPreferences.getDouble(_bundle);
    balances.account = sharedPreferences.getDouble(_account);
    balances.points = sharedPreferences.getInt(_points);
    print('getBalances '+balances.toString());
    return balances;
  }

  Future<void> setLoggedInUser(MobileUser user) async{
    print('To be inserted '+user.toString());
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setInt(_loggedInUserId, user.id);
    preferences.setString(_loggedInFName, user.firstName);
    preferences.setString(_loggedInLName, user.lastName);
    preferences.setString(_loggedInPhone, user.phone);
    preferences.setString(_loggedInPin, user.pin);
    preferences.setString(_loggedInEmail, user.email);
    preferences.setString(_loggedInUserFeedback, user.userfeedback);
    preferences.setBool(_loggedInRatedApp, user.ratedapp);
    preferences.setDouble(_loggedInRating , user.rating);
    preferences.setString(_loggedInRole, user.role);
    preferences.setString(_loggedInPassword, user.accountPassword);
  }

  Future<MobileUser> getLoggedInUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    MobileUser mobileUser = new MobileUser.empty();
    mobileUser.id = preferences.getInt(_loggedInUserId);
    mobileUser.firstName = preferences.getString(_loggedInFName);
    mobileUser.lastName = preferences.getString(_loggedInLName);
    mobileUser.phone = preferences.getString(_loggedInPhone);
    mobileUser.pin = preferences.getString(_loggedInPin);
    mobileUser.email = preferences.getString(_loggedInEmail);
    mobileUser.userfeedback = preferences.getString(_loggedInUserFeedback);
    mobileUser.ratedapp = preferences.getBool(_loggedInRatedApp);
    mobileUser.rating = preferences.getDouble(_loggedInRating);
    mobileUser.role = preferences.getString(_loggedInRole);
    mobileUser.accountPassword = preferences.getString(_loggedInPassword);
    print('Being fetched '+mobileUser.toString());
    return mobileUser;
  }

  void purchaseToBeMade(Purchase purchase) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setInt(_purchaseUser, purchase.user.id);
    sharedPreferences.setInt(_purchasedPackage, purchase.aPackage.id);
    sharedPreferences.setString(_purchaseDate, purchase.datePurchased);
    sharedPreferences.setString(_expiryDate, purchase.expiryDate);
  }

  Future<Purchase> getPurchaseToBeMade() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return Purchase(
      user: MobileUser(
        id: sharedPreferences.getInt(_purchaseUser)
      ),
      aPackage: FuelPackage(
        id: sharedPreferences.getInt(_purchasedPackage)
      ),
      datePurchased: sharedPreferences.getString(_purchaseDate),
      expiryDate: sharedPreferences.getString(_expiryDate)
    );
  }
}