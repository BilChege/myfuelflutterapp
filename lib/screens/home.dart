import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
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
import 'package:my_fuel_flutter_app/screens/buypackage.dart';
import 'package:my_fuel_flutter_app/screens/checkbalance.dart';
import 'package:my_fuel_flutter_app/screens/consumptionImproved.dart';
import 'package:my_fuel_flutter_app/screens/forgotpassword.dart';
import 'package:my_fuel_flutter_app/screens/fuelcar.dart';
import 'package:my_fuel_flutter_app/screens/managevehicles.dart';
import 'package:my_fuel_flutter_app/screens/maps.dart';
import 'package:my_fuel_flutter_app/screens/offers.dart';
import 'package:my_fuel_flutter_app/screens/plantrip.dart';
import 'package:my_fuel_flutter_app/screens/reports.dart';
import 'package:my_fuel_flutter_app/screens/settings.dart';
import 'package:my_fuel_flutter_app/screens/signup.dart';
import 'package:my_fuel_flutter_app/screens/transactions.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix1;
import 'package:progress_dialog/progress_dialog.dart';
import 'sambazaimproved.dart';

void main(){
  runApp(
      MyApp()
  );
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget{
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Fuel App',
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        primarySwatch: Colors.amber,
        accentColor: Colors.amberAccent,
        primaryColorDark: Colors.amber
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  const MyHomePage({Key key}) : super(key : key);

  @override
  State<StatefulWidget> createState() => _MyHomePageState();

}

class _MyHomePageState extends State<MyHomePage> with RouteAware{

  double _accountBalance;
  int _pointsBalance;
  BuildContext _context;
  MobileUser _user;
  String _message = "Loading ... ";
  bool _loggedIn;
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  var emailInputController = new TextEditingController();
  var passwordInputController = new TextEditingController();
  ProgressDialog _dialog;
  bool passwordVisible = true;
  double _rating;
  bool _corporateUser =false;
  bool _popUpForPinDone = false;
  bool _popUpForVehiclesDone = false;
  bool _noVehicles = false;
  bool _activationState = false;
  StreamSubscription _subscription;
  bool _connectionOn = true,_connectionPromptDone = false;
  List<HomeChoice> _homeChoices = [
    HomeChoice(title: 'Rate App'),
    HomeChoice(title: 'Settings')
  ];

  @override
  void initState(){
    super.initState();
    Connectivity().checkConnectivity().then((connectivityResult){
      if (connectivityResult == ConnectivityResult.none){
        setState(() {
          _connectionOn = false;
        });
      }
    });
    _subscription = Connectivity().onConnectivityChanged.listen((result){
      if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi){
        setState(() {
          _connectionOn = true;
        });
      }
    });
    SessionPrefs().getLoggedInStatus().then((status){
      if (status != null){
          if(status){
            SessionPrefs().getLoggedInUser().then((onValue){
              if (onValue != null){
                getTokenBasicAuth().then((token){
                  checkUser(onValue.email,token).then((user){
                    if(user.active){
                      setState(() {
                        _loggedIn = status;
                      });
                      if(onValue.role == corporateUserRole){
                        setState(() {
                          _corporateUser = true;
                        });
                      }
                      setState(() {
                        _user = onValue;
                      });
                      getBalances(onValue.id,token).then((balances){
                        if (balances != null){
                          SessionPrefs().setBalances(balances);
                          setState((){
                            _accountBalance = balances.account;
                            _pointsBalance = balances.points;
                          });
                        }
                      });
                      if (_corporateUser){
                        _updateCorporateUserVehicles(onValue.id, token, false);
                      }
                      AppDB.appDB.findAll(tbVehicle).then((vehicles){
                        if (vehicles == null || vehicles.isEmpty){
                          setState(() {
                            _noVehicles = true;
                          });
                        }
                      });
                      _updateDealerData(onValue.id,false);
                    } else {
                      setState(() {
                        _loggedIn = false;
                      });
                      SessionPrefs().setLoggedInStatus(false);
                    }
                  });
                });
              }
            });
          }
      } else {
        setState(() {
          _loggedIn = false;
        });
      }
    });
  }

  _updateDealerData(int userId,bool refresh){
    ProgressDialog progressDialog;
    if (refresh){
      progressDialog = new ProgressDialog(_context);
      progressDialog.style(message: 'Refreshing data ... ');
      progressDialog.show();
    }
    getTokenBasicAuth().then((token){
      allDealers(userId,token).then((dealers){
        print(' !!!!!!!!!!!!!!!! Fetched !!!!!!!!!!!!!!!! ');
        if (progressDialog != null){
          progressDialog.dismiss();
        }
        if (dealers != null && dealers.isNotEmpty){
          var fromServer = new List(dealers.length);
          int index = 0;
          for (MobileDealer d in dealers){
            print("Dealer data from network: "+d.toString());
            fromServer[index] = d.id;
            index += 1;
          }
          AppDB.appDB.findAll(dealer).then((mobileDealers){
            if (mobileDealers != null && mobileDealers.isNotEmpty){
              var fromMobile = new List(mobileDealers.length);
              int index = 0;
              for (Map<String,dynamic> d in mobileDealers){
                fromMobile[index] = d[id];
                index += 1;
              }
              for (var i = 0; i < fromServer.length; i++){
                if (!contains(fromMobile, fromServer[i])){
                  for (MobileDealer d in dealers){
                    if (d.id == fromServer[i]){
                      String s = d.toString();
                      print("To be saved ... $s");
                      Map row = new HashMap<String,dynamic>();
                      row[id] = d.id;
                      row[name] = d.name;
                      row[stationId] = d.stationid;
                      row[latitude] = d.latitude;
                      row[rating] = d.userrating;
                      row[longitude] = d.longitude;
                      AppDB.appDB.save(dealer, row);
                    }
                  }
                }
              }
            } else {
              for (MobileDealer d in dealers){
                Map row = new HashMap<String,dynamic>();
                row[id] = d.id;
                row[name] = d.name;
                row[stationId] = d.stationid;
                row[latitude] = d.latitude;
                row[rating] = d.userrating;
                row[longitude] = d.longitude;
                AppDB.appDB.save(dealer, row);
              }
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_connectionOn){
      if (!_connectionPromptDone){
        WidgetsBinding.instance.addPostFrameCallback((_){
          showDialog(context: context,builder: (BuildContext bc){
            return AlertDialog(
              title: Text('No Connection'),
              content: Text('Turn on mobile connection or wifi to access myFuel services'),
              actions: <Widget>[
                FlatButton(onPressed: (){
                  Navigator.pop(bc);
                }, child: Text('Ok'))
              ],
            );
          });
        });
        _connectionPromptDone = true;
      }
    }
    if(_loggedIn != null){
      if(_loggedIn){
        if(_corporateUser){
          if (_user.pin == null || _user.pin.isEmpty){
            if (!_popUpForPinDone){
              WidgetsBinding.instance.addPostFrameCallback((_){
                showModalBottomSheet(context: context, builder: (BuildContext bc){
                  return Container(
                    padding: EdgeInsets.all(10.0),
                    child: Wrap(
                      children: <Widget>[
                        Text('We have noticed that you are a corporate user and you have not set your MyFuel pin. You need to set a pin for transactions at the fueling station'),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: ListTile(title: Text('Set a pin'),onTap: (){
                            prefix0.Navigator.pop(bc);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => SetPin(toUpdate: true,)));
                          },),
                        )
                      ],
                    ),
                  );
                });
              });
              _popUpForPinDone = true;
            }
          }
        } else if (_noVehicles){
          if (!_popUpForVehiclesDone){
            WidgetsBinding.instance.addPostFrameCallback((_){
              showModalBottomSheet(context: context, builder: (BuildContext bc){
                return Container(
                  padding: EdgeInsets.all(10.0),
                  child: Wrap(
                    children: <Widget>[
                      Text('We have noticed that you are a new User and have not added any cars. Please add a car first'),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: ListTile(title: Text('Add a car'),onTap: (){
                          prefix0.Navigator.pop(bc);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CarDetails()));
                        },),
                      )
                    ],
                  ),
                );
              });
            });
            _popUpForVehiclesDone = true;
          }
        }
      }
    }
    _context = context;
    return toBeBuilt();
  }

  Widget toBeBuilt(){
    String firstName, lastName, email;
    if (_user != null){
      firstName = _user.firstName;
      lastName = _user.lastName;
      email = _user.email;
    }
    if(_loggedIn != null){
      if (_loggedIn){
        return WillPopScope(
          onWillPop: () async{
            exit(0);
            return true;
          },
          child: Scaffold(
            key: _scaffoldKey,
            resizeToAvoidBottomInset: false,
            resizeToAvoidBottomPadding: false,
            drawer: Visibility(
              visible: _connectionOn,
              child: new Drawer(
                child: ListView(
                  scrollDirection: Axis.vertical,
                  children: <Widget>[
                    Container(
                      child: DrawerHeader(
                        child: Column(
                          children: <Widget>[
                            Expanded(
                                child: Image(
                                    image: new AssetImage('images/shell.png')
                                )
                            ),
                            Text(
                              firstName != null && lastName != null ? '$firstName $lastName' : 'Please wait ... ',
                              style: TextStyle(
                                  color: Colors.white
                              ),
                            ),
                            Text(
                              email != null ? email : '',
                              style: TextStyle(
                                  color: Colors.white
                              ),
                            )
                          ],
                        ),
                      ),
                      color: Colors.amber,
                    ),
                    ListTile(
                      leading: Icon(Icons.directions_car),
                      title: Text(
                        'My Cars',
                        style: TextStyle(
                          color: Colors.black
                        ),
                      ),
                      onTap: (){
                        Navigator.of(context).pop();
                        Navigator.push(_context, MaterialPageRoute(builder: (context) => MyCars()));
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.airport_shuttle),
                      title: Text('Plan Trip',style: TextStyle(
                        color: Colors.black
                      )),
                      onTap: (){
                        Navigator.of(context).pop();
                        Navigator.push(_context, MaterialPageRoute(builder: (context)=> PlanTrip()));
                      },
                    ),
                    InkWell(
                      child: ListTile(
                        leading: Icon(Icons.compare_arrows),
                        title: Text(
                            'View Transactions',
                            style: TextStyle(
                                color: Colors.black
                            )
                        ),
                        onTap: (){
                          Navigator.of(context).pop();
                          Navigator.push(_context, MaterialPageRoute(builder: (context) => Transactions()));
                        },
                      ),
                    ),
                    InkWell(
                      child: ListTile(
                        leading: Icon(Icons.settings),
                        title: Text(
                          'Settings',
                          style: TextStyle(
                              color: Colors.black
                          ),
                        ),
                        onTap: (){
                          Navigator.of(context).pop();
                          Navigator.push(_context, MaterialPageRoute(builder: (context)=> Settings()));
                        },
                      ),
                    ),
                    InkWell(
                      child: ListTile(
                        leading: Icon(Icons.exit_to_app),
                        title: Text(
                          'Log out',
                          style: TextStyle(
                              color: Colors.black
                          ),
                        ),
                        onTap: (){
                          SessionPrefs().setLoggedInStatus(false);
                          AppDB.appDB.clearTable(tbVehicle);
                          setState((){
                            _loggedIn = false;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    InkWell(
                      child: ListTile(
                        leading: Icon(Icons.share),
                        title: Text(
                          'Share',
                          style: TextStyle(
                              color: Colors.black
                          ),
                        ),
                        onTap: (){
                          Navigator.of(context).pop();
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
            appBar: AppBar(
              title: Text(
                  'My Fuel App Home'
              ),
              backgroundColor: Colors.amber,
              actions: <Widget>[
                IconButton(icon: Icon(Icons.refresh), onPressed: (){
                  getTokenBasicAuth().then((token){
                    getBalances(_user.id, token).then((balances){
                      if (balances != null){
                        SessionPrefs().setBalances(balances);
                        double balance = balances.account;
                        int points = balances.points;
                        setState(() {
                          _accountBalance = balance;
                          _pointsBalance = points;
                        });
                      }
                    });
                    if (_user.role == corporateUserRole){
                      _updateCorporateUserVehicles(_user.id,token,true);
                    }
                  });
                  _updateDealerData(_user.id,true);
                }),
                PopupMenuButton<HomeChoice>(itemBuilder: (BuildContext bc){
                  return _homeChoices.map((choice){
                    return PopupMenuItem<HomeChoice>(child: Text(choice.title),value: choice);
                  }).toList();
                },onSelected:(choice){
                  double ratingValue = _user.rating;
                  switch(choice.title){
                    case 'Rate App' : {
                      showDialog(context: _context, builder: (BuildContext bc){
                        return SimpleDialog(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(ratingValue != null && ratingValue > 0 ? 'You may change your rating from the previous one' :'Please give a rating of this app.'),
                            ),
                            RatingBar(
                              initialRating: ratingValue != null && ratingValue > 0? ratingValue : 0,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemPadding: EdgeInsets.all(5.0),
                              itemBuilder: (context,_)=>Icon(Icons.star,color: Colors.pink,),
                              onRatingUpdate: (rating){
                                setState((){
                                  _rating = rating;
                                });
                              },
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(child: FlatButton(onPressed: (){
                                  Navigator.pop(bc);
                                }, child: Text('Maybe Later'))),
                                Expanded(child: FlatButton(onPressed: () async{
                                  Navigator.pop(bc);
                                  if (_rating != null && _rating > 0){
                                    _user.rating = _rating;
                                    _user.accountPassword = null;
                                    _user.pin = null;
                                    String jsonBody = json.encode(_user);
                                    ProgressDialog dialog = new ProgressDialog(_context);
                                    dialog.style(message: 'saving feedback ... ');
                                    dialog.show();
                                    getTokenBasicAuth().then((token){
                                      updateUser(jsonBody, token).then((updatedUser){
                                        dialog.dismiss();
                                        if (updatedUser != null && updatedUser.id > 0){
                                          SessionPrefs().setLoggedInUser(updatedUser);
                                          Fluttertoast.showToast(msg: 'Thanks for your feedback');
                                        }
                                      });
                                    });
                                  }
                                }, child: Text('Submit')))
                              ],
                            )
                          ],
                        );
                      });
                      break;
                    }
                    case 'Settings' : {
                      Navigator.push(_context, MaterialPageRoute(builder: (context) => Settings()));
                      break;
                    }
                  }
                })
              ],
            ),
            body: _homePageBody(),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text('My Fuel App Login'),
          backgroundColor: Colors.amber,
        ),
        body: _loginBody(),
      );
    }
    return Scaffold(
      body: Center(
        child: Image(
          image: new AssetImage('images/shell.png'),
          width: 500.0,
          height: 500.0,
        ),
      ),
    );
  }

  _loginBody(){
    if (_connectionOn){
      return WillPopScope(
        onWillPop: () async{
          exit(0);
          return true;
        },
        child: Builder(
          builder: (context) => Container(
            padding: EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Center(
                child: ListView(
                  scrollDirection: Axis.vertical,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                      child: Image(
                        image: new AssetImage('images/shell.png'),
                        width: 500.0,
                        height: 200.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                      child: TextFormField(
                        decoration: new InputDecoration(
                          border: new OutlineInputBorder(
                              borderSide: new BorderSide(color: Colors.pink)
                          ),
                          labelText: 'Email',
                          hintText: '(e.g myName@domain.com)',
                        ),
                        validator: (value){
                          if (value.isEmpty){
                            return 'Please Enter your email address';
                          }
                          return null;
                        },
                        controller: emailInputController,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                      child: TextFormField(
                        decoration: new InputDecoration(
                          suffixIcon: IconButton(
                              icon: Icon(passwordVisible ? Icons.visibility_off : Icons.visibility),
                              onPressed: (){
                                setState(() {
                                  passwordVisible ^= true;
                                });
                              }
                          ),
                          border: new OutlineInputBorder(
                              borderSide: new BorderSide(color: Colors.pink)
                          ),
                          labelText: 'Password',
                        ),
                        controller: passwordInputController,
                        validator: (value){
                          if (value.isEmpty){
                            return 'Enter your password';
                          }
                          return null;
                        },
                        obscureText: passwordVisible,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0.0, 25.0, 0.0, 0.0),
                      child: ButtonTheme(
                        height: 50.0,
                        child: RaisedButton(
                          onPressed: () => _doLogin(context),
                          child: Text('Login'),
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          FlatButton(
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                  color: Colors.blue
                              ),
                            ),
                            onPressed: () => Navigator.push(_context, MaterialPageRoute(builder: (context)=>NamesAndContacts())),
                          ),
                          FlatButton(
                            onPressed: () => Navigator.push(_context, MaterialPageRoute(builder: (context) => VerifyUser())),
                            child: Text(
                              'Forgot Password',
                              style: TextStyle(
                                  color: Colors.blue
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ) ,
        ),
      );
    }
    return WillPopScope(
      onWillPop: () async{
        exit(0);
        return true;
      },
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(child: Icon(Icons.network_check),height: 50.0,width: 50.0),
            Text('Please turn on mobile data or wifi'),
          ],
        ),
      ),
    );
  }

  _homePageBody(){
    if (_connectionOn){
      return WillPopScope(
        onWillPop: () async{
          if(_scaffoldKey.currentState.isDrawerOpen){
            Navigator.of(context).pop();
            return false;
          }
          exit(0);
          return true;
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
                    child: Card(
                      child:Padding(
                        padding: EdgeInsets.all(5.0),
                        child: balancesWidget(),
                      ),
                    ),
                  )
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          child: GestureDetector(
                            onTap: () {
                              AppDB.appDB.findAll(tbVehicle).then((vehicles){
                                if (vehicles != null && vehicles.isNotEmpty){
                                  Navigator.push(context, MaterialPageRoute(
                                      builder: (context) => FuelCarPage()
                                  ));
                                } else {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context){
                                        return AlertDialog(
                                          title: Text('No Cars Found.'),
                                          content: Text('Add a car first. Go to Settings'),
                                          actions: <Widget>[
                                            FlatButton(
                                                onPressed: (){
                                                  Navigator.pop(context);
                                                },
                                                child: Text('Ok')
                                            )
                                          ],
                                        );
                                      }
                                  );
                                }
                              });
                            },
                            child: InkWell(
                              child: Card(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Expanded(
                                        child: Image(
                                            image: AssetImage('images/fuel_car.png')
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: Text('Fuel My Car'),
                                      )
                                    ],
                                  )
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          child: GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => MapsScreen()));
                            },
                            child: Card(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Image(
                                        image: AssetImage('images/navigation.png')
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Text('Nearest Station'),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Visibility(
                        visible: !_corporateUser,
                        child: Expanded(
                          flex: 1,
                          child: SizedBox(
                            child: GestureDetector(
                              onTap: (){
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) => BuyPackage()));
                              },
                              child: Card(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Expanded(
                                      child: Image(
                                          image: AssetImage('images/buypkg.png')
                                      ),
                                    ),
                                    Text(
                                        'Buy package'
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                          flex: 1,
                          child: SizedBox(
                            child: GestureDetector(
                              onTap: (){
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) => CheckBalance()));
                              },
                              child: Card(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Expanded(
                                      child: Image(
                                          image: AssetImage('images/checkbalance.png')
                                      ),
                                    ),
                                    Text(
                                        'Check Balance'
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )),
                      Expanded(
                          child: SizedBox(
                            height: 120.0,
                            child: GestureDetector(
                              onTap: (){
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ConsumptionNew()));
                              },
                              child: Card(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Expanded(
                                      child: Image(
                                          image: AssetImage('images/consumption.png')
                                      ),
                                    ),
                                    Text(
                                        'Consumption'
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                          flex: 1,
                          child: SizedBox(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => Offers()));
                              },
                              child: Card(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Expanded(
                                      child: Image(
                                          image: AssetImage('images/offer.png')
                                      ),
                                    ),
                                    Text(
                                        'Offers'
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                      ),
                      Expanded(
                          child: SizedBox(
                            child: GestureDetector(
                              onTap: (){
                                Navigator.push(_context, MaterialPageRoute(builder: (context)=> Reports()));
                              },
                              child: Card(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Expanded(
                                      child: Image(
                                          image: AssetImage('images/report.png')
                                      ),
                                    ),
                                    Text(
                                        'Reports'
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                      ),
                      Visibility(
                        visible: !_corporateUser,
                        child: Expanded(
                            child: SizedBox(
                              child: GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => SambazaPageView()));
                                },
                                child: Card(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Expanded(
                                        child: Image(
                                            image: AssetImage('images/sambaza.png')
                                        ),
                                      ),
                                      Text(
                                          'Sambaza'
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            )
                        ),
                      )
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.network_check),
          Text('Please turn on mobile data or wifi'),
        ],
      ),
    );
  }

  _doLogin(BuildContext context){
    if (_formKey.currentState.validate()){
      String entered = passwordInputController.text;
      var bytes = utf8.encode(entered);
      var encodedPass = base64.encode(bytes);
      print(encodedPass);
      _dialog = new ProgressDialog(_context,isDismissible: false);
      _dialog.style(
          message: 'Logging in ... ',
          progressWidget: CircularProgressIndicator(),
          insetAnimCurve: Curves.easeInOut
      );
      _dialog.show();
      getTokenBasicAuth().then((token){
        getUser(emailInputController.text.trim(),encodedPass,token).then((onValue){
          _dialog.dismiss();
          if (onValue != null){
            if (onValue.id > 0){
              String username = onValue.firstName;
              SessionPrefs().setLoggedInStatus(true);
              SessionPrefs().setLoggedInUser(onValue);
              SessionPrefs().setBalances(onValue.balances);
              List<Vehicle> vehicles = onValue.vehicles;
              if (vehicles != null && vehicles.isNotEmpty){
                for (Vehicle v in vehicles){
                  Map row = new HashMap<String,dynamic>();
                  row[id] = v.id;
                  row[regNo] = v.regno;
                  row[make] = v.make;
                  row[makeId] = v.makeid;
                  row[active] = v.active ? 1 : 0;
                  row[modelId] = v.modelid;
                  row[mileage] = v.mileage;
                  row[consumptionRate] = v.consumptionRate;
                  row[ccs] = v.CCs;
                  row[keyUser] = onValue.id;
                  row[engineType] = v.enginetype;
                  AppDB.appDB.save(tbVehicle, row);
                }
              } else {
                setState(() {
                  _noVehicles = true;
                });
              }
              getBalances(onValue.id,token).then((balances){
                if (balances != null){
                  SessionPrefs().setBalances(balances);
                  setState(() {
                    _accountBalance = balances.account;
                    _pointsBalance = balances.points;
                  });
                }
              });
              allDealers(onValue.id,token).then((dealers){
                if (dealers != null && dealers.isNotEmpty){
                  var fromServer = new List(dealers.length);
                  int index = 0;
                  for (MobileDealer d in dealers){
                    print("Dealer data from network: "+d.toString());
                    fromServer[index] = d.id;
                    index += 1;
                  }
                  AppDB.appDB.findAll(dealer).then((mobileDealers){
                    if (mobileDealers != null && mobileDealers.isNotEmpty){
                      var fromMobile = new List(mobileDealers.length);
                      int index = 0;
                      for (Map<String,dynamic> d in mobileDealers){
                        fromMobile[index] = d[id];
                        index += 1;
                      }
                      for (var i = 0; i < fromServer.length; i++){
                        if (!contains(fromMobile, fromServer[i])){
                          for (MobileDealer d in dealers){
                            if (d.id == fromServer[i]){
                              String s = d.toString();
                              print("To be saved ... $s");
                              Map row = new HashMap<String,dynamic>();
                              row[id] = d.id;
                              row[name] = d.name;
                              row[stationId] = d.stationid;
                              row[latitude] = d.latitude;
                              row[rating] = d.userrating;
                              row[longitude] = d.longitude;
                              AppDB.appDB.save(dealer, row);
                            }
                          }
                        }
                      }
                    } else {
                      for (MobileDealer d in dealers){
                        Map row = new HashMap<String,dynamic>();
                        row[id] = d.id;
                        row[name] = d.name;
                        row[stationId] = d.stationid;
                        row[latitude] = d.latitude;
                        row[rating] = d.userrating;
                        row[longitude] = d.longitude;
                        AppDB.appDB.save(dealer, row);
                      }
                    }
                  });
                }
              });
              Fluttertoast.showToast(
                  msg: 'Welcome $username',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM
              );
              setState((){
                _corporateUser = (onValue.role == corporateUserRole);
                _loggedIn = true;
                _user = onValue;
                _accountBalance = onValue.balances.account;
                _pointsBalance = onValue.balances.points;
              });
            } else if(onValue.id == -1){
              Scaffold.of(context).showSnackBar(SnackBar(content: Text('Wrong Password')));
            } else if(onValue.id == -2){
              setState(() {
                _activationState = true;
              });
              showDialog(context: _context,builder: (ctx){
                return AlertDialog(
                  title: Text('User Account Deactivated'),
                  content: Text('Your user account has been deactivated. Would you like to re-activate it?'),
                  actions: <Widget>[
                    FlatButton(onPressed: ()=>Navigator.pop(ctx), child: Text('No')),
                    FlatButton(onPressed: (){
                      Navigator.pop(ctx);
                      Navigator.push(_context, MaterialPageRoute(builder: (ctx)=>VerifyUser(activation: true)));
                    }, child: Text('Yes'))
                  ],
                );
              });
            } else {
              Scaffold.of(context).showSnackBar(SnackBar(content: Text('User not found')));
            }
          }
        });
      });
    }
  }

  Future<MobileUser> getUser(String userName, String password, String token) async{
    Response response;
    try{
      response = await get(baseUrlLocal+'login?email=$userName&rsps=$password',headers: getHeaders(token));
    } catch (e){
      _dialog.dismiss();
      if (e is SocketException){
        Fluttertoast.showToast(msg: 'Service is unreachable. you may be offline');
      }
    }
    var jsonResponse;
    MobileUser mobileUser;
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        jsonResponse = jsonDecode(response.body);
        mobileUser = MobileUser.fromJson(jsonResponse);
      } else {
        _dialog.dismiss();
        print(response.body);
        Fluttertoast.showToast(
            msg: 'Error $statusCode Occured',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM
        );
      }
    } else {
      _dialog.dismiss();
      Fluttertoast.showToast(
          msg: 'Server is currently unreachable',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM
      );
    }
    return mobileUser;
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _subscription.cancel();
    super.dispose();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  Future<List<MobileDealer>> allDealers(int userId,String token) async{
    List<MobileDealer> dealers;
    try{
      Response response = await get(baseUrlLocal+'alldealers/$userId',headers: getHeaders(token));
      if (response != null){
        int statusCode = response.statusCode;
        if (statusCode == 200){
          print(response.body);
          var jsonResponse = jsonDecode(response.body);
          var list = jsonResponse as List;
          dealers = list.map<MobileDealer>((json) => MobileDealer.fromJson(json)).toList();
        } else {
//        Fluttertoast.showToast(
//          msg: 'Error $statusCode Occured',
//          toastLength: Toast.LENGTH_SHORT,
//          gravity: ToastGravity.BOTTOM
//        );
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Server is unreachable',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM
        );
      }
    } catch (e){
      if (e is SocketException){
        SessionPrefs().getBalances().then((balances){
          if (balances != null){
            setState(() {
              _accountBalance = balances.account;
              _pointsBalance = balances.points;
            });
          }
        });
      } else {
        print(e);
      }
    }
    return dealers;
  }

  Future<Balances> getBalances(int userId,String token) async{
    Response response;
    try{
      response = await get(baseUrlLocal+'balancesfor/$userId',headers: getHeaders(token));
    } on SocketException {
      SessionPrefs().getBalances().then((balances){
        if (balances != null){
          setState(() {
            _accountBalance = balances.account;
            _pointsBalance = balances.points;
          });
        } else {
          setState(() {
            _message = "Your balances are currently unavailable";
          });
        }
      });
    }
    Balances balances;
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        var jsonResponse = jsonDecode(response.body);
        balances = Balances.fromJson(jsonResponse);
      } else {
//        Fluttertoast.showToast(
//          msg: 'Error $statusCode Occured',
//          toastLength: Toast.LENGTH_SHORT,
//          gravity: ToastGravity.BOTTOM
//        );
      }
    } else {
      Fluttertoast.showToast(
        msg: 'Server is unreachable',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM
      );
    }
    return balances;
  }

  @override
  void didPopNext() {
    print('   #######################  ______________ DID_POP_NEXT DETECTED ______________');
    if (_activationState){
      setState(() {
        _activationState = false;
      });
    } else {
      SessionPrefs().getBalances().then((onValue){
        if (onValue != null){
          setState(() {
            _accountBalance = onValue.account;
            _pointsBalance = onValue.points;
          });
        }
      });
    }
  }

  bool contains(List array, int key){
    for (int i in array){
      if(i == key){
        return true;
      }
    }
    return false;
  }

  balancesWidget () {
    if (_accountBalance != null && _pointsBalance != null){
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
//                            child: Text('Account Balance: 50000.00 Ksh'),
            flex : 1,
            child: Text('Account Balance: $_accountBalance Ksh'),
          ),
          Expanded(
//                            child: Text('Points Balance: 200'),
            flex : 1,
            child: Text('Points Balance: $_pointsBalance'),
          )
        ],
      );
    }
    return Text('$_message');
  }

  void _updateCorporateUserVehicles(int id, String token, bool refresh) async{
    ProgressDialog dialog;
    if (refresh){
      dialog = ProgressDialog(_context);
      dialog.style(message: 'Checking your vehicles');
      dialog.show();
    }
    Response response;
    try{
      response = await get(baseUrlLocal+'vehiclesforcorporate/$id',headers: getHeaders(token));
    } on SocketException{
      if (dialog != null){
        dialog.dismiss();
      }
      Fluttertoast.showToast(msg: 'You may be offline');
    }
    if (dialog != null && dialog.isShowing()){
      dialog.dismiss();
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        var jsonResponse = json.decode(response.body);
        var list = jsonResponse as List;
        List<Vehicle> _vehicles = list.map<Vehicle>((json) => Vehicle.fromJson(json)).toList();
        AppDB.appDB.findAll(tbVehicle).then((rows){
          var fromMobile = new List();
          for (Map m in rows){
            fromMobile.add(m[prefix1.id]);
          }
          int numVehiclesUpdated = 0;
          for (Vehicle v in _vehicles){
            if(!contains(fromMobile, v.id)){
              Map row = new HashMap<String,dynamic>();
              row[prefix1.id] = v.id;
              row[regNo] = v.regno;
              row[make] = v.make;
              row[makeId] = v.makeid;
              row[modelId] = v.modelid;
              row[consumptionRate] = v.consumptionRate;
              row[mileage] = v.mileage;
              row[active] = v.active? 1 : 0;
              AppDB.appDB.save(tbVehicle,row);
              numVehiclesUpdated += 1;
            }
          }
          if (numVehiclesUpdated > 0){
            Fluttertoast.showToast(msg: '$numVehiclesUpdated vehicle(s) have been added');
          }
        });
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode occured');
      }
    } else {
      Fluttertoast.showToast(msg: 'No response from the server');
    }
  }

}

class HomeChoice{
  String title;
  IconData icon;

  HomeChoice({this.title,this.icon});
}
