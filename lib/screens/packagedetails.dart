import 'dart:convert';
import 'dart:io';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/MpesaModels.dart';
import 'package:my_fuel_flutter_app/models/PackageModels.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:progress_dialog/progress_dialog.dart';

// ignore: must_be_immutable
class PackageDetails extends StatefulWidget {

  FuelPackage _package;
  PackageDetails(this._package);

  @override
  _PackageDetailsState createState() => _PackageDetailsState();
}

class _PackageDetailsState extends State<PackageDetails> with WidgetsBindingObserver{

  FuelPackage _fuelPackage;
  PromoCode _promoCode;
  BuildContext _context;
  MobileUser _loggedInUser;
  ProgressDialog _dialog;
  StkPushRequestSuccess _stkPushRequestSuccess;
  bool _waiting = false, _applyPromoCode = false;
  TextEditingController _codeController;
  final codeValidate = GlobalKey<FormState>();
  List<PackageOption> _packageOptions = [];

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    setState(() {
      _fuelPackage = widget._package;
    });
    SessionPrefs().getLoggedInUser().then((user){
      setState(() {
        _loggedInUser = user;
      });
    });
    _codeController = new TextEditingController();
    _packageOptions.add(PackageOption(
      title: 'Apply Promo Code'
    ));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    double amt = _fuelPackage.priceOfPackage;
    double cashAmt;
    if (_promoCode != null){
      double _percentageDiscount = _promoCode.percentageDiscount;
      double discount = (_percentageDiscount/100) * amt;
      cashAmt = amt - discount;
    } else {
      cashAmt = amt;
    }
    int amount = cashAmt.ceil();
    DateFormat dateFormat = new DateFormat('yyyy-MM-dd HH:mm:ss');
    DateTime now = new DateTime.now();
    String curr = dateFormat.format(now);
    DateTime expiry = now.add(Duration(days: _fuelPackage.expiryDays));
    String expDate = dateFormat.format(expiry);
    return WillPopScope(
      onWillPop: () async => !_waiting,
      child: Scaffold(
        appBar: AppBar(title: Text('Package details'),actions: <Widget>[
          PopupMenuButton<PackageOption>(itemBuilder: (bc){
            return _packageOptions.map((option){
              return PopupMenuItem<PackageOption>(child: Text(option.title),value: option);
            }).toList();
          },onSelected: (option){
            switch (option.title){
              case 'Apply Promo Code' : {
                if (_promoCode != null){
                  Fluttertoast.showToast(msg: 'You have already applied discount for this purchase');
                } else {
                  setState(() {
                    _applyPromoCode = true;
                  });
                }
                break;
              }
            }
          })
        ],),
        body: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 0.0),
              child: Text('Fuel worth amount: $amt Kshs',style: TextStyle(fontSize: 20.0)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 0.0),
              child: Text('Cash price (Amount Kshs): $cashAmt Kshs',style: TextStyle(fontSize: 20.0,color: _promoCode != null ? Colors.green : Colors.black)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 0.0),
              child: Text('Date of purchase: $curr',style: TextStyle(fontSize: 20.0)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 10.0, 0.0, 0.0),
              child: Text('Expiry Date: $expDate',style: TextStyle(fontSize: 20.0)),
            ),
            Visibility(
              visible: _applyPromoCode,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: <Widget>[
                  Expanded(
                    child: Form(
                      key: codeValidate,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide()
                            ),
                            labelText: 'Enter the code here'
                          ),
                          validator: (code){
                            if (code.isEmpty){
                              return 'Please Enter the code first';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),
                  RaisedButton(onPressed: (){
                    if (codeValidate.currentState.validate()){
                      String code = _codeController.text;
                      ProgressDialog d = new ProgressDialog(_context);
                      d.style(message: 'Checking code ... ');
                      d.show();
                      getTokenBasicAuth().then((token){
                        getPromoCode(_loggedInUser.id, code, token).then((promoCode){
                          d.dismiss();
                          setState(() {
                            _promoCode = promoCode;
                            _applyPromoCode = false;
                          });
                        });
                      });
                    }
                  },child: Text('Apply Code'),)
                ],),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 30.0,10.0, 0.0),
              child: ButtonTheme(
                height: 50.0,
                child: RaisedButton(onPressed: (){
                  SessionPrefs().getLoggedInUser().then((user){
                    Purchase purchase = Purchase(
                        user: user,
                        aPackage: _fuelPackage,
                        datePurchased: curr,
                        expiryDate: expDate
                    );
                    SessionPrefs().purchaseToBeMade(purchase);
                    int pts = _fuelPackage.points;
                    String jsonPurchase = jsonEncode(purchase);
                    print('________________#########################________________________ DATA TO BE SENT '+jsonPurchase);
                    showDialog(
                        context: _context,
                        builder: (BuildContext context){
                          return AlertDialog(
                            title: Text('Confirm purchase:'),
                            content: Text('Amount: $amt Ksh\nPoints Awarded: $pts\nBuy Package?'),
                            actions: <Widget>[
                              FlatButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('No')),
                              FlatButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    String timeStamp = generateTimeStamp();
                                    StkPushRequest spr = StkPushRequest(
                                        BusinessShortCode: businessShortCode,
                                        Password: generateMpesaPassword(timeStamp),
                                        Timestamp: timeStamp,
                                        TransactionType: transactionTypeValue,
                                        Amount: amount.toString(),
                                        AccountReference: accountReferenceValue,
                                        CallBackURL: callBackUrlValue,
                                        PartyA: '254'+_loggedInUser.phone,
                                        PartyB: businessShortCode,
                                        PhoneNumber: '254'+_loggedInUser.phone,
                                        TransactionDesc: 'Payment for MyFuel App Package'
                                    );
                                    String jsonStk = json.encode(spr);
                                    print(spr);
                                    _dialog = new ProgressDialog(context);
                                    _dialog.style(
                                        message: 'Please wait ... ',
                                        backgroundColor: Colors.white,
                                        borderRadius: 10.0,
                                        progressWidget: CircularProgressIndicator(),
                                        elevation: 10.0
                                    );
                                    _dialog.show();
                                    String authRecipe = consumer_key+':'+consumer_secret;
                                    String authString = base64Encode(utf8.encode(authRecipe));
                                    requestToken(authString).then((token){
                                      requestPush(jsonStk,token).then((requestSuccess){
                                        setState(() {
                                          _stkPushRequestSuccess = requestSuccess;
                                        });
                                      });
                                    });
                                  },
                                  child: Text('Yes'))
                            ],
                          );
                        }
                    );
                  });
                }, child: Text('Make Purchase'),color: Colors.amber),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<PromoCode> getPromoCode(int userId,String code, String token) async{
    Response response;
    try{
      response = await get(baseUrlLocal+'checkpromocode/$userId?code=$code',headers: getHeaders(token));
    } on SocketException{
      Fluttertoast.showToast(msg: 'You may be offline.');
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        var jsonResponse = json.decode(response.body);
        return PromoCode.fromJson(jsonResponse);
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode Occured while checking code');
      }
    } else {
      Fluttertoast.showToast(msg: 'There was no response from the server');
    }
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    String timestamp = generateTimeStamp();
    String passWord = generateMpesaPassword(timestamp);
    StkTransactionStatusQuery stkTransactionStatusQuery = StkTransactionStatusQuery(
        Timestamp: timestamp,
        Password: passWord,
        CheckoutRequestID: _stkPushRequestSuccess.CheckoutRequestID,
        BusinessShortCode: businessShortCode
    );
    String jsonQr = json.encode(stkTransactionStatusQuery);
    if (state == AppLifecycleState.resumed){
      Fluttertoast.showToast(msg: 'Confirming payment ... ',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      setState(() {
        _waiting = true;
      });
      String authRecipe = consumer_key+':'+consumer_secret;
      String authString = base64Encode(utf8.encode(authRecipe));
      requestToken(authString).then((token){
        queryTransactionStatus(jsonQr, token).then((statusQuerySuccess){
          setState(() {
            _waiting = false;
          });
          int code = int.parse(statusQuerySuccess.ResultCode);
          switch(code){
            case 0: {
              SessionPrefs().getPurchaseToBeMade().then((purchase){
                DateFormat format = new DateFormat('yyyy-MM-dd HH:mm:ss');
                DateTime current = new DateTime.now();
                DateTime expiryDate = current.add(Duration(days: _fuelPackage.expiryDays));
                String expDate = formatDate(expiryDate, [yyyy,'/',MM,'/',dd]);
                double price = _fuelPackage.priceOfPackage;
                int pts = _fuelPackage.points;
                ProgressDialog dialog2 = new ProgressDialog(_context,isDismissible: false);
                dialog2.style(message: 'Making purchase ... ');
                dialog2.show();
                String jsonPur = json.encode(purchase);
                String promoId = _promoCode.id.toString();
                getTokenBasicAuth().then((token){
                  buyPackage(jsonPur,token,promoId).then((onValue){
                    if(onValue){
                      dialog2.dismiss();
                      showDialog(
                          context: _context,
                          builder: (BuildContext context){
                            return AlertDialog(
                              title: Text('Purchase Successful'),
                              content: Text('You have successfully purchased a prepay package for fuel worth $price Ksh. Points Awarded: $pts'),
                              actions: <Widget>[
                                FlatButton(
                                    onPressed: (){
                                      Navigator.pop(context);
                                      Navigator.pop(_context);
                                    },
                                    child: Text('Ok'))
                              ],
                            );
                          }
                      );//                          Navigator.pop(_context);
                    }
                  });
                });
              });
              break;
            }
            case 1: {
//              dialog1.dismiss();
              showDialog(
                  context: _context,
                  builder: (BuildContext context){
                    return AlertDialog(
                      title: Text('Purchase failed'),
                      content: Text('You do not have enough money in your mpesa to buy this package'),
                      actions: <Widget>[
                        FlatButton(onPressed: ()=> Navigator.pop(context), child: Text('Ok'))
                      ],
                    );
                  }
              );
              break;
            }
            case 2001: {
//              dialog1.dismiss();
              showDialog(
                  context: _context,
                  builder: (BuildContext context){
                    return AlertDialog(
                      title: Text('Purchase failed'),
                      content: Text('You have entered the wrong Mpesa Pin'),
                      actions: <Widget>[
                        FlatButton(onPressed: () => Navigator.pop(context), child: Text('Ok'))
                      ],
                    );
                  }
              );
              break;
            }
            case 1032: {
//              dialog1.dismiss();
              showDialog(
                  context: _context,
                  builder: (BuildContext context){
                    return AlertDialog(
                      title: Text('Purchase failed'),
                      content: Text('You cancelled the Mpesa transaction'),
                      actions: <Widget>[
                        FlatButton(onPressed: () => Navigator.pop(context), child: Text('Ok'))
                      ],
                    );
                  }
              );
              break;
            }
            default: {
//              dialog1.dismiss();
              showDialog(
                  context: _context,
                  builder: (BuildContext context){
                    return AlertDialog(
                      title: Text('Purchase Failed'),
                      content: Text('An error Occured during mpesa transaction. Please contact Support. Issue number $code'),
                      actions: <Widget>[
                        FlatButton(onPressed:() => Navigator.pop(context), child: Text('Ok'))
                      ],
                    );
                  }
              );
              break;
            }
          }
        });
      });

    } else if(state == AppLifecycleState.paused){
      Fluttertoast.showToast(msg: 'Pausing');
      _dialog.dismiss();
    }
  }

  Future<bool> buyPackage(String purchase,String token,String promoId) async{
    Response response;
    try{
      response = await post(baseUrlLocal+'makepurchase?promocode=$promoId',body: purchase,headers: postHeaders(token));
    } catch (e){
      if (e is SocketException){
        Fluttertoast.showToast(msg: 'Service is unreachable. You may be offline');
      }
    }
    bool success;
    var jsonResponse;
    if(response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        jsonResponse = jsonDecode(response.body);
        Purchase purchase = Purchase.fromJson(jsonResponse);
        Balances balances = purchase.balances;
        SessionPrefs().setBalances(balances);
        success = true;
      } else {
        Fluttertoast.showToast(
            msg: 'Error $statusCode Occured',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM
        );
        success = false;
      }
    } else {
      Fluttertoast.showToast(
          msg: 'The service is currently unreachable',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM
      );
    }
    return success;
  }

  Future<StkTransactionStatusQuerySuccess> queryTransactionStatus(String jsonString,String token) async{
    StkTransactionStatusQuerySuccess result;
    Map<String,String> mpesaHeader = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization':'Bearer $token'
    };
    Response response;
    try{
      response = await post(safaricomStkPushQuery+'query',body: jsonString,headers: mpesaHeader);
    } on SocketException catch(e){
      Fluttertoast.showToast(msg: 'You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      print(e);
    }
    var jsonResponse;
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        jsonResponse = json.decode(response.body);
        result = StkTransactionStatusQuerySuccess.fromJson(jsonResponse);
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode Occurred while checking the status of mpesa transaction');
      }
    } else {
      Fluttertoast.showToast(msg: 'No response from mpesa services');
    }
    return result;
  }

  Future<String> requestToken(String auth) async{
    String result;
    Map<String,String> safaricomAuthHeader = {
      'authorization':'Basic $auth',
      'cache-control':'no-cache'
    };
    Response response;
    Map<String,dynamic> json;
    try{
      response = await get(safaricomAuth+'?grant_type=client_credentials',headers: safaricomAuthHeader);
    } on SocketException catch(e){
      print(e);
      Fluttertoast.showToast(msg: 'Service is unreachable. You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    if (response != null){
      int statusCode = response.statusCode;
      if(statusCode == 200){
        json = jsonDecode(response.body);
        result = json['access_token'];
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode Occured while contacting safaricom auth service');
      }
    } else {
      Fluttertoast.showToast(msg: 'No response from safaricom Auth service',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    return result;
  }

  Future<StkPushRequestSuccess> requestPush(String jsonString,String token) async{
    StkPushRequestSuccess result;
    Response response;
    Map<String,String> mpesaHeader = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization':'Bearer $token'
    };
    try{
      response = await post(safaricomStkProcessRequest+'processrequest',headers: mpesaHeader,body: jsonString);
    } on SocketException catch (e){
      _dialog.dismiss();
      Fluttertoast.showToast(msg: 'Service is unreachable.You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      print(e);
    }
    var jsonResponse;
    if(response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        jsonResponse = json.decode(response.body);
        result = StkPushRequestSuccess.fromJson(jsonResponse);
      } else {
        _dialog.dismiss();
        Fluttertoast.showToast(msg: 'Error $statusCode Occured while contacting mpesa services',gravity: ToastGravity.BOTTOM,toastLength: Toast.LENGTH_SHORT);
        print(response.body);
      }
    } else {
      _dialog.dismiss();
      Fluttertoast.showToast(msg: 'no response from Mpesa services',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    return result;
  }

}

class PackageOption{
  String title;
  IconData iconData;

  PackageOption({this.title,this.iconData});
}
