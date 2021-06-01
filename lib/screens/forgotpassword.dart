import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/screens/home.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:progress_dialog/progress_dialog.dart';

import 'signup.dart';

// ignore: must_be_immutable
class VerifyUser extends StatefulWidget {

  bool activation;
  VerifyUser({this.activation});

  @override
  _VerifyUserState createState() => _VerifyUserState();
}

class _VerifyUserState extends State<VerifyUser> with RouteAware{

  bool _emailVerified = false;
  bool _activationState;
  bool _codeVerified = false;
  final _formKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _setNewPassFormKey = GlobalKey<FormState>();
  final _emailController = new TextEditingController();
  final _codeInputController = new TextEditingController();
  final _newPassController = new TextEditingController();
  final _rptPassController = new TextEditingController();
  bool _newPassVisible = true;
  bool _rptPassVisible = true;
  ProgressDialog _dialog;
  BuildContext _context;
  String _verificationCode;


  @override
  void initState() {
    bool activationVal = widget.activation;
    if (activationVal != null){
      setState(() {
        _activationState = activationVal;
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    _context = context;
    return Scaffold(
      appBar: AppBar(title: Text('Verify User'),backgroundColor: Colors.amber),
      body: _body(),
    );
  }


  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context));
    super.didChangeDependencies();
  }


  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  _body() {
    if (_emailVerified){
      if (_codeVerified){
        return Container(
          child: Padding(padding: EdgeInsets.all(20.0),
            child: Form(
              key: _setNewPassFormKey,
              child: ListView(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: TextFormField(
                      obscureText: _newPassVisible,
                      validator: (value){
                        if(value.isEmpty){
                          return 'Enter new password';
                        }
                        return null;
                      },
                      controller: _newPassController,
                      decoration: InputDecoration(
                        labelText: 'Enter new password',
                        border: new OutlineInputBorder(
                          borderSide: new BorderSide(
                            color: Colors.pink
                          ),
                        ),
                        suffixIcon: IconButton(
                            icon: Icon(_newPassVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: (){
                              setState(() {
                                _newPassVisible ^= true;
                              });
                            }
                        )
                      ),
                    ),
                  ),
                  TextFormField(
                    obscureText: _rptPassVisible,
                    validator: (value){
                      String newPass = _newPassController.text;
                      if(value.isEmpty){
                        return 'Repeat new password';
                      } else{
                        if (newPass.isNotEmpty){
                          if (value != newPass){
                            return 'The new password values must match';
                          }
                        }
                      }
                      return null;
                    },
                    controller: _rptPassController,
                    decoration: InputDecoration(
                      labelText: 'Repeat password',
                      border: new OutlineInputBorder(
                        borderSide: new BorderSide(
                          color: Colors.pink
                        ),
                      ),
                      suffixIcon: IconButton(
                          icon: Icon(_rptPassVisible ? Icons.visibility_off : Icons.visibility),
                          onPressed: (){
                            setState(() {
                              _rptPassVisible ^= true;
                            });
                          })
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: ButtonTheme(
                      height: 50.0,
                        child: RaisedButton(onPressed: (){
                          if(_setNewPassFormKey.currentState.validate()){
                            _dialog = new ProgressDialog(context);
                            _dialog.style(
                              message: 'Saving new password'
                            );
                            _dialog.show();
                            SessionPrefs().getLoggedInUser().then((user){
                              String plainText = _newPassController.text;
                              user.accountPassword = base64Encode(utf8.encode(plainText));
                              String jsonString = json.encode(user);
                              getTokenBasicAuth().then((token){
                                updateUser(jsonString,token).then((user){
                                  _dialog.dismiss();
                                  if (user != null){
                                    Fluttertoast.showToast(msg: 'Your new password has been saved successfully',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                                    Navigator.pop(_context);
                                  }
                                });
                              });
                            });
                          }
                        },
                        color: Colors.amber,
                          child: Text('Save new password'),
                        )),
                  )
                ],
              ),
            ),
          ),
        );
      }
      return Container(
        child: Padding(padding: EdgeInsets.all(20.0),child: Form(
          key: _codeFormKey,
            child: ListView(
              children: <Widget>[
                Padding(padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: TextFormField(
                    validator: (value){
                      if (value.isEmpty){
                        return 'Enter the code sent to your email address';
                      }
                      return null;
                    },
                    controller: _codeInputController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),),
                Text('A six digit verification code was sent to your email address. Enter the code in the input above inorder to complete the verification process'),
                Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: ButtonTheme(height: 50,child: RaisedButton(onPressed: (){
                  if (_codeFormKey.currentState.validate()){
                    if (_verificationCode == _codeInputController.text){
                        if(_activationState != null && _activationState){
                          Navigator.push(_context, MaterialPageRoute(builder: (ctx)=>VerifyPhone(activation: true)));
//                          Navigator.pop(_context);
                        } else {
                          setState(() {
                            _codeVerified = true;
                          });
                        }
                    } else {
                      Fluttertoast.showToast(msg: 'The code you entered is incorrect',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                    }
                  }
                },color: Colors.amber,child: Text('Verify code'),)))
              ],
            )),),
      );
    }
    return Container(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Padding(padding: EdgeInsets.symmetric(vertical: 20.0),
                child: TextFormField(
                  validator: (value){
                    if (value.isEmpty){
                      return 'Enter your email address here first';
                    }
                    return null;
                  },
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: new OutlineInputBorder(
                      borderSide: new BorderSide(
                        color: Colors.pink
                      )
                    ),
                    labelText: 'Enter your email address'
                  ),
                ),
              ),
              ButtonTheme(child: RaisedButton(onPressed: () => _doVerification(),color: Colors.amber,child: Text('Verify email')),height: 50)
            ],
          ),
        ),
      ),
    );
  }

  _doVerification() {
    if (_formKey.currentState.validate()){
      _dialog = new ProgressDialog(_context);
      _dialog.style(message: 'Verifying account');
      _dialog.show();
      getTokenBasicAuth().then((token){
        checkUser(_emailController.text,token).then((user){
          if (user.id > 0){
            SessionPrefs().setLoggedInUser(user);
            _dialog.update(message: 'Requesting verification ... ');
            getCode(_emailController.text,token).then((code){
              _dialog.dismiss();
              setState(() {
                _verificationCode = code;
                _emailVerified = true;
              });
            });
          } else {
            _dialog.dismiss();
            Fluttertoast.showToast(msg: 'User not found',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
          }
        });
      });
    }
  }

  Future<String> getCode(String email,String token) async{
    String code;
    Response response;
    try{
      response = await get(baseUrlLocal+'verifyemail?address=$email',headers: getHeaders(token));
    } on SocketException{
      _dialog.dismiss();
      Fluttertoast.showToast(msg: 'Service is unreachable. You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    var jsonResponse;
    if(response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        jsonResponse = json.decode(response.body);
        int codeValue = jsonResponse as int;
        code = codeValue.toString();
      } else {
        _dialog.dismiss();
        Fluttertoast.showToast(msg: 'Error $statusCode Occured while requesting verification',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      }
    } else {
      _dialog.dismiss();
      Fluttertoast.showToast(msg: 'No response from service',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    return code;
  }
}