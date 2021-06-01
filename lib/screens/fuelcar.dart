import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:dropdownfield/dropdownfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:my_fuel_flutter_app/database/AppDB.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/DealerModels.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/models/VehicleModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix1;
import 'package:progress_dialog/progress_dialog.dart';

class FuelCarPage extends StatefulWidget {

  @override
  _FuelCarPageState createState() => _FuelCarPageState();

}

class _FuelCarPageState extends State<FuelCarPage> {

  Vehicle _vehicle;
  String _selectedVehicle;
  MobileDealer _dealer;
  String _selectedDealer;
  BuildContext _context;
  SessionPrefs sessionPrefs;
  MobileUser _loggedInUser;
  List<MobileDealer> _dealers;
  List<String> _dealerNames;
  List<Vehicle> _vehiclesForUser;
  List<String> _vehicleRegs;
  double _accountBalance;
  int _pointsBalance;
  final _amountController = TextEditingController();
  final _mileageController = TextEditingController();
  final _pinController = TextEditingController();
  final _fcformKey = GlobalKey<FormState>();
  ProgressDialog _progressDialog;
  bool _validated = true;
  bool _transactionSuccess = false;
  bool _ratingBarShown = false;
  bool _passwordVisible = true;
  double _rating;

  @override
  void initState(){
    super.initState();
    List<Vehicle> vehicles = [];
    List<String> vehicleRegs = [];
    List<MobileDealer> mobileDealers = [];
    List<String> dealerNames = [];
    double account;
    int points;
    SessionPrefs().getLoggedInUser().then((user){
      List<int> selectionArgs = [user.id];
      AppDB.appDB.findAll(dealer).then((dealers){
        for(var i = 0; i < dealers.length; i++){
          Map<String,dynamic> row = dealers[i];
          MobileDealer mobileDealer = MobileDealer.empty();
          mobileDealer.id = row[id];
          mobileDealer.name = row[name];
          mobileDealer.userrating = row[rating];
          mobileDealer.stationid = row[stationId];
          mobileDealer.latitude = row[latitude];
          mobileDealer.longitude = row[longitude];
          mobileDealers.add(mobileDealer);
          print(mobileDealer.toString());
          dealerNames.add(mobileDealer.toString());
        }
      });
      AppDB.appDB.findByQuery('SELECT * FROM $tbVehicle WHERE $keyUser = ? AND $active = 1',selectionArgs).then((rows){
        for (var i = 0; i < rows.length; i++){
          Map <String,dynamic> obj = rows[i];
          Vehicle vehicle = Vehicle.empty();
          vehicle.id = obj[id];
          vehicle.regno = obj[regNo];
          vehicle.make = obj[make];
          vehicle.makeid = obj[makeId];
          vehicle.active = obj[active] == 1;
          vehicle.modelid = obj[modelId];
          vehicle.CCs = obj[ccs];
          vehicle.enginetype = obj[engineType];
          vehicles.add(vehicle);
          vehicleRegs.add(vehicle.toString());
        }
        SessionPrefs().getBalances().then((balances){
          setState(() {
            _accountBalance = balances.account;
            _pointsBalance = balances.points;
          });
        });
        setState(() {
          _dealerNames = dealerNames;
          _vehicleRegs = vehicleRegs;
          _dealers = mobileDealers;
          _loggedInUser = user;
          _vehiclesForUser = vehicles;
        });
      });
    });
  }

