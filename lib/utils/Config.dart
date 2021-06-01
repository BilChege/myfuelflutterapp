
  import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:core' as prefix0;
import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:my_fuel_flutter_app/database/AppDB.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/DealerModels.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/models/VehicleModels.dart';
import 'package:password_hash/password_hash.dart';
import 'package:password_hash/salt.dart';
import 'package:permission_handler/permission_handler.dart';

  final String appDb = 'app_db.db';
  final String tbVehicle = 'vehicle';
  final String id = 'id';
  final String keyUser = 'user';
  final String comments = 'comments';
  final String dealer = 'dealer';
  final String rating = 'rating';
  final String regNo = 'regno';
  final String make = 'make';
  final String aPackage = 'aPackage';
  final String datePurchased = 'datePurchased';
  final String expiryDate = 'expiryDate';
  final String balances = 'balances';
  final String makeId = 'make_id';
  final String active = 'active';
  final String consumptionRate = 'consumptionRate';
  final String modelId = 'model_id';
  final String ccs = 'CCs';
  final String engineType = 'enginetype';
  final String name = 'name';
  final String stationId = 'station_id';
  final String latitude = 'latitude';
  final String longitude = 'longitude';
  final String firstName = 'firstName';
  final String lastName = 'lastName';
  final String phone = 'phone';
  final String pin = 'pin';
  final String email = 'email';
  final String offer = 'offer';
  final String userFeedBack = 'userFeedBack';
  final String ratedApp = 'ratedApp';
  final String customerMessage = 'CustomerMessage';
  final String responseCode = 'ResponseCode';
  final String responseDesc = 'ResponseDescription';
  final String merchantReqId = 'MerchantRequestID';
  final String resultCode = 'ResultCode';
  final String resultDesc = 'ResultDesc';
  final String businessSc = 'BusinessShortCode';
  final String mpesaPassword = 'Password';
  final String mpesaAmount = 'Amount';
  final String transactionType = 'TransactionType';
  final String partyA = 'PartyA';
  final String partyB = 'PartyB';
  final String vehicles = 'vehicles';
  final String mpesaPhone = 'PhoneNumber';
  final String smsVerificationFailure = 'SMS Verification failure';
  final String callBackURL = 'CallBackURL';
  final String callBackUrlValue = 'http://192.168.1.11:8080/myFuelAPI';
  final String accountReference = 'AccountReference';
  final String transactionDesc = 'TransactionDesc';
  final String timestamp = 'Timestamp';
  final String checkoutId = 'CheckoutRequestID';
  final String password = 'password';
  final String accountPassword = 'accountPassword';
  final String amount ='amount';
  final String corporateUserRole = 'Corp-User';
  final String individualUserRole = 'User';
  final String bundle = 'bundle';
  final String account = 'account';
  final String promoName = 'promoname';
  final String promoCode = 'promocode';
  final String promoDesc = 'promodesc';
  final String expiryDays = 'expirydays';
  final String expiry = 'expiry';
  final String priceOfPackage = 'priceOfPackage';
  final String dateFueled = 'dateFueled';
  final String feedBack = 'feedBack';
  final String flagInvalidPhoneNumber = 'invalid phone number';
  final String vehicleMake = 'vehiclemake';
  final String models = 'models';
  final String userrating = 'userrating';
  final String points = 'points';
  final String typeOfPackage = 'typeOfPackage';
  final String purchases = 'purchases';
  final String fuelCar = 'fuelCar';
  final String consumer_key = 'aGwO62wwMEfGK8pWX6jWoxnejrTkCllk';
  final String consumer_secret = 'X729si71RDapKBGW';
  final String googleMapsApiKey = 'AIzaSyC1oBtZ7QkyEyQRVC5fD6BrC2aYtF8NFqY';
  final String safaricomStkProcessRequest = 'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/';
  final String safaricomStkPushQuery = 'https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/';
  final String safaricomAuth = 'https://sandbox.safaricom.co.ke/oauth/v1/generate';
  final String businessShortCode = '174379';
  final String accountReferenceValue = 'Shell Vivo Test';
  final String transactionTypeValue = 'CustomerPayBillOnline';
  final String callBackUrl = 'http://192.168.1.11:8080/myFuelAPI';
  final String distanceMatrixApiURL = 'https://maps.googleapis.com/maps/api/distancematrix/json';
  final String passKey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
//  final String baseUrlHotSpot = 'http://192.168.43.89:8080/myFuelAPI/mobile/';
  final String baseUrlLocal = 'http://172.104.242.19:8282/myFuelAPI/mobile/';
//  final String baseUrlLocalVd = 'http://10.0.2.2:8080/myFuelAPI/mobile/';
  final String mileage = 'mileage';
