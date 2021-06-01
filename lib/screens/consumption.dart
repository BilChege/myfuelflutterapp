import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/VehicleModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:progress_dialog/progress_dialog.dart';

class Consumption extends StatefulWidget {
  @override
  _ConsumptionState createState() => _ConsumptionState();
}

class _ConsumptionState extends State<Consumption> {

  List<FuelCar> _fuelCars;
  ProgressDialog _dialog;
  BuildContext _context;
  bool _errorState = false;
  bool _offlineState = false;
  String _message = "Loading ... ";

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Consumption'),
      ),
      body: _body(),
    );
  }

  Widget _body(){
    if(_fuelCars != null && _fuelCars.isNotEmpty){
      Set<String> regs = new Set();
      for (FuelCar fc in _fuelCars){
        regs.add(fc.vehicle.regno);
      }
      Map data = new HashMap<String,double>();
      for(String s in regs){
        double amt = 0;
        for(FuelCar fc in _fuelCars){
          if (fc.vehicle.regno == s){
            amt += fc.amount;
          }
        }
        data[s] = amt;
      }
      return ListView.builder(
        itemCount: regs.length,
        itemBuilder: (context,i){
            String regNum = regs.elementAt(i);
            double totalAmt = data[regNum];
            return ListTile(
              title: Text(regNum),
              subtitle: Text('Total fuel $totalAmt Kshs'),
            );
        },
      );
    }
    return Center(child: Text('$_message'));
  }

  @override
  void initState() {
    SessionPrefs().getLoggedInUser().then((user){
      _allTransactions(user.id).then((transactions){
        if (transactions != null && transactions.isNotEmpty){
          setState(() {
            _fuelCars = transactions;
          });
        } else {
          setState(() {
            _message = 'There were no transactions found';
          });
        }
      });
    });
    super.initState();
  }

  Future<List<FuelCar>> _allTransactions(int id) async{
    List<FuelCar> responseList = [];
    try{
      Response response = await get(baseUrlLocal+'usages/$id');
      var jsonResponse;
      if (response != null){
        int responseCode = response.statusCode;
        if(responseCode == 200){
          jsonResponse = jsonDecode(response.body);
          var list = jsonResponse as List;
          responseList = list.map<FuelCar>((json) => FuelCar.fromJson(json)).toList();
          if (responseList.isEmpty){
            _dialog.dismiss();
            setState(() {
              _message = "There were no transactions found";
            });
          }
        } else {
          setState(() {
            _message = "An error occured while fetching data";
          });
          Fluttertoast.showToast(
              msg: 'Error $responseCode Occured',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM
          );
        }
      } else {
        setState(() {
          _message = "The service is currently Unreachable";
        });
        Fluttertoast.showToast(
            msg: 'The service is currently Unreachable',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM
        );
      }
    } catch (e){
      if (e is SocketException){
        setState(() {
          _message = "Service is unreachable. You may be offline";
        });
        print(e);
      } else {
        print(e);
      }
    }
    return responseList;
  }
}