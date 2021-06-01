import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:progress_dialog/progress_dialog.dart';

class Sambaza extends StatelessWidget {

  var contactController = new TextEditingController();
  var amountController = new TextEditingController();
  final _formKey = GlobalKey<FormState>();
  ProgressDialog _dialog;
  BuildContext _context;

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Container(
      padding: EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              controller: contactController,
              validator: (value){
                if (value.isEmpty){
                  return 'Recievers phone number is required';
                }
                return null;
              },
              decoration: new InputDecoration(
                border: new OutlineInputBorder(
                  borderSide: new BorderSide(color: Colors.pink)
                ),
                labelText: 'Reciever phone number',
              ),
            ),
            TextFormField(
              controller: amountController,
              validator: (value) {
                if (value.isEmpty){
                  return 'Specify the amaount to send';
                }
                return null;
              },
              decoration: new InputDecoration(
                border: new OutlineInputBorder(
                  borderSide: new BorderSide(color: Colors.pink)
                ),
                labelText: 'Amount to send'
              ),
            ),
            RaisedButton(
              onPressed: () => _doSambaza(),
              child: Text('Send'),
              color: Colors.amber,
            )
          ],
        ),
      ),
    );
  }

  _doSambaza(){
    if (_formKey.currentState.validate()){
      String senderId = getLoggedInUser().id as String;
      String reciever = contactController.text;
      String amount = amountController.text;
      showDialog(
          context: _context,
          builder: (BuildContext context){
            return AlertDialog(
              title: Text('Sambaza Package?'),
              content: Text('Are you sure you want to sambaza $amount Ksh worth of fuel to $reciever'),
              actions: <Widget>[
                FlatButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('No')
                ),
                FlatButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _dialog = new ProgressDialog(_context);
                      _dialog.style(
                          message: 'Processing transaction',
                          insetAnimCurve: Curves.easeInOut,
                          progressWidget: CircularProgressIndicator()
                      );
                      _dialog.show();
                      sambazaPackage(senderId, reciever, amount).then((onValue){
                        _dialog.dismiss();
                        if (onValue){
                          showDialog(
                            context: _context,
                            builder: (BuildContext context){
                              return AlertDialog(
                                title: Text('Success'),
                                content: Text('Transaction successful.'),
                                actions: <Widget>[
                                  FlatButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Ok')
                                  )
                                ],
                              );
                            }
                          );
                          Navigator.pop(_context);
                        }
                      });
                    },
                    child: Text('Yes')
                )
              ],
            );
          }
      );
    }
  }

  Future<bool> sambazaPackage(String from,String to,String amt) async{
    bool result;
    Response response = await post(baseUrlLocal+'sambaza?sentfrom=$from&recipientphone=$to&amount=$amt');
    Map<String,dynamic> jsonResponse;
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        result = true;
        jsonResponse = jsonDecode(response.body);
        Balances balances = Balances.fromJson(jsonResponse);
        SessionPrefs().setBalances(balances);
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
        msg: 'Server didnt respond',
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT
      );
    }
    return result;
  }

}