//  final String baseUrlStaging = 'http://134.209.109.13:8282/myFuelAPI/mobile/';
//  final String baseUrldemo = 'http://172.104.147.162:8282/myFuelAPI/mobile/';
//  final String baseUrlQA = 'http://172.104.242.19:8282/myfuelAPI/mobile/';
  final double cashPerLitre = 100;

  Map<String, String> postHeaders(String requestToken){
    return {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $requestToken'
    };
  }

  Map<String,String> getHeaders(String requestToken){
    return {
      'Accept': 'application/json',
      'Authorization':'Bearer $requestToken'
    };
  }

  Future<Position> getLocation() async{
    Position currLoc = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    double latitude = currLoc.latitude;
    double longitude = currLoc.longitude;
    print('################__________________Current location: ______________ $latitude $longitude');
    return currLoc;
  }

  String generateMpesaPassword(String timeStamp){
    return base64Encode(utf8.encode(businessShortCode+passKey+timeStamp));
  }

  String generateTimeStamp(){
    return new DateFormat('yyyyMMddhhmmss').format(new DateTime.now());
  }

  Map<String,String> loginHeader = {
//    'Accept':'utf-8',
    'Accept':'application/json'
  };

  List<MobileDealer> allDealers() {
    List<MobileDealer> mobileDealers = [];
    AppDB.appDB.findAll(dealer).then((rows) {
      for (var i = 0; i < rows.length; i++){
        HashMap<String,dynamic> obj = rows[i];
        MobileDealer mobileDealer = MobileDealer.empty();
        mobileDealer.id = obj[id];
        mobileDealer.name = obj[name];
        mobileDealer.longitude = obj[longitude];
        mobileDealer.latitude = obj[latitude];
        mobileDealer.stationid = obj[stationId];
        mobileDealer.userrating = obj[rating];
        mobileDealers.add(mobileDealer);
      }
    });
    return mobileDealers;
  }

  String hashPassword(String password){
//    return Password.hash(password, algorithm);
  }

  String hashPbkdf2(String password){
    var generator = new PBKDF2();
    var salt = Salt.generateAsBase64String(16);
    var hash = generator.generateKey(password, salt, 1000, 32);
  }

  bool verifyPassword(String plain, String hashed){
//    return Password.verify(plain, hashed);
  }

  MobileUser getLoggedInUser(){
    MobileUser user;
    SessionPrefs().getLoggedInUser().then((u) {
      user = u;
    });
    return user;
  }

  Balances getBalances(){
    Balances balances;
    SessionPrefs().getBalances().then((b){
      balances = b;
    });
    return balances;
  }

  Future<bool> checkIfInstalled(String packageName) async{
    return await DeviceApps.isAppInstalled(packageName);
  }

  Future<PermissionStatus> checkPermissionStatus(PermissionGroup permissionGroup) async{
    return await PermissionHandler().checkPermissionStatus(permissionGroup);
  }

  Future<Map<PermissionGroup,PermissionStatus>> requestPermission(List<PermissionGroup> permissions) async{
    return await PermissionHandler().requestPermissions(permissions);
  }

  Future<MobileUser> updateUser(String jsonString,String requestToken) async{
    MobileUser result;
    Response response;
    try{
      response = await put(baseUrlLocal+'updateuserdetails',headers: postHeaders(requestToken),body: jsonString);
    } on SocketException{
      Fluttertoast.showToast(msg: 'You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    var jsonResponse;
    if(response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        jsonResponse = json.decode(response.body);
        return MobileUser.fromJson(jsonResponse);
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode occurred while updating data');
      }
    } else {
      Fluttertoast.showToast(msg: 'No response from service',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    return null;
  }

  Future<DealerRating> doRating(String jsonBody,String requestToken) async{
    Response response;
    try{
      response = await post(baseUrlLocal+'ratestation',body: jsonBody,headers: postHeaders(requestToken));
    } on SocketException{
      Fluttertoast.showToast(msg: 'You may be offline');
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        return DealerRating.fromJson(json.decode(response.body));
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode occured while contacting rating service');
      }
    } else {
      Fluttertoast.showToast(msg: 'No response from the server');
    }
    return null;
  }

  Future<MobileUser> checkUser(String email,String token) async{
    MobileUser result;
    Response response;
    try{
      response = await get(baseUrlLocal+'checkuser?email=$email',headers: getHeaders(token));
    } on SocketException{
      Fluttertoast.showToast(msg: 'Service is unreachable. You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    var jsonResponse;
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        jsonResponse = json.decode(response.body);
        result = MobileUser.fromJson(jsonResponse);
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode Occured while verifyng user',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      }
    } else {
      Fluttertoast.showToast(msg: 'No response from the service',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    return result;
  }

  Future<String> getTokenBasicAuth() async{
    String basicAuthString = base64Encode(utf8.encode('VivoMfMobile:@@@@@@Vivo##Mf##Mobile@@@@@@'));
    Map<String,String> requestHeaders = {
      'Content-type':'application/x-www-form-urlencoded',
      'Authorization':'Basic $basicAuthString',
      'Accept':'application/json'
    };
    Map<String,String> basicAuthBody = {
      'grant_type':'password',
      'username':'Vivo',
      'password':'####vivomobileuser####'
    };
    Response response;
    try{
      response = await post('http://192.168.8.103:8080/myFuelAPI/oauth/token',headers: requestHeaders,body: basicAuthBody);
    } on SocketException{
      Fluttertoast.showToast(msg: 'You may be offline');
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        Map<String,dynamic> jsonResponse = jsonDecode(response.body);
        String accessToken = jsonResponse['access_token'];
        return accessToken;
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode occurred during token request');
      }
    } else {
      Fluttertoast.showToast(msg: 'Auth service not reachable');
    }
    return null;
  }

  Future<List<PointLatLng>> getRoutePointsBetween(LatLng source, LatLng dest) async{
    return await PolylinePoints().getRouteBetweenCoordinates(googleMapsApiKey, source.latitude, source.longitude, dest.latitude, dest.longitude);
  }