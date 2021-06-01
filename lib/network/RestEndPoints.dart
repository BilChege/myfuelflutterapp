import 'package:chopper/chopper.dart';
import 'package:my_fuel_flutter_app/models/DealerModels.dart';
import 'package:my_fuel_flutter_app/models/MpesaModels.dart';
import 'package:my_fuel_flutter_app/models/PackageModels.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/models/VehicleModels.dart';

//const String baseUrlLocal = "http://192.168.0.108:8080/myFuelAPI/";
const String baseUrlLocalVd = "http://10.0.2.2:8080/myFuelAPI/";
const String baseUrlDemo = "http://172.104.147.162:8282/myFuelAPI/";

//@ChopperApi(baseUrl: baseUrlLocal)
abstract class NetClient extends ChopperService{

  @Post(path: 'signupmobileuser')
  Future<MobileUser> signUp(@Body() MobileUser user);

  @Post(path: 'verifyphone/{phone}')
  Future<String> verifyPhone(@Path('phone') String phone);

  @Get(path: 'allpackages')
  Future<List<FuelPackage>> allpackages();

  @Post(path: 'addvehicle')
  Future<Vehicle> addVehicle(@Body() Vehicle vehicle);

  @Post(path: 'makepurchase')
  Future<Purchase> buyBundle(@Body() Purchase purchase);

  @Header('Accept-Charset: utf-8')
  @Get(path: 'login/{email}')
  Future<MobileUser> loginUser (@Path('email') String email);

  @Post(path: 'fuelcar')
  Future<FuelCar> fuelMyCar(@Body() FuelCar fuelCar);

  @Put(path: 'updateuserdetails')
  Future<MobileUser> updateUser(@Body() MobileUser user);

  @Get(path: 'balancesfor/{id}')
  Future<Balances> getBalances (@Path('id') int id);

  @Get(path: 'usages/{userid}')
  Future<List<FuelCar>> usagesForUser(@Path('userid') int id);

  @Get(path: 'alloffers')
  Future<List<OffersForMobile>> allOffers();

  @Post(path: 'redeempointsforpromo')
  Future<Balances> redeemPointsForPromo(@Body() MobileRedemption mobileRedemption);

  @Get(path: 'allmakes')
  Future<List<VehicleMake>> allMakes();

  @Get(path: 'alldealers/{id}')
  Future<List<MobileDealer>> allDealers(@Path('id') int id);

  @Put(path: 'updatevehicle')
  Future<Vehicle> updateCar(@Body() Vehicle vehicle);

  @Get(path: 'verifyuser')
  Future<MobileUser> verifySystemUser(@Query('phone') String phone);

  @Post(path: 'sambaza')
  Future<Balances> sambazaPackage(@Query('sentfrom') String sentFrom,@Query('recipientphone') String recipientPhone,@Query('amount') String amount);

  @Put(path: 'userfeedback')
  Future<FuelCar> giveUserFeedBack(@Body() FuelCar fuelCar);

  @Post(path: 'processrequest')
  Future<StkPushRequestSuccess> promptUser(@Body()StkPushRequest stkPushRequest);

  @Post(path: 'query')
  Future<StkTransactionStatusQuerySuccess> confirmPayment(@Body() StkTransactionStatusQuery query);

  @Post(path: 'ratestation')
  Future<DealerRating> doRating(@Body() DealerRating dealerRating);


}

