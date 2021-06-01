import 'dart:convert';
import 'dart:io';

import 'package:dropdownfield/dropdownfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:my_fuel_flutter_app/database/AppDB.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/DealerModels.dart';
import 'package:my_fuel_flutter_app/models/PackageModels.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix1;
import 'package:progress_dialog/progress_dialog.dart';

class OfferToRedeem extends StatefulWidget {

  OffersForMobile offer;
  OfferToRedeem(this.offer);

  @override
  _OfferToRedeemState createState() => _OfferToRedeemState(offer);
}

class _OfferToRedeemState extends State<OfferToRedeem>{

  MobileDealer _dealer;
  List<MobileDealer> _dealers;
  String _selectedDealer;
  List<String> _dealerNames;
  MobileUser _loggedInUser;
  TextEditingController _promoName = new TextEditingController();
  TextEditingController _promoDesc = new TextEditingController();
  TextEditingController _points = new TextEditingController();
  DateFormat  format = new DateFormat('yyyy-MM-dd HH:mm:ss');
  BuildContext _context;
  ProgressDialog _dialog;

  OffersForMobile _offer;

  _OfferToRedeemState(this._offer);


  @override
  void initState() {
    super.initState();
    List<String> dealerNames = [];
    List<MobileDealer> dealers = [];
    AppDB.appDB.findAll(dealer).then((rows){
      for (Map<String,dynamic> d in rows){
        MobileDealer mobileDealer = MobileDealer(
            id: d[prefix1.id],
            name: d[prefix1.name],
            stationid: d[prefix1.stationId],
            latitude: d[prefix1.latitude],
            longitude: d[prefix1.longitude]
        );
        dealers.add(mobileDealer);
        dealerNames.add(mobileDealer.toString());
      }
    });
    SessionPrefs().getLoggedInUser().then((user){
      setState(() {
        _dealers = dealers;
        _dealerNames = dealerNames;
        _loggedInUser = user;
        _promoName.text = _offer.promoname;
        _promoDesc.text = _offer.promodesc;
        _points.text = _offer.points.toString();
        });
    });
  }

  @override
  Widget build(BuildContext context){
    _context = context;
    return Scaffold(
      appBar: AppBar(title: Text('Get Offer')),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0,10.0,0.0,0.0),
              child: TextField(
                enabled: false,
                controller: _promoName,
                decoration: new InputDecoration(
                    border: new OutlineInputBorder(
                        borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Promo Name'
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
              child: TextField(
                enabled: false,
                controller: _promoDesc,
                decoration: new InputDecoration(
                    border: new OutlineInputBorder(
                        borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Promo Description'
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
              child: TextField(
                enabled: false,
                controller: _points,
                decoration: new InputDecoration(
                    border: new OutlineInputBorder(
                        borderSide: new BorderSide(color: Colors.pink)
                    ),
                    labelText: 'Promo Points'
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
              child: DropDownField(
                value: _selectedDealer,
                required: true,
                strict: true,
                labelText: 'Station Id Number',
                items: _dealerNames,
                onValueChanged: (val){
                  for (MobileDealer d in _dealers){
                    if (d.toString() == val){
                      setState(() {
                        _selectedDealer = val;
                        _dealer = d;
                      });
                    }
                  }
                },
                setter: (dynamic newVal){
                  _selectedDealer = newVal;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
              child: RaisedButton(
                  onPressed: () => _doRedeem(_offer),
                  child: Text('Redeem Offer'),
                  color: Colors.amber
              ),
            )
          ],
        ),
      ),
    );
  }

  _doRedeem(OffersForMobile offersForMobile){
    DateTime current = new DateTime.now();
    String currstr = format.format(current);
      MobileRedemption redemption = MobileRedemption(
        user: _loggedInUser,
        offer: offersForMobile,
        stationId: _dealer.stationid,
      );
      String json = jsonEncode(redemption);
      print(json);
      int points = offersForMobile.points;
      String service = offersForMobile.promoname;
      showDialog(
        context: _context,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text('Redeem Points'),
            content: Text('Do you wish to redeem $points Points for Service: $service'),
            actions: <Widget>[
              FlatButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('No')),
              FlatButton(
                child: Text('Yes'),
                onPressed: () {
                  Navigator.pop(context);
                  _dialog = new ProgressDialog(
                    context,
                    isDismissible: false
                  );
                  _dialog.style(
                      message: 'Processing Transaction. Please wait ... ',
                      backgroundColor: Colors.white,
                      borderRadius: 10.0,
                      progressWidget: CircularProgressIndicator(),
                      elevation: 10.0,
                      insetAnimCurve: Curves.easeInOut
                  );
                  _dialog.show();
                  prefix1.getTokenBasicAuth().then((token){
                    redeemOffer(json,token).then((onValue){
                      if (onValue){
                        _dialog.dismiss();
                        showDialog(
                            context: _context,
                            builder: (BuildContext context){
                              return AlertDialog(
                                title: Text('Success'),
                                content: Text('You have successfully redeemed $points Points'),
                                actions: <Widget>[
                                  FlatButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(_context);
                                      },
                                      child: Text('Ok'))
                                ],
                              );
                            }
                        );
                      }
                    });
                  });
                },
              )
            ],
          );
        }
      );
  }

  Future<bool> redeemOffer(String offer, String token) async{
    bool result;
    var jsonResponse;
    Response response;
    try{
      response = await post(baseUrlLocal+'redeempointsforpromo',body: offer,headers: prefix1.postHeaders(token));
    } catch (e){
      _dialog.dismiss();
      if (e is SocketException){
        Fluttertoast.showToast(msg: 'Service is unreachable. You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      }
    }
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
        msg: 'Server is unreachable',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM
      );
    }
    return result;
  }

}
