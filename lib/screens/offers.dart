import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/PackageModels.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/models/VehicleModels.dart';
import 'package:my_fuel_flutter_app/screens/offerdetails.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix0;
import 'package:progress_dialog/progress_dialog.dart';

class Offers extends StatefulWidget {
  @override
  _OffersState createState() => _OffersState();
}

class _OffersState extends State<Offers> with SingleTickerProviderStateMixin{

  List<OffersForMobile> _offers;
  List<CashBack> _cashBackPromos;
  BuildContext _context;
  CashBack _selectedPromo;
  MobileUser _loggedInUser;
  ProgressDialog _dialog;
  String _message = 'Loading ... ',_cashBackMessage = 'Loading ... ';
  List<Tab> _tabs = [Tab(text: 'Value based promos'),Tab(text: 'Cash back promos',)];
  TabController _tabController;
  TextEditingController _cbTitle = new TextEditingController();
  TextEditingController _cbDescription = new TextEditingController();
  TextEditingController _cbThreshold  = new TextEditingController();
  TextEditingController _cbDiscount = new TextEditingController();
  TextEditingController _cbExpiry = new TextEditingController();
  TextEditingController _cbScore = new TextEditingController();
  final _formKey = GlobalKey<FormState>();


  @override
  void initState(){
    _tabController = TabController(length: _tabs.length, vsync: this);
    super.initState();
    SessionPrefs().getLoggedInUser().then((user){
      setState(() {
        _loggedInUser = user;
      });
    });
    prefix0.getTokenBasicAuth().then((token){
      _getAllOffers(token).then((offers){
        setState(() {
          _offers = offers;
        });
      });
      getCashBackPromos(token).then((cashbacks){
        setState(() {
          _cashBackPromos = cashbacks;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context){
    if(_selectedPromo != null){
      _cbTitle.text = _selectedPromo.title;
      _cbDescription.text = _selectedPromo.description;
      _cbThreshold.text = _selectedPromo.threshold.toString();
      _cbDiscount.text = _selectedPromo.cashDiscPerLitre.toString();
      _cbScore.text = _selectedPromo.amtAchieved.toString();
      _cbExpiry.text = _selectedPromo.expiryDate;
    }
    _context = context;
    return WillPopScope(
      onWillPop: () async{
        if (_tabController.index == 1){
          if(_selectedPromo != null){
            setState(() {
              _selectedPromo = null;
            });
            return false;
          }
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(tabs: _tabs,controller: _tabController),
          title: Text('All Offers'),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            _vbPromosbody(),
            _cbPromosBody()
          ],
        ),
      ),
    );
  }

  Widget _vbPromosbody(){
    if (_offers != null){
      if (_offers.isNotEmpty){
        return new ListView.builder(
          itemCount: _offers.length,
          itemBuilder: (context,i){
            OffersForMobile offer = _offers[i];
            String offerName = offer.promoname;
            int points = offer.points;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: new ListTile(
                title: Text('Name: $offerName'),
                subtitle: Text('Redeem $points Points'),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OfferToRedeem(offer))),
              ),
            );
          },
        );
      } else {
        return Center(
          child: Text('There were no offers found at this time'),
        );
      }
    }
    return Center(
      child: Text('$_message'),
    );
  }

    Future<List<OffersForMobile>> _getAllOffers(String token)async{
    List<OffersForMobile> offers;
    Response response;
    try{
      response = await get(prefix0.baseUrlLocal+'alloffers',headers: prefix0.getHeaders(token));
    } catch (e){
      if (e is SocketException){
        setState(() {
          _message = 'Service is currently unreachable. You may be offline';
        });
      }
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        var jsonResponse = jsonDecode(response.body);
        var list = jsonResponse as List;
        offers = list.map<OffersForMobile>((json) => OffersForMobile.fromJson(json)).toList();
      } else {
        setState(() {
          _message = 'An error occured while fetching data';
        });
        Fluttertoast.showToast(
          msg: 'Error $statusCode Occured',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM
        );
      }
    } else {
      setState((){
        _message = 'The service is currently unreachable';
      });
      Fluttertoast.showToast(
        msg: 'Server is unreachable',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM
      );
    }
    return offers;
  }

  _cbPromosBody(){
    if (_cashBackPromos != null){
      if (_cashBackPromos.isNotEmpty){
        if(_selectedPromo != null){
          return ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('This promotion awards you discount per litre of fuel purchased when you achieve the given threshold in total fuel purchases before the expiry date.'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _cbTitle,
                  enabled: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide()
                    ),
                    labelText: 'Title'
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _cbDescription,
                  enabled: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide()
                    ),
                    labelText: 'Description'
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _cbThreshold,
                  enabled: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide()
                    ),
                    labelText: 'Threshold to be met'
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _cbDiscount,
                  enabled: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide()
                    ),
                    labelText: 'Discount per litre awarded'
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _cbExpiry,
                  enabled: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide()
                    ),
                    labelText: 'Expiry Date'
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Visibility(child: TextFormField(
                  controller: _cbScore,
                  enabled: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide()
                    ),
                    labelText: 'Your current score'
                  ),
                ),visible: _selectedPromo.subscribed),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RaisedButton(onPressed: _selectedPromo.subscribed ? null : _doSubscribe,child: Text(_selectedPromo.subscribed ? 'Subscribed' : 'Subscribe for offer')),
              )
            ],
          );
        }
        return ListView.builder(
          itemBuilder: (ctx,i){
            CashBack cashBack = _cashBackPromos.elementAt(i);
            String ttl = cashBack.title;
            double threshold = cashBack.threshold;
            return ListTile(
              title: Text(ttl),
              subtitle: Text('Purchase fuel up to $threshold Kshs'),
              onTap: (){
                setState(() {
                  _selectedPromo = cashBack;
                });
              },
            );
          },
          itemCount: _cashBackPromos.length,
        );
      }
      return Center(child: Text('There were no cash-back offers found at this time'));
    }
    return Center(child: Text(_cashBackMessage));
  }

  Future<List<CashBack>> getCashBackPromos(String requestToken) async{
    int userId = _loggedInUser.id;
    Response response;
    try{
      response = await get(prefix0.baseUrlLocal+'cashbackpromos/$userId',headers: prefix0.getHeaders(requestToken));
    } on SocketException{
      Fluttertoast.showToast(msg: 'You may be offline');
      setState((){
        _cashBackMessage = 'Service is currently unreachable. Check your network connection';
      });
    }
    if (response != null){
      int statusCode  = response.statusCode;
      if (statusCode == 200){
        var jsonResponse = json.decode(response.body);
        var list = jsonResponse as List;
        return list.map((json)=> CashBack.fromJson(json)).toList();
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode occurred');
        setState((){
          _cashBackMessage = "An error occurred while fetching casback promos";
        });
      }
    } else {
      setState((){
        _cashBackMessage = "There was no feedback from the server";
      });
    }
    return null;
  }


  void _doSubscribe() {
    int userId = _loggedInUser.id;
    int promoId = _selectedPromo.id;

    ProgressDialog dialog = new ProgressDialog(_context);
    dialog.style(message: 'Processing request, please wait ...');
    dialog.show();
    prefix0.getTokenBasicAuth().then((token) async{
      Response response = await post(prefix0.baseUrlLocal+"subscribetopromo?userId=$userId&promoId=$promoId",headers: prefix0.getHeaders(token));
      dialog.dismiss();
      if (response != null){
        int statusCode = response.statusCode;
        if (statusCode == 200){
          String result = response.body;
          if (result == 'success'){
            Fluttertoast.showToast(msg: 'Subscription has been done successfully');
            Navigator.pop(_context);
          } else {
            Fluttertoast.showToast(msg: 'An issue occured during subscription');
          }
        } else {
          Fluttertoast.showToast(msg: 'Error $statusCode Occured');
        }
      } else {
        Fluttertoast.showToast(msg: 'No response from service');
      }
    });

  }
}
