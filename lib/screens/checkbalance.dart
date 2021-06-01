import 'package:flutter/material.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';

class CheckBalance extends StatefulWidget {
  @override
  _CheckBalanceState createState() => _CheckBalanceState();
}

class _CheckBalanceState extends State<CheckBalance> {

  double _account;
  int _points;
  bool _balancesUnAvailable = false;

  @override
  void initState() {
    SessionPrefs().getBalances().then((balances){
      if (balances != null){
        setState(() {
          _account = balances.account;
          _points = balances.points;
        });
      } else {
        setState(() {
          _balancesUnAvailable = true;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Balances')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0)
          ),
          child: balancesView(),
        ),
      ),
    );
  }

  Widget balancesView(){
    if (_balancesUnAvailable){
      return Center(
        child: Text('Your balances are currently unavailable'),
      );
    }
    return ListView(
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.all(20.0),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text('Account Balance'),
              Text('$_account')
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text('Points Balance'),
              Text('$_points')
            ],
          ),
        )
      ],
    );
  }
}
