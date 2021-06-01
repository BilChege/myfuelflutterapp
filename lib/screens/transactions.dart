import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:my_fuel_flutter_app/database/AppDB.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/DealerModels.dart';
import 'package:my_fuel_flutter_app/models/PackageModels.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/models/VehicleModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix0;
import 'package:progress_dialog/progress_dialog.dart';

class Transactions extends StatefulWidget {
  @override
  _TransactionsState createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> with SingleTickerProviderStateMixin{

  List<FuelCar> _fcs;
  List<MobileSambaza> _mobileSambazas;
  ProgressDialog _dialog;
  MobileUser _loggedInUser;
  List<int> _selectedVehicles = new List();
  List<Vehicle> _vehicles = new List();
  List<String> _vehicleStrings = new List();
  String _selectedVehicle;
  MobileSambaza _selectedSambaza;
  TabController _tabController;
  String _messageForFuelTransactions = 'Loading ... ',_messageForSambazas = "Loading ... ";
  var _namesController = new TextEditingController();
  var _phoneController = new TextEditingController();
  var _emailController = new TextEditingController();
  var _amountController = new TextEditingController();
  var _dateController = new TextEditingController();
  List<Tab> _tabs = [
    Tab(text: 'Fuel Purchases'),
    Tab(text: 'Sambaza')
  ];
  List<SambazaOption> _sambazaOptions = [
    SambazaOption(title: 'Reverse Transaction')
  ];

  @override
  Widget build(BuildContext context){
    return WillPopScope(
      onWillPop: () async{
        if (_tabController.index == 1){
          if (_selectedSambaza != null){
            setState(() {
              _selectedSambaza = null;
            });
            return false;
          }
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('All Transactions'),
          bottom: TabBar(tabs: _tabs,controller: _tabController,onTap:(index){
            if (index == 0){
              setState((){
                _selectedSambaza = null;
              });
            }
          }),
          actions: <Widget>[
            Visibility(child: PopupMenuButton<SambazaOption>(itemBuilder: (BuildContext bc){
              return _sambazaOptions.map((option){
                return PopupMenuItem<SambazaOption>(child: Text(option.title),value: option);
              }).toList();
            },onSelected: (option){
              switch(option.title){
                case 'Reverse Transaction' : {
                  showDialog(context: context,builder: (BuildContext buildContext){
                    return AlertDialog(
                      title: Text('Reverse this Sambaza'),
                      content: Text('Are you sure you want to reverse this transaction? The amount sent to the recipient will be deducted and re-allocated to you.'),
                      actions: <Widget>[
                        FlatButton(onPressed: () => Navigator.pop(buildContext), child: Text('No')),
                        FlatButton(onPressed: (){
                          Navigator.pop(buildContext);
                          ProgressDialog dialog = new ProgressDialog(context);
                          dialog.style(message: 'Please wait ... ');
                          dialog.show();
                          getTokenBasicAuth().then((token){
                            reverseSambaza(_selectedSambaza.id, token).then((balances){
                              if (balances != null){
                                SessionPrefs().setBalances(balances);
                                Fluttertoast.showToast(msg: 'Reversal has been done successfully');
                                setState(() {
                                  _selectedSambaza = null;
                                });
                                dialog.update(message: 'Updating ... ');
                                getSambazasForUser(_loggedInUser.id,token).then((sambazas){
                                  dialog.dismiss();
                                  setState(() {
                                    _mobileSambazas = sambazas;
                                  });
                                });
                              }
                            });
                          });
                        }, child: Text('Yes'))
                      ],
                    );
                  });
                  break;
                }
              }
            }),visible: _selectedSambaza != null)
          ],
        ),
        body: TabBarView(children: [
          _fuelPurchaseBody(),
          _sambazasBody()
        ],controller: _tabController),
      ),
    );
  }

  @override
  void dispose(){
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState(){
    _tabController = TabController(length: _tabs.length, vsync: this);
    SessionPrefs().getLoggedInUser().then((user){
      getTokenBasicAuth().then((token){
        getSambazasForUser(user.id,token).then((sambazas){
          if (sambazas != null){
            if (sambazas.isNotEmpty){
              setState((){
                _mobileSambazas = sambazas;
              });
            } else {
              setState((){
                _messageForSambazas = "There were no sambaza transactions found";
              });
            }
          }
        });
        fetchAllTransactions(user.id,token).then((onValue){
          if (onValue.isNotEmpty){
            setState(() {
              _fcs = onValue;
            });
          } else {
            setState(() {
              _messageForFuelTransactions = 'There were no transactions found';
            });
          }
        });
      });
      setState(() {
        _loggedInUser = user;
      });
    });
    AppDB.appDB.findAll(tbVehicle).then((rows){
      for (Map row in rows){
        Vehicle v = Vehicle(
          id: row[id],
          regno: row[regNo],
          make: row[make]
        );
        setState(() {
          _vehicles.add(v);
          _vehicleStrings.add(v.toString());
        });
      }
    });
    super.initState();
  }

  Widget _fuelPurchaseBody(){
    Widget result;
    if (_fcs != null && _fcs.isNotEmpty){
      return ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: ExpansionTile(
              title: Text('Select to filter by vehicle'),
              children: _carCheckBoxes(),
            )
//            DropDownField(
//              labelText: 'Select to filter by vehicle',
//              value: _selectedVehicle,
//              items: _vehicleStrings,
//              onValueChanged: (value){
//                _vehicles.forEach((vehicle){
//                  if (vehicle.toString() == value){
//                    setState(() {
//                      _selectedVehicle = value;
//                      _vehicle = vehicle;
//                    });
//                  }
//                });
//              },
//              setter: (value){
//                setState(() {
//                  _selectedVehicle = value;
//                });
//              },
//            ),
          ),
          _results(),
        ],
      );
    }
    return Center(
        child: Text('$_messageForFuelTransactions'),
      );
  }

  _results(){
    if (_selectedVehicles.isNotEmpty){
      List<FuelCar> filtered = new List();
      _fcs.forEach((fc){
        Vehicle v = fc.vehicle;
        if (_selectedVehicles.contains(v.id)){
          filtered.add(fc);
        }
      });
      return new ListView.builder(
        itemBuilder: (context,i){
          FuelCar fc = filtered[i];
          String regNo = fc.vehicle.regno;
          String station = fc.stationid;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Fueled vehicle $regNo'),
              subtitle: Text('At Station $station'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionDetails(fc))),
            ),
          );
        },
        itemCount: filtered.length,
        shrinkWrap: true,
      );
    }
    return new ListView.builder(
        shrinkWrap: true,
        itemCount: _fcs.length,
        itemBuilder: (context,i){
          FuelCar fc = _fcs[i];
          String regNo = fc.vehicle.regno;
          String station = fc.stationid;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Fueled vehicle $regNo'),
              subtitle: Text('At Station $station'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionDetails(fc))),
            ),
          );
        }
    );
  }

  _sambazasBody() {
    if (_selectedSambaza != null){
      MobileUser mobileUser = _selectedSambaza.userSentTo;
      _namesController.text = mobileUser.firstName+' '+mobileUser.lastName;
      _phoneController.text = mobileUser.phone;
      _emailController.text = mobileUser.email;
      _amountController.text = _selectedSambaza.amountSent.toString();
      _dateController.text = _selectedSambaza.dateSent;
      return ListView(
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.all(10.0),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TextField(
              controller: _namesController,
              enabled: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide()
                ),
                labelText: 'Sent to'
              ),
            ),
          ),
          TextField(
            controller: _phoneController,
            enabled: false,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Phone Number'
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TextField(
              controller: _emailController,
              enabled: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email Address'
              ),
            ),
          ),
          TextField(
            controller: _amountController,
            enabled: false,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Amount Sent'
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TextField(
              controller: _dateController,
              enabled: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Date Sent'
              ),
            ),
          )
        ],
      );
    }
    if (_mobileSambazas != null){
      if (_mobileSambazas.isNotEmpty){
        return new ListView.builder(
          itemCount: _mobileSambazas.length,
          itemBuilder: (context,i){
            MobileSambaza ms = _mobileSambazas.elementAt(i);
            MobileUser sentTo = ms.userSentTo;
            return ListTile(
              title: Text('Sambaza made to '+sentTo.firstName+' '+sentTo.lastName),
              subtitle: Text('On '+ms.dateSent),
              onTap: (){
                setState(() {
                  _selectedSambaza = ms;
                });
              },
            );
          },
        );
      }
    }
    return Center(child: Text(_messageForSambazas));
  }

  Future<List<FuelCar>> fetchAllTransactions(int userId, String token) async{
    List<FuelCar> fuelCars;
    Response response;
    try{
      response = await get(baseUrlLocal+'usages/$userId',headers: getHeaders(token));
    } on SocketException catch(e){
      setState(() {
        _messageForFuelTransactions = 'Service is unreachable. You may be offline';
      });
    }
    int statusCode;
    var jsonResponse;
    if (response != null){
      statusCode = response.statusCode;
      if (statusCode == 200){
        jsonResponse = jsonDecode(response.body);
        var list = jsonResponse as List;
        fuelCars = list.map<FuelCar>((json)=> FuelCar.fromJson(json)).toList();
      } else {
        setState(() {
          _messageForFuelTransactions = 'An error occured while fetching data';
        });
        Fluttertoast.showToast(
            msg: 'Error $statusCode Occured',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM
        );
      }
    } else {
      setState(() {
        _messageForFuelTransactions = 'There was no response from the server';
      });
      Fluttertoast.showToast(
          msg: 'Server is unreachable',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM
      );
    }
    return fuelCars;
  }

  Future<List<MobileSambaza>> getSambazasForUser(int userId,String token) async{
    Response response;
    try{
      response = await get(baseUrlLocal+'sambazasbyuser/$userId',headers: getHeaders(token));
    } on SocketException{
      setState(() {
        _messageForSambazas = "You may be offline";
      });
      Fluttertoast.showToast(msg: 'You may be offline');
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        var jsonResponse = json.decode(response.body);
        var list = jsonResponse as List;
        return list.map((json) => MobileSambaza.fromJson(json)).toList();
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode occurred while fetching sambazas');
      }
    } else {
      setState(() {
        _messageForSambazas = "There was no response from the server";
      });
      Fluttertoast.showToast(msg: 'No response from the server');
    }
    return null;
  }

  Future<Balances> reverseSambaza(int id, String token) async{
    Response response;
    try{
      response = await put(baseUrlLocal+'reverseSambaza/$id?access_token=$token');
    } on SocketException{
      Fluttertoast.showToast(msg: 'You may be offline');
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        var jsonResponse = json.decode(response.body);
        return Balances.fromJson(jsonResponse);
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode occured');
      }
    } else {
      Fluttertoast.showToast(msg: 'No response from the service');
    }
    return null;
  }

  _carCheckBoxes(){
    List<Widget> children = new List();
    for (Vehicle v in _vehicles){
      String reg = v.toString();
      children.add(Row(
        children: <Widget>[
          Text(reg),
          Checkbox(value: _selectedVehicles.contains(v.id), onChanged: (selected){
            if (selected){
              setState(() {
                _selectedVehicles.add(v.id);
              });
            } else {
              setState(() {
                _selectedVehicles.remove(v.id);
              });
            }
          })
        ],
      ));
    }
    return children;
  }
}

