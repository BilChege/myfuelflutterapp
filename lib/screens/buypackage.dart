import 'dart:collection';
import 'dart:convert';
import 'dart:convert' as prefix2;
import 'dart:core';
import 'dart:core' as prefix0;
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/MpesaModels.dart';
import 'package:my_fuel_flutter_app/models/PackageModels.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/screens/packagedetails.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix1;
import 'package:progress_dialog/progress_dialog.dart';

class BuyPackage extends StatefulWidget {

  @override
  _BuyPackageState createState() => _BuyPackageState();
}

class _BuyPackageState extends State<BuyPackage>{

  ProgressDialog _dialog;
  BuildContext _context;
  Set<String> _categories;
  FuelPackage _package;
  MobileUser _loggedInUser;
  String _message = 'Loading ... ';
  HashMap<String,List<FuelPackage>> data;

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Buy Packages'),
        backgroundColor: Colors.amber,
      ),
      body: _body(),
    );
  }

  @override
  void initState() {
    prefix1.getTokenBasicAuth().then((token){
      _fetchAllPackages(token).then((packages){
        setState(() {
          data = new HashMap();
          Set<String> cat = Set();
          _categories = cat;
          for (var i = 0;i < packages.length;i++){
            cat.add(packages[i].typeOfPackage);
          }
          for (String s in cat){
            List<FuelPackage> fpackages = [];
            for (FuelPackage f in packages){
              if (f.typeOfPackage == s){
                fpackages.add(f);
              }
            }
            data[s] = fpackages;
          }
        });
      });
    });
    SessionPrefs().getLoggedInUser().then((user){
      setState(() {
        _loggedInUser = user;
      });
    });
    super.initState();
  }

  Widget _body(){
    if (data != null && data.isNotEmpty){
      return new ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context,i){
          String titleVal = _categories.elementAt(i);
          List<FuelPackage> fuelPackages = data[titleVal];
          var children = List<Widget>();
          for (FuelPackage f in fuelPackages){
            double price = f.priceOfPackage;
            children.add(Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.0,horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('$price Ksh'),
                  RaisedButton(
                    onPressed: () {
                      Navigator.push(_context, MaterialPageRoute(builder: (bc) => PackageDetails(f)));
                    },
                    color: Colors.amber,
                    child: Text('Buy'),
                  )
                ],
              ),
            ));
          }
          return new ExpansionTile(
            title: new Text(
              '$titleVal Packages',
            ),
//            children: <Widget>[
//              Text('Test'),
//              Text('Test')
//            ],
            children: children,
          );
        },
      );
    }
    return Center(
        child: Text('$_message'),
    );
  }

//  List<Widget> getChildrenOf(String title){
//    var rows = List<Widget>();
//    for(FuelPackage f in _fuelPackages){
//      if (f.typeOfPackage == title){
//        packages.add(f);
//      }
//      return new List<Widget>.generate(packages.length,(int index){
//        FuelPackage f1 = packages[index];
//        double price = f1.priceOfPackage;
//        return Row(
//          mainAxisAlignment: MainAxisAlignment.spaceBetween,
//          crossAxisAlignment: CrossAxisAlignment.center,
//          children: <Widget>[
//            Text('$price Ksh'),
//            RaisedButton(
//              color: Colors.amber,
//              onPressed: _makePurchase(f1),
//              child: Text('Buy'),
//            )
//          ],
//        );
//      });
//    }
//  }

  _makePurchase(){
    DateFormat format = new DateFormat('yyyy-MM-dd HH:mm:ss');
    DateTime current = new DateTime.now();
    String curr = format.format(current);
    DateTime expiryDate = current.add(Duration(days: _package.expiryDays));
    String edate = format.format(expiryDate);

  }

  Future<List<FuelPackage>> _fetchAllPackages(String token) async{
    Response response;
    try{
      response = await get(baseUrlLocal+'allpackages',headers: prefix1.getHeaders(token));
    } catch(e){
      if (e is SocketException){
        setState(() {
          _message = 'Service is unreachable. You may be offline';
        });
      } else {
        print(e);
      }
    }
    List<FuelPackage> fuelPackages = [];
    var jsonResponse;
    if (response != null){
      int responseCode  = response.statusCode;
      if (responseCode == 200){
        jsonResponse = json.decode(response.body);
        var list = jsonResponse as List;
        fuelPackages = list.map<FuelPackage>((json) => FuelPackage.fromJson(json)).toList();
      } else {
        Fluttertoast.showToast(
            msg: 'Error $responseCode Occured',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM
        );
      }
    } else {
      Fluttertoast.showToast(
          msg: 'The service is currently unreachable',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM
      );
    }
    return fuelPackages;
  }

}

//class _Categories{
//  String title;
//  List
//}