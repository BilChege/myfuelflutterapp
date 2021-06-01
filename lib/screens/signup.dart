import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/screens/home.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:pin_view/pin_view.dart';
import 'package:progress_dialog/progress_dialog.dart';

class NamesAndContacts extends StatefulWidget {

  @override
  _NamesAndContactsState createState() => _NamesAndContactsState();
}

class _NamesAndContactsState extends State<NamesAndContacts> {
  var fNameController = new TextEditingController();
  var lNameController = new TextEditingController();
  var emailController = new TextEditingController();
  var phoneController = new TextEditingController();
  RegExp _validEmail2 = new RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+\.[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]*$",caseSensitive: false);
  final _formKey = GlobalKey<FormState>();
  BuildContext _context;
  ProgressDialog _dialog;

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Names and contacts'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 40.0, 0.0, 0.0),
                child: TextFormField(
                  controller: fNameController,
                  validator: (value){
                    if (value.isEmpty){
                      return 'Enter your first name';
                    }
                    return null;
                  },
                  decoration: new InputDecoration(
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'First Name'
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  controller: lNameController,
                  validator: (value){
                    if (value.isEmpty){
                      return 'Enter your last name';
                    }
                    return null;
                  },
                  decoration: new InputDecoration(
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Last Name'
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  controller: emailController,
                  validator: (value){
                    if (value.isEmpty){
                      return 'Enter your email address';
                    } else if (!_validEmail2.hasMatch(value.trim())){
                      return 'Invalid email input';
                    }
                    return null;
                  },
                  decoration: new InputDecoration(
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Email Address',
                    hintText: '(e.g myName@domain.com)'
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  controller: phoneController,
                  validator: (value){
                    if(value.isEmpty){
                      return 'Enter your phone number';
                    } else if (!value.startsWith('07') || value.length != 10){
                      return 'Invalid phone number';
                    }
                    return null;
                  },
                  decoration: new InputDecoration(
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Phone Number',
                    hintText: '(e.g 07xxxxxxxx)'
                  ),
                  keyboardType: TextInputType.phone,
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goNext(),
        child: Icon(Icons.arrow_forward),
        backgroundColor: Colors.amber,
      ),
    );
  }

  _goNext() {
    if(_formKey.currentState.validate()){
      _dialog = new ProgressDialog(_context);
      _dialog.style(message: 'Please wait ... ');
      _dialog.show();
      getTokenBasicAuth().then((token){
        checkUser(emailController.text,token).then((user){
          _dialog.dismiss();
          if(user.id > 0){
            showDialog(
                context: _context,
                builder: (BuildContext context){
                  return AlertDialog(
                    content: Text('The email address entered has been used to register another account'),
                    actions: <Widget>[
                      FlatButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Ok')
                      )
                    ],
                  );
                }
            );
          } else {
            MobileUser mobileUser = MobileUser.empty();
            mobileUser.firstName = fNameController.text.trim();
            mobileUser.lastName = lNameController.text.trim();
            mobileUser.email = emailController.text.trim();
            mobileUser.phone = phoneController.text.trim();
            SessionPrefs().setLoggedInUser(mobileUser);
            Navigator.push(_context, MaterialPageRoute(builder: (context) => VerifyPhone()));
          }
        });
      });
    }
  }