class TransactionDetails extends StatefulWidget {

  FuelCar _fuelCar;

  TransactionDetails(this._fuelCar);

  @override
  _TransactionDetailsState createState() => _TransactionDetailsState(_fuelCar);
}

enum Satisfaction { happy , unhappy }

class _TransactionDetailsState extends State<TransactionDetails>{
  var _amountController = new TextEditingController();
  var _dateController = new TextEditingController();
  var _stationController = new TextEditingController();
  var _vehicleController = new TextEditingController();
  var _reviewController = new TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Satisfaction _cleanBrightStation, _everythingWorks, _greatExperience, _quickAndEasy;
  String _generalSatisfaction;
  int _generalSatisfactionVal;
  DealerRating _dealerRating;
  FuelCar _transaction;
  MobileUser _loggedInUser;
  BuildContext _context;
  double _rating = 0;
  ProgressDialog _dialog;
  MobileDealer _dealer;
  List<Choice> _choices =  <Choice>[
     Choice(title: 'Rate this station',iconData: Icons.star)
  ];

  _TransactionDetailsState(this._transaction);

  @override
  Widget build(BuildContext context){
    _context = context;
    FuelCar fuelCar = widget._fuelCar;
    String station = fuelCar.stationid.split(' ').elementAt(0);
    double ratingValue;
    if (_dealer != null){
      ratingValue = _dealer.userrating;
    }
    _dialog = new ProgressDialog(context,isDismissible: false);
    return Scaffold(
      appBar: AppBar(
        title: Text('Service at $station'),
        actions: <Widget>[
//          PopupMenuButton<Choice>(
//          onSelected: (choice){
//            switch (choice.title){
//              case 'Rate this station': {
//                showDialog(context: _context, builder: (BuildContext bc){
//                  return SimpleDialog(
//                    children: <Widget>[
//                      Padding(
//                        padding: const EdgeInsets.all(8.0),
//                        child: Text(ratingValue != null && ratingValue > 0 ? 'You may change your rating from the previous one' :'Please give a rating of this fuel station based on the service you were provided.'),
//                      ),
//                      RatingBar(
//                        initialRating: ratingValue != null && ratingValue > 0? ratingValue : 0,
//                        minRating: 1,
//                        direction: Axis.horizontal,
//                        allowHalfRating: true,
//                        itemCount: 5,
//                        itemPadding: EdgeInsets.all(5.0),
//                        itemBuilder: (context,_)=>Icon(Icons.star,color: Colors.pink,),
//                        onRatingUpdate: (rating){
//                          setState(() {
//                            _rating = rating;
//                          });
//                        },
//                      ),
//                      Row(
//                        children: <Widget>[
//                          Expanded(child: FlatButton(onPressed: (){
//                            Navigator.pop(bc);
//                          }, child: Text('Maybe Later'))),
//                          Expanded(child: FlatButton(onPressed: (){
//
//                          }, child: Text('Submit')))
//                        ],
//                      )
//                    ],
//                  );
//                });
//              }
//            }
//          }
//          ,itemBuilder: (BuildContext bc){
//            return _choices.map((Choice choice){
//              return PopupMenuItem<Choice>(child: Text(choice.title),value: choice);
//            }).toList();
//          })
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0,horizontal: 20.0),
              child: TextField(
                enabled: false,
                controller: _amountController,
                decoration: new InputDecoration(
                  border: new OutlineInputBorder(
                    borderSide: new BorderSide(color: Colors.pink)
                  ),
                  labelText: 'Amount'
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                enabled: false,
                controller: _dateController,
                decoration: new InputDecoration(
                  border: new OutlineInputBorder(
                    borderSide: new BorderSide(color: Colors.pink)
                  ),
                  labelText: 'Date of Transaction'
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0,vertical: 10.0),
              child: TextField(
                enabled: false,
                controller: _stationController,
                decoration: new InputDecoration(
                  border: new OutlineInputBorder(
                    borderSide: new BorderSide(
                      color: Colors.pink
                    ),
                  ),
                  labelText: 'Station'
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _vehicleController,
                enabled: false,
                decoration: new InputDecoration(
                  border: new OutlineInputBorder(
                    borderSide: new BorderSide(color: Colors.pink)
                  ),
                  labelText: 'Car Fueled'
                ),
              ),
            ),
            _ratingBody(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ButtonTheme(
                height: 50.0,
                child: RaisedButton(
                  onPressed: (){
                    if (_validate()){
                      int dealerId = _dealer.id;
                      String jsonBody = json.encode(DealerRating(
                          dealer: dealerId,
                          user: _loggedInUser.id,
                          rating: _rating,
                          areaToImprove: _reviewController.text,
                          generalSatisfactionVal: _generalSatisfactionVal,
                          cleanBrightStation: _cleanBrightStation == Satisfaction.happy ? 'happy' : 'unhappy',
                          overallSatisfaction: _generalSatisfaction,
                          everythingWorks: _everythingWorks == Satisfaction.happy ? 'happy' : 'unhappy',
                          greatExperience: _greatExperience == Satisfaction.happy ? 'happy' : 'unhappy',
                          quickAndEasy: _quickAndEasy == Satisfaction.happy ? 'happy' : 'unhappy'
                      ));
                      ProgressDialog pr = new ProgressDialog(_context);
                      pr.style(message: 'Saving feedback ... ');
                      pr.show();
                      getTokenBasicAuth().then((token){
                        doRating(jsonBody,token).then((ratingVal){
                          pr.dismiss();
                          print('Will pop now');
                          Fluttertoast.showToast(msg: 'Feedback saved successfully');
                          Navigator.pop(_context);
                        });
                      });
                    } else {
                      Fluttertoast.showToast(msg: 'Check your inputs above');
                    }
                  },
                  child: Text('Post your Review'),
                  color: Colors.amber,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _doReview(FuelCar fuelCar){
    if (_formKey.currentState.validate()){
      String json = jsonEncode(fuelCar);
      _dialog.style(
          message: 'Sending review ... ',
          progressWidget: CircularProgressIndicator(),
          elevation: 10.0,
          insetAnimCurve: Curves.easeInOut
      );
      _dialog.show();
      getTokenBasicAuth().then((token){
        writeReview(json,token).then((onValue){
          _dialog.dismiss();
          if (onValue){
            Fluttertoast.showToast(
                msg: 'Thanks for your feedback',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM
            );
            Navigator.pop(_context);
          }
        });
      });
    }
  }

  Future<bool> writeReview(String review,String token) async{
    Response response = await put(baseUrlLocal+'userfeedback',headers: postHeaders(token),body: review);
    bool result;
    var jsonResponse;
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        result = true;
      } else {
        _dialog.dismiss();
        Fluttertoast.showToast(
          msg: null,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM
        );
      }
    } else {
      _dialog.dismiss();
      Fluttertoast.showToast(
        msg: 'Server is unreachable',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM
      );
    }
    return result;
  }


  @override
  void initState(){
    DateFormat format = new DateFormat('yyyy-MM-dd HH:mm:ss');
    String stationIdVal = _transaction.stationid.split(' ').elementAt(0);
    List<String> selectionArgs = [stationIdVal];
    AppDB.appDB.findByQuery('select * from $dealer where $stationId = ?', selectionArgs).then((list){
      Map<String,dynamic> row = list.elementAt(0);
      setState(() {
        _dealer = MobileDealer(
          id: row[id],
          name: row[name],
          userrating: row[rating]
        );
      });
    });
    SessionPrefs().getLoggedInUser().then((user){
      setState(() {
        _loggedInUser = user;
      });
    });
    setState(() {
      _amountController.text = _transaction.amount.toString();
      _dateController.text = _transaction.dateFueled;
      _stationController.text = _transaction.stationid;
      _vehicleController.text = _transaction.vehicle.regno;
    });
    prefix0.getTokenBasicAuth().then((token){
      getRating(_loggedInUser.id, _dealer.id,token).then((rating){
        if (rating != null){
          setState(() {
            _dealerRating = rating;
          });
          if (rating.id > 0){
            setState(() {
              _generalSatisfaction = rating.overallSatisfaction;
              _cleanBrightStation = rating.cleanBrightStation == 'happy' ? Satisfaction.happy : Satisfaction.unhappy;
              _everythingWorks = rating.everythingWorks == 'happy' ? Satisfaction.happy : Satisfaction.unhappy;
              _greatExperience = rating.greatExperience == 'happy' ? Satisfaction.happy : Satisfaction.unhappy;
              _quickAndEasy = rating.quickAndEasy == 'happy' ? Satisfaction.happy : Satisfaction.unhappy;
            });
          }
        }
      });
    });
    super.initState();
  }

  Future<DealerRating> getRating(int userId, int dealerId, String token) async{
    String userIdVal = userId.toString();
    String dealerIdVal = dealerId.toString();
    Response response;
    try{
      response = await get(prefix0.baseUrlLocal+'/getrating?userid=$userIdVal&dealerid=$dealerIdVal',headers: prefix0.getHeaders(token));
    } on SocketException {
      Fluttertoast.showToast(msg: 'You may be offline');
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        var jsonResponse = json.decode(response.body);
        return DealerRating.fromJson(jsonResponse);
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode occurred while fetching rating data');
      }
    }
    return null;
  }

  _ratingBody() {
    if (_dealerRating != null){
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20.0),
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('Specify your overall satisfaction'),
                  Visibility(child: Text('Please give sentiment',style: TextStyle(color: Colors.red),),visible: _generalSatisfaction == null),
                  RatingBar(
                    initialRating: _dealerRating != null ? _dealerRating.generalSatisfactionVal.toDouble() : 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 3,
                    itemPadding: EdgeInsets.all(5.0),
                    itemBuilder: (context,indx){
                      Widget result;
                      switch (indx){
                        case 0 : {
                          result = Icon(
                            Icons.sentiment_dissatisfied,
                            color: Colors.red,
                          );
                          break;
                        }
                        case 1 : {
                          result = Icon(Icons.sentiment_neutral,color: Colors.amber,);
                          break;
                        }
                        case 2 : {
                          result = Icon(Icons.sentiment_satisfied,color: Colors.greenAccent,);
                          break;
                        }
                      }
                      return result;
                    }
                    ,
                    onRatingUpdate: (rating){
                      int val = rating.round();
                      setState(() {
                        _generalSatisfactionVal = val;
                      });
                      switch (val){
                        case 1 : {
                          setState(() {
                            _generalSatisfaction = 'unhappy';
                          });
                          break;
                        }
                        case 2 : {
                          setState(() {
                            _generalSatisfaction = 'neutral';
                          });
                          break;
                        }
                        case 3 : {
                          setState(() {
                            _generalSatisfaction = 'happy';
                          });
                        }
                      }
                    },
                  ),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10.0),child: Text(_generalSatisfaction != null ? _generalSatisfaction : "",style: TextStyle(color: Colors.grey)))
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              children: <Widget>[
                Text('Areas you are happy with'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    color: Colors.black12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Clean and bright station'),
                        Visibility(child: Text('Please give sentiment',style: TextStyle(color: Colors.red),),visible: _cleanBrightStation == null),
                        Row(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Radio(value: Satisfaction.happy, groupValue: _cleanBrightStation, onChanged: (satisfaction){
                                  setState((){
                                    _cleanBrightStation = satisfaction;
                                  });
                                },activeColor: Colors.orange,),
                                Text('Happy')
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Radio(value: Satisfaction.unhappy, groupValue: _cleanBrightStation, onChanged: (satisfaction){
                                  setState(() {
                                    _cleanBrightStation = satisfaction;
                                  });
                                },activeColor: Colors.orange,),
                                Text('Unhappy')
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    color: Colors.black12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Everything works'),
                        Visibility(child: Text('Please give sentiment',style: TextStyle(color: Colors.red),),visible: _everythingWorks == null),
                        Row(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Radio(value: Satisfaction.happy, groupValue: _everythingWorks, onChanged: (satisfaction){
                                  setState(() {
                                    _everythingWorks = satisfaction;
                                  });
                                },activeColor: Colors.orange,),
                                Text('Happy')
                              ],
                            ),
                            Row(
                              children: <Widget>[
                                Radio(value: Satisfaction.unhappy, groupValue: _everythingWorks, onChanged: (satisfaction){
                                  setState(() {
                                    _everythingWorks = satisfaction;
                                  });
                                },activeColor: Colors.orange,),
                                Text('Unhappy')
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  color: Colors.black12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Great Experience'),
                      Visibility(child: Text('Please give sentiment',style: TextStyle(color: Colors.red),),visible: _greatExperience == null),
                      Row(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Radio(value: Satisfaction.happy, groupValue: _greatExperience, onChanged: (satisfaction){
                                setState(() {
                                  _greatExperience = satisfaction;
                                });
                              },activeColor: Colors.orange,),
                              Text('happy')
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Radio(value: Satisfaction.unhappy, groupValue: _greatExperience, onChanged: (satisfaction){
                                setState(() {
                                  _greatExperience = satisfaction;
                                });
                              },activeColor: Colors.orange,),
                              Text('Unhappy')
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                  child: Container(
                    color: Colors.black12,
                    padding: EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Quick and Easy'),
                        Visibility(child: Text('Please give sentiment',style: TextStyle(color: Colors.red),),visible: _quickAndEasy == null),
                        Row(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Radio(value: Satisfaction.happy, groupValue: _quickAndEasy, onChanged: (satisfaction){
                                  setState(() {
                                    _quickAndEasy = satisfaction;
                                  });
                                },activeColor: Colors.orange,),
                                Text('Happy')
                              ],
                            ),
                            Row(
                              children:<Widget>[
                                Radio(value: Satisfaction.unhappy, groupValue: _quickAndEasy, onChanged: (satisfaction){
                                  setState(() {
                                    _quickAndEasy = satisfaction;
                                  });
                                },activeColor: Colors.orange,),
                                Text('Unhappy')
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0,vertical: 20.0),
            child: TextFormField(
              controller: _reviewController,
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 5,
              decoration: new InputDecoration(
                  border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                  ),
                  labelText: 'Recommendations',
                  hintText: 'Please share your recommendations on areas to be improved'
              ),
            ),
          )
        ],
      );
    }
    else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          )
        ],
      );
    }
  }

  bool _validate() {
    if (_generalSatisfaction == null){
      return false;
    }
    if (_everythingWorks == null){
      return false;
    }
    if (_greatExperience == null){
      return false;
    }
    if (_quickAndEasy == null){
      return false;
    }
    return true;
  }
}

class Choice{
  String title;
  IconData iconData;

  Choice({this.title, this.iconData});
}

class SambazaOption{
  String title;
  IconData iconData;

  SambazaOption({this.title, this.iconData});
}