  @override
  void dispose(){
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Widget _ratingBar(prefix0.BuildContext bc){
    String dealerName = _dealer.name;
    return prefix0.SimpleDialog(
      children: <Widget>[
        prefix0.Padding(padding: prefix0.EdgeInsets.all(5.0),child: prefix0.Text('Would you like to rate this station $dealerName'),),
        RatingBar(onRatingUpdate: (rating){
          setState(() {
            _rating = rating;
          });
        },initialRating: 0,
            minRating: 1,
            direction: prefix0.Axis.horizontal,
            itemCount: 5,
            itemPadding: prefix0.EdgeInsets.all(5.0),
            itemBuilder: (context,_)=>prefix0.Icon(prefix0.Icons.star,color: prefix0.Colors.pink)),
        prefix0.Row(
          children: <Widget>[
            prefix0.Expanded(
              child: prefix0.FlatButton(onPressed: (){
                prefix0.Navigator.pop(bc);
              }, child: prefix0.Text('Maybe Later')),
            ),
            prefix0.Expanded(
              child: prefix0.FlatButton(onPressed: (){
                int dealerId = _dealer.id;
                String jsonBody = json.encode(DealerRating(
                    dealer: dealerId,
                    user: _loggedInUser.id,
                    rating: _rating
                ));
                Navigator.pop(bc);
                ProgressDialog pr = new ProgressDialog(_context);
                pr.style(message: 'Saving feedback ... ');
                pr.show();
                getTokenBasicAuth().then((token){
                  doRating(jsonBody,token).then((rating){
                    if (rating != null){
                      Map<String,dynamic> row = {id:dealerId,prefix1.rating:_rating};
                      AppDB.appDB.update(dealer, row);
                      pr.dismiss();
                      setState(() {
                        _dealer.userrating =_rating;
                      });
                      Fluttertoast.showToast(msg: 'Thanks for your feedback');
                      prefix0.Navigator.pop(_context);
                    }
                  });
                });
              }, child: prefix0.Text('Submit')),
            )
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context){
    _context = context;
    return WillPopScope(
      onWillPop: () async{
        if (_dealer != null){
          if (_dealer.userrating == null || _dealer.userrating == 0){
            if (_transactionSuccess){
              if (!_ratingBarShown){
                showDialog(context: context,builder: (BuildContext bc){
                  _ratingBarShown = true;
                  return _ratingBar(bc);
                });
              }
              return _ratingBarShown;
            }
          }
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Fuel My Car'),
          backgroundColor: Colors.amber,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              Card(
                child: Form(
                  key: _fcformKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text('Acc bal: $_accountBalance Kshs'),
                            Text('Pts bal $_pointsBalance')
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropDownField(
                          value: _selectedVehicle,
                          required: true,
                          strict: true,
                          labelText: 'Car to be fueled',
                          items: _vehicleRegs,
                          onValueChanged: (val){
                            Vehicle selected;
                            for (Vehicle v in _vehiclesForUser){
                              if (v.toString() == val){
                                selected = v;
                              }
                            }
                            setState(() {
                              _vehicle = selected;
                              _selectedVehicle = val;
                            });
                          },
                          setter: (dynamic newVal){
                            _selectedVehicle = newVal;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropDownField(
                          value: _selectedDealer,
                          required: true,
                          strict: true,
                          labelText: 'Station Id Number',
                          items: _dealerNames,
                          onValueChanged: (val){
                            MobileDealer mobileDealer;
                            for (MobileDealer md in _dealers){
                              if (md.toString() == val){
                                mobileDealer = md;
                              }
                            }
                            setState(() {
                              _dealer = mobileDealer;
                              _selectedDealer = val;
                            });
                          },
                          setter: (dynamic newVal){
                            _selectedDealer = newVal;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          validator: (value) {
                            if (value.isEmpty){
                              return 'Specify the amount to fuel';
                            } else {
                              double amt = double.parse(value);
                              if(amt > _accountBalance){
                                return 'The amount you specified exceeds your balance';
                              } else if(amt <= 0){
                                return 'Invalid amount specified';
                              }
                            }
                            return null;
                          },
                          controller: _amountController,
                          decoration: InputDecoration(
                            border: new OutlineInputBorder(
                                borderSide: new BorderSide(
                                    color: Colors.pink
                                )
                            ),
                            labelText: "Enter the amount to fuel",
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _mileageController,
                          decoration: prefix0.InputDecoration(
                            border: prefix0.OutlineInputBorder(
                              borderSide: prefix0.BorderSide()
                            ),
                            labelText: 'Current mileage',
                            hintText: '(Current odometer reading)'
                          ),
                          keyboardType: prefix0.TextInputType.number,
                          validator: (value){
                            if (value.isEmpty){
                              return 'Specify current mileage (odometer)';
                            } else {
                              int val = int.parse(value);
                              if (val < 0){
                                return 'invalid value entered';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          maxLength: 4,
                          controller: _pinController,
                          validator: (value) {
                            String message;
                            if (value.isEmpty){
                              return 'Enter your pin';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                              suffixIcon: IconButton(
                                  icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                                  onPressed: (){
                                    setState((){
                                      _passwordVisible ^= true;
                                    });
                                  }),
                              border: new OutlineInputBorder(
                                  borderSide: new BorderSide(color: Colors.pink)
                              ),
                              labelText: "Enter your Pin"
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: _passwordVisible,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
                child: ButtonTheme(
                  height: 50.0,
                  child: InkWell(
                    child: RaisedButton(
                      onPressed: _doFueling,
                      color: Colors.amber,
                      child: Text(
                        'Fuel Car',
                        style: TextStyle(
                            color: Colors.white
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _doFueling(){
    if (_fcformKey.currentState.validate()){
      String db = _amountController.text;
      var amount = double.parse(db);
      String carreg = _vehicle.regno;
      FuelCar fuelCar = FuelCar(
        user: _loggedInUser,
        vehicle: _vehicle,
        stationid: _dealer.stationid,
        mileage: int.parse(_mileageController.text),
        amount: double.parse(db),
      );
      showDialog(
        context: _context,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text('Confirm Transaction'),
            content: Text('Are you sure you want to fuel vehicle $carreg with fuel worth amount $amount Kshs'),
            actions: <Widget>[
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('No')),
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                    String json = jsonEncode(fuelCar);
                    _progressDialog = new ProgressDialog(
                        context,
                        isDismissible: false
                    );
                    _progressDialog.style(
                        message: 'Processing Transaction. Please wait ... ',
                        backgroundColor: Colors.white,
                        borderRadius: 10.0,
                        progressWidget: CircularProgressIndicator(),
                        elevation: 10.0,
                        insetAnimCurve: Curves.easeInOut
                    );
                    _progressDialog.show();
                    String pin = _pinController.text;
                    String encodedPin = base64.encode(utf8.encode(pin));
                    int id = _loggedInUser.id;
                    verifyPin(id, encodedPin).then((response){
                      if (response){
                        prefix1.getTokenBasicAuth().then((token){
                          makeRequest(json,token).then((success){
                            if(_progressDialog.isShowing()){
                              _progressDialog.dismiss();
                            }
                            if (success){
                              Fluttertoast.showToast(msg: 'Transaction completed successfully');
                              SessionPrefs().getBalances().then((balances){
                                setState((){
                                  _transactionSuccess = true;
                                  _accountBalance = balances.account;
                                  _pointsBalance = balances.points;
                                });
                              });
                              if (_dealer.userrating > 0){
                                Navigator.pop(_context);
                              } else {
                                prefix0.showDialog(
                                    context: _context,
                                    builder: (prefix0.BuildContext bc){
                                      return _ratingBar(bc);
                                    },
                                    barrierDismissible: false
                                  );
                              }
                            }
                          });
                        });
                      } else {
                        _progressDialog.dismiss();
                        Fluttertoast.showToast(msg: 'You entered a wrong pin',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                      }
                    });
                  },
                  child: Text('Yes'))
              ],
            );
          }
        );
    } else {
      Fluttertoast.showToast(msg: 'Check for errors in the inputs above',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
  }

  Future<bool> makeRequest(String fuelCar,String token) async{
    Response response;
    try{
      response = await post(baseUrlLocal+'fuelcar',body: fuelCar,headers: postHeaders(token));
    } catch (e) {
      if (e is SocketException){
        _progressDialog.dismiss();
        Fluttertoast.showToast(msg: 'Service is currently unreachable. You may be offline.',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      } else {
        print(e);
      }
    }
    bool success;
    Map<String,dynamic> jsonResponse;
    int statusCode = response.statusCode;
    if(statusCode == 200){
      jsonResponse = jsonDecode(response.body);
      FuelCar fuelCar = FuelCar.fromJson(jsonResponse);
      Balances balances = fuelCar.balances;
      SessionPrefs().setBalances(balances);
      success = true;
    } else{
      if (_progressDialog.isShowing()){
        _progressDialog.dismiss();
      }
      Fluttertoast.showToast(
          msg: 'Error $statusCode Occured',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM
      );
      success = false;
    }
    return success;
  }

  Future<bool> verifyPin(int id,String input) async {
    Response response;
    try{
      response = await get(baseUrlLocal+'verifypin/$id?encodedPin=$input');
    } catch (e){
      _progressDialog.dismiss();
      if (e is SocketException){
        Fluttertoast.showToast(msg: 'Service is unreachable. You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      } else {
        print(e);
      }
    }
    bool result;
    var jsonResponse;
    if (response != null){
      int statusCode = response.statusCode;
      if(statusCode == 200){
        jsonResponse = json.decode(response.body);
        result = jsonResponse as bool;
      } else {
        _progressDialog.dismiss();
        Fluttertoast.showToast(msg: 'Error $statusCode Occured',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      }
    } else {
      _progressDialog.dismiss();
    }
    return result;
  }

  bool _validate() {
    bool result = true;
    return result;
  }

}