  Future<MobileUser> checkUser(String email,String token) async{
    MobileUser mobileUser;
    Response response = await get(baseUrlLocal+"checkuser?email=$email",headers: getHeaders(token));
    if (response != null){
      int statusCode = response.statusCode;
      if(statusCode == 200){
        var jsonResponse = jsonDecode(response.body);
        mobileUser = MobileUser.fromJson(jsonResponse);
      } else {
        _dialog.dismiss();
        Fluttertoast.showToast(
          msg: 'Error $statusCode Occured',
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
    return mobileUser;
  }
}


// ignore: must_be_immutable
class VerifyPhone extends StatefulWidget {

  bool activation;
  VerifyPhone({this.activation});

  @override
  _VerifyPhoneState createState() => _VerifyPhoneState();
}

class _VerifyPhoneState extends State<VerifyPhone>{

  MobileUser _loggedInUser;
  bool _activationState;
  String _verificationCode;
  ProgressDialog _dialog;
  BuildContext _context;
  bool _requesting = true;
  String _message;

  @override
  void initState() {
    bool activationVal = widget.activation;
    if(activationVal != null){
      setState(() {
        _activationState = activationVal;
      });
    }
    SessionPrefs().getLoggedInUser().then((onValue){
      setState(() {
        _loggedInUser = onValue;
      });
      getTokenBasicAuth().then((token){
        requestVerification(onValue.phone,token).then((onValue1){
          setState(() {
            _requesting = false;
            _verificationCode = onValue1;
          });
        });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Phone'),
        backgroundColor: Colors.amber,
      ),
      body: _body(),
    );
  }

  _body(){
    if (_verificationCode != null){
      if (_verificationCode == smsVerificationFailure){
        return Center(
          child: Text('There was an error requesting for verification. Please try again later'),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(15.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text('Please wait for a verification code via sms. If the code does not autofill, enter the values into the inputs below'),
              PinView(
                submit: (String code){
                  verifyCode(_verificationCode, code).then((onValue){
                    if(onValue){
                      if(_activationState != null && _activationState){
                        ProgressDialog d = new ProgressDialog(_context);
                        d.style(message: 'Please wait ... ');
                        d.show();
                        _loggedInUser.active = true;
                        String jsonData = json.encode(_loggedInUser);
                        getTokenBasicAuth().then((token){
                          updateUser(jsonData, token).then((user){
                            d.dismiss();
                            if (user != null){
                              Fluttertoast.showToast(msg: 'Your account has been activated successfully');
                              Navigator.push(_context, MaterialPageRoute(builder: (ctx)=>MyHomePage()));
                            }
                          });
                        });
                      } else {
                        Navigator.push(_context, MaterialPageRoute(builder: (context)=> SetPassword()));
                      }
                    } else {
                      Fluttertoast.showToast(
                          msg: 'Sorry, wrong code entered',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM
                      );
                    }
                  });
                },
                count: 6,
                dashPositions: [3],
                margin: EdgeInsets.all(2.5),
                sms: SmsListener(
                    from: 'NETRIXBIZ',
                    formatBody: (String body){
                      return body;
                    }
                ),
              )
            ],
          ),
        ),
      );
    }
    if (_requesting){
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(
              backgroundColor: Colors.pink,
            ),
            Text('Requesting Phone Verification ... ')
          ],
        ),
      );
    }
    return Center(
      child: Text(_message),
    );
  }

  Future<bool> verifyCode(String fromServer, String fromSms) async{
    bool result = fromServer == fromSms;
    return result;
  }

  Future<String> requestVerification(String phone,String token) async{
    String result;
    Response response;
    try{
      response = await post(baseUrlLocal+'verifyphone/$phone');
    } on SocketException{
      setState(() {
        _requesting = false;
        _message = 'You may be offline';
      });
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        result = response.body;
      } else {
        setState(() {
          _requesting = false;
          _message = 'An error occured while requesting verification';
        });
        Fluttertoast.showToast(
          msg: 'Error $statusCode Occured',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM
        );
      }
    } else {
      setState(() {
        _requesting = false;
        _message = 'There was no response from the service';
      });
      Fluttertoast.showToast(
        msg: 'Server is Unreachable',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM
      );
    }
    return result;
  }
}

class SetPassword extends StatefulWidget {
  @override
  _SetPasswordState createState() => _SetPasswordState();
}

class _SetPasswordState extends State<SetPassword> {

  MobileUser _loggedInUser;
  var setPassController = new TextEditingController();
  var rptPassController = new TextEditingController();
  final _forKey = GlobalKey<FormState>();
  BuildContext _context;
  ProgressDialog _dialog;
  bool setPassVisisble = true, rptPassVisible = true;

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Password'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _forKey,
          child: ListView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: Text('Set a Login Password'),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  obscureText: setPassVisisble,
                  controller: setPassController,
                  validator: (value){
                    if (value.isEmpty){
                      return 'Enter a password';
                    }
                    return null;
                  },
                  decoration: new InputDecoration(
                    suffixIcon: IconButton(
                        icon: Icon(setPassVisisble ? Icons.visibility_off : Icons.visibility),
                        onPressed: (){
                          setState(() {
                            setPassVisisble ^= true;
                          });
                        }
                    ),
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Enter Password'
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  obscureText: rptPassVisible,
                  controller: rptPassController,
                  validator: (value){
                    String entered = setPassController.text;
                    if (value.isEmpty){
                      return 'Repeat your password';
                    } else if (value != entered){
                      return 'Passwords must match';
                    }
                    return null;
                  },
                  decoration: new InputDecoration(
                    suffixIcon: IconButton(
                        icon: Icon(rptPassVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: (){
                          setState(() {
                            rptPassVisible ^= true;
                          });
                        }
                    ),
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Repeat password'
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          if (_forKey.currentState.validate()){
            _dialog = new ProgressDialog(_context,isDismissible: false);
            _dialog.style(
                message: 'Saving password'
            );
            _dialog.show();
            SessionPrefs().getLoggedInUser().then((onValue){
              String enteredPass = setPassController.text;
              var bytes = utf8.encode(enteredPass);
              var encodedStr = base64.encode(bytes);
              onValue.accountPassword = encodedStr;
              SessionPrefs().setLoggedInUser(onValue).then((onValue){
                _dialog.dismiss();
                Navigator.push(_context, MaterialPageRoute(builder: (context)=>SetPin()));
              });
            });
//              _dialog.dismiss();

          }
        },
        child: Icon(Icons.arrow_forward),
        backgroundColor: Colors.amber,
      ),
    );
  }

  _goNext() {

  }
}

