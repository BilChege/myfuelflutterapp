import 'dart:collection';
import 'dart:convert';
import 'dart:convert' as prefix1;
import 'dart:core' as prefix0;
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:progress_dialog/progress_dialog.dart';

class ChangePassword extends StatefulWidget {
  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {

  var oldPasswordController = new TextEditingController();
  var newPasswordController = new TextEditingController();
  var rptPasswordController = new TextEditingController();
  MobileUser _loggedInUser;
  ProgressDialog _dialog;
  BuildContext _context;
  final _formKey = GlobalKey<FormState>();
  prefix0.bool _oldPassVisible = true;
  prefix0.bool _newPassVisible = true;
  bool _rptPassVisible = true;

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
        title: Text('Change Password'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            scrollDirection: Axis.vertical,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: Text('Enter your old password below'),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  obscureText: _oldPassVisible,
                  controller: oldPasswordController,
                  validator: (value){
                    String oldpass = oldPasswordController.text;
                    if(value.isEmpty){
                      return 'Enter the old password';
                    }
                    return null;
                  },
                  decoration: new InputDecoration(
                    suffixIcon: IconButton(icon: Icon(_oldPassVisible ? Icons.visibility_off : Icons.visibility), onPressed: (){
                      setState(() {
                        _oldPassVisible ^= true;
                      });
                    }),
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Old Password'
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Enter and repeat your new password in the inputs below'),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  obscureText: _newPassVisible,
                  validator: (value){
                    if (value.isEmpty){
                      return 'Enter the new password';
                    }
                    return null;
                  },
                  controller: newPasswordController,
                  decoration: new InputDecoration(
                    suffixIcon: IconButton(icon: Icon(_newPassVisible ? Icons.visibility_off : Icons.visibility), onPressed: (){
                      setState(() {
                        _newPassVisible ^= true;
                      });
                    }),
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'New Password'
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: TextFormField(
                  controller: rptPasswordController,
                  obscureText: _rptPassVisible,
                  validator: (value){
                    if (value.isEmpty){
                      return 'Repeat the new password';
                    } else{
                      String newPass = newPasswordController.text;
                      if (newPass != null && newPass.isNotEmpty){
                        if (newPass != value){
                          return 'The new password values must match';
                        }
                      }
                    }
                    return null;
                  },
                  decoration: new InputDecoration(
                    suffixIcon: IconButton(icon: Icon(_rptPassVisible ? Icons.visibility_off : Icons.visibility), onPressed: (){
                      setState(() {
                        _rptPassVisible ^= true;
                      });
                    }),
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Repeat Password'
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: ButtonTheme(
                  height: 50,
                  child: RaisedButton(
                    onPressed: () => _doUpdate(),
                    child: Text('Change Password'),
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
      prefix0.String encodedUserPass = base64.encode(utf8.encode(newPasswordController.text.trim()));
      _loggedInUser.accountPassword = encodedUserPass;
      _loggedInUser.pin = null;
      String data = jsonEncode(_loggedInUser);
      _dialog = new ProgressDialog(context,isDismissible: false);
      _dialog.style(
        message: 'Verifying old password ... ',
        progressWidget: CircularProgressIndicator(),
        insetAnimCurve: Curves.easeInOut
      );
      _dialog.show();
      String oldPasswordPlain = oldPasswordController.text.trim();
      prefix0.String encodedOldPass = base64.encode(utf8.encode(oldPasswordPlain));
      checkOldPassword(_loggedInUser.id, encodedOldPass).then((valid){
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
        } else {
          Fluttertoast.showToast(msg: 'The old password you entered is incorrect');
        }
      });
    }
  }

  Future<bool> checkOldPassword(int userId, String oldPassword) async{
    prefix0.bool result;
    Response response;
    try{
      response = await get(baseUrlLocal+'verifypass/$userId?encodedPass=$oldPassword');
    } on SocketException catch (e){
      _dialog.dismiss();
      Fluttertoast.showToast(msg: 'You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    var json;
    if (response != null){
      int statusCode =  response.statusCode;
      if(statusCode == 200){
        json = prefix1.json.decode(response.body);
        result = json as prefix0.bool;
      } else {
        _dialog.dismiss();
        Fluttertoast.showToast(msg: 'Error $statusCode Occured while verifying old pin');
      }
    } else{
      _dialog.dismiss();
      Fluttertoast.showToast(msg: 'No response from server',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    return result;
  }

  Future<bool> updateUserDetails(String user, String token) async{
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
