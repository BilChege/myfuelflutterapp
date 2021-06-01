import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/screens/changepassword.dart';
import 'package:my_fuel_flutter_app/screens/changepin.dart';
import 'package:my_fuel_flutter_app/screens/home.dart';
import 'package:my_fuel_flutter_app/screens/managevehicles.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:progress_dialog/progress_dialog.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  BuildContext _context;
  MobileUser _loggedInUser;

  @override
  void initState() {
    SessionPrefs().getLoggedInUser().then((user){
      setState(() {
        _loggedInUser = user;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    _context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.amber,
      ),
      body: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[
          ListTile(
            title: Text('Change Pin'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePin())),
          ),
          Divider(
            thickness: 1,
          ),
          ListTile(
            title: Text('My Cars'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyCars())),
          ),
          Divider(
            thickness: 1,
          ),
          ListTile(
            title: Text('Change Password'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePassword())),
          ),
          Divider(
            thickness: 1,
          ),
          ListTile(
            title: Text('Deactivate Account'),
            onTap: _deactivateUserAccount,
          ),
          Divider(
            thickness: 1,
          ),
        ],
      ),
    );
  }

  void _deactivateUserAccount(){
    showDialog(context: _context,builder: (bc){
      return AlertDialog(
        title: Text('Deactivate Account?'),
        content: Text('You are about to deactivate your user account. Would like to proceed?'),
        actions: <Widget>[
          FlatButton(onPressed: () => Navigator.pop(bc), child: Text('No')),
          FlatButton(onPressed: (){
            Navigator.pop(bc);
            ProgressDialog dialog = new ProgressDialog(_context);
            dialog.style(message: 'Please wait ... ');
            dialog.show();
            _loggedInUser.active = false;
            _loggedInUser.accountPassword = null;
            _loggedInUser.pin = null;
            String jsonData = json.encode(_loggedInUser);
            getTokenBasicAuth().then((token){
              updateUser(jsonData, token).then((user){
                dialog.dismiss();
                Fluttertoast.showToast(msg: 'User account deactivated successfully.');
                SessionPrefs().setLoggedInStatus(false);
                Navigator.push(_context, MaterialPageRoute(builder: (ctx)=>MyHomePage()));
              });
            });
          }, child: Text('Yes'))
        ],
      );
    });
  }

}