class SetPin extends StatefulWidget {

  final bool toUpdate;

  @override
  _SetPinState createState() => _SetPinState();

  SetPin({this.toUpdate});
}

class _SetPinState extends State<SetPin> {

  MobileUser _loggedInUser;
  var setPinController = new TextEditingController();
  var rptPinController = new TextEditingController();
  BuildContext _context;
  ProgressDialog _dialog;
  bool _toUpdateValue = false;
  final _formKey = GlobalKey<FormState>();
  bool setPinVisible = true, rptPinVisible = true;

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Pin'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          child: ListView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Set a pin for transactions at the fuel station'),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  obscureText: setPinVisible,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  controller: setPinController,
                  validator: (value){
                    if (value.isEmpty){
                      return 'Set a pin for transactions at the station';
                    }
                    return null;
                  },
                  decoration: new InputDecoration(
                    suffixIcon: IconButton(
                        icon: Icon(setPinVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            setPinVisible ^= true;
                          });
                        }
                    ),
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Enter Pin'
                  ),
                )
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  obscureText: rptPinVisible,
                  maxLength: 4,
                  controller: rptPinController,
                  keyboardType: TextInputType.number,
                  validator: (value){
                    String entered = setPinController.text;
                    if (value.isEmpty){
                      return 'Repeat your pin';
                    } else if (value != entered){
                      return 'The input pin values must match';
                    }
                    return null;
                  },
                  decoration: new InputDecoration(
                    suffixIcon: IconButton(
                        icon: IconButton(
                            icon: Icon(rptPinVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: (){
                              setState(() {
                                rptPinVisible ^= true;
                              });
                            }
                        ),
                        onPressed: null
                    ),
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(
                        color: Colors.pink
                      ),
                    ),
                    labelText: 'Repeat pin'
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: ButtonTheme(
                  height: 50.0,
                  child: RaisedButton(
                    onPressed: () => _doSignUp(),
                    child: Text(_toUpdateValue ? 'Set Pin' : 'Create Account'),
                    color: Colors.amber,
                  ),
                ),
              )
            ],
          ),
          key: _formKey,
        ),
      ),
    );

  }

  @override
  void initState() {
    SessionPrefs().getLoggedInUser().then((onValue){
      _loggedInUser = onValue;
    });
    if (widget.toUpdate != null){
      setState(() {
        _toUpdateValue = widget.toUpdate;
      });
    }
    super.initState();
  }

  _doSignUp() {
    if (_formKey.currentState.validate()){
      String enteredPin = setPinController.text;
      var bytes = utf8.encode(enteredPin);
      var encodedStr = base64.encode(bytes);
      _loggedInUser.pin = encodedStr;
      if (_toUpdateValue){
        _loggedInUser.accountPassword = null;
      }
      String data = jsonEncode(_loggedInUser);
      _dialog = new ProgressDialog(_context, isDismissible: false);
      _dialog.style(
        message: _toUpdateValue ? 'Saving Your pin ... ':'Creating Account ... ',
        progressWidget: CircularProgressIndicator(),
        insetAnimCurve: Curves.easeInOut
      );
      _dialog.show();
      if (_toUpdateValue){
        getTokenBasicAuth().then((token){
          updateUser(data,token).then((user){
            _dialog.dismiss();
            if (user != null && user.id > 0){
              SessionPrefs().setLoggedInUser(user);
              Fluttertoast.showToast(msg: 'Your pin has been saved successfully',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
              Navigator.pop(_context);
            }
          });
        });
      } else {
        getTokenBasicAuth().then((token){
          signUpUser(data,token).then((onValue){
            _dialog.dismiss();
            if(onValue){
              String firstName = _loggedInUser.firstName;
              Fluttertoast.showToast(
                  msg: 'Welcome $firstName',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM
              );
              Navigator.push(_context, MaterialPageRoute(builder: (context) => MyHomePage()));
            }
          });
        });
      }
    }
  }

  Future<bool> signUpUser(String data,String token) async{
    Response response;
    try{
      response = await post(baseUrlLocal+'signupmobileuser',headers: postHeaders(token),body: data);
    } on SocketException{
      _dialog.dismiss();
      Fluttertoast.showToast(msg: 'You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    bool result;
    if(response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        result = true;
        var jsonResponse = jsonDecode(response.body);
        MobileUser mobileUser = MobileUser.fromJson(jsonResponse);
        SessionPrefs().setLoggedInUser(mobileUser);
        SessionPrefs().setLoggedInStatus(true);
      } else {
        _dialog.dismiss();
        result = false;
        Fluttertoast.showToast(
          msg: 'Error $statusCode Occured',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM
        );
      }
    } else {
      _dialog.dismiss();
      result = false;
      Fluttertoast.showToast(
        msg: 'Server is unreachable',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM
      );
    }
    return result;
  }

}
