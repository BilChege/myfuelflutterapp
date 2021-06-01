import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:progress_dialog/progress_dialog.dart';

class ChangePin extends StatefulWidget {

  @override
  _ChangePinState createState() => _ChangePinState();
}

class _ChangePinState extends State<ChangePin> {
  var oldPinController = new TextEditingController();
  var newPinController = new TextEditingController();
  var rptPinController = new TextEditingController();
  MobileUser _loggedInUser;
  ProgressDialog _dialog;
  BuildContext _context;
  final _formKey = GlobalKey<FormState>();
  bool _oldPinVisible = true;
  bool _newPinVisible = true;
  bool _rptPinVisible = true;

  @override
  void initState() {
    SessionPrefs().getLoggedInUser().then((onValue){
      setState(() {
        _loggedInUser = onValue;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Pin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: Text('Enter your old pin below'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  obscureText: _oldPinVisible,
                  validator: (value){
                    String oldPin = oldPinController.text;
                    if (value.isEmpty){
                      return 'Enter the old pin';
                    }
                    return null;
                  },
                  controller: oldPinController,
                  decoration: new InputDecoration(
                    suffixIcon: IconButton(icon: Icon(_oldPinVisible ? Icons.visibility_off : Icons.visibility),onPressed: (){
                      setState(() {
                        _oldPinVisible ^=true;
                      });
                    }),
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Old Pin',
                  ),
                  maxLength: 4,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Enter and repeat your new pin in the below inputs')
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  obscureText: _newPinVisible,
                  validator: (value){
                    if (value.isEmpty){
                      return 'Enter the new pin';
                    }
                    return null;
                  },
                  controller: newPinController,
                  decoration: new InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(_newPinVisible ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _newPinVisible ^= true;
                        });
                      },
                    ),
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'New pin'
                  ),
                  maxLength: 4,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  obscureText: _rptPinVisible,
                  validator: (value){
                    String newPin = newPinController.text;
                    if (value.isEmpty){
                      return 'Repeat your new pin';
                    } else{
                      if(newPin.isNotEmpty){
                        if (newPin != value){
                          return 'The new pin values must match';
                        }
                      }
                    }
                    return null;
                  },
                  controller: rptPinController,
                  decoration: new InputDecoration(
                    suffixIcon: IconButton(icon: Icon(_rptPinVisible ? Icons.visibility_off : Icons.visibility), onPressed: (){
                      setState(() {
                        _rptPinVisible ^= true;
                      });
                    }),
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Repeat pin'
                  ),
                  maxLength: 4,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: ButtonTheme(
                  height: 50,
                  child: RaisedButton(
                    onPressed: () => _doUpdate(),
                    child: Text('Change Pin'),
                    color: Colors.amber,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _doUpdate() {
    if (_formKey.currentState.validate()){
      _loggedInUser.pin = base64.encode(utf8.encode(newPinController.text.trim()));
      _loggedInUser.accountPassword = null;
      String data = json.encode(_loggedInUser);
      _dialog = new ProgressDialog(_context,isDismissible: false);
      _dialog.style(
          message: 'Verifying old pin ...',
          progressWidget: CircularProgressIndicator(),
          insetAnimCurve: Curves.easeInOut
      );
      _dialog.show();
      String encodedOldPin = base64.encode(utf8.encode(oldPinController.text.trim()));
      verifyOldPin(_loggedInUser.id, encodedOldPin).then((valid){
        _dialog.dismiss();
        if(valid){
          _dialog.style(
            message: 'Updating data ... ',
              progressWidget: CircularProgressIndicator(),
              insetAnimCurve: Curves.easeInOut
          );
          _dialog.show();
          getTokenBasicAuth().then((token){
            updateUserDetails(data,token).then((onValue){
              _dialog.dismiss();
              if (onValue){
                Fluttertoast.showToast(
                    msg: 'Data saved Successfully',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM
                );
                Navigator.pop(_context);
              }
            });
          });
        } else{
          Fluttertoast.showToast(msg: 'The old pin you entered is incorrect');
        }
      });
    }
  }

  Future<bool> verifyOldPin(int id,String input) async {
    Response response;
    try{
      response = await get(baseUrlLocal+'verifypin/$id?encodedPin=$input');
    } catch (e){
      _dialog.dismiss();
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
        _dialog.dismiss();
        Fluttertoast.showToast(msg: 'Error $statusCode Occured',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      }
    } else {
      _dialog.dismiss();
    }
    return result;
  }

  Future<bool> updateUserDetails(String user,String token) async{
    bool result;
    Response response;
    try{
      response = await put(baseUrlLocal+'updateuserdetails',headers: postHeaders(token),body: user);
    } on SocketException{
      _dialog.dismiss();
      Fluttertoast.showToast(msg: 'You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        Map<String,dynamic> jsonResponse = jsonDecode(response.body);
        MobileUser user = MobileUser.fromJson(jsonResponse);
        SessionPrefs().setLoggedInUser(user);
        result = true;
      } else {
        result = false;
        Fluttertoast.showToast(
          msg: 'Error $statusCode Occured',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM
        );
      }
    } else {
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

