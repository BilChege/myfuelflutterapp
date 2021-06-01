import 'dart:convert';
import 'dart:io';

import 'package:dropdownfield/dropdownfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart';
import 'package:location/location.dart' as prefix1;
import 'package:my_fuel_flutter_app/database/AppDB.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/models/VehicleModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix0;
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:search_map_place/search_map_place.dart';

class ConsumptionNew extends StatefulWidget {
  @override
  _ConsumptionNewState createState() => _ConsumptionNewState();
}

class _ConsumptionNewState extends State<ConsumptionNew> {

  MobileUser _loggedInUser;
  List<Vehicle> _vehicles = new List();
  var _location = new prefix1.Location();
  GlobalKey _key = GlobalKey<FormState>();
  LatLng _currentPosition;
  String _message = "Starting. Please wait ... ";
  String _origin, _destination;
  LatLng _originLatLng, _destinationLatLng;
  var _originController = new TextEditingController();
  var _destinationController = new TextEditingController();
  var _distanceCoveredController = new TextEditingController();
  List<String> _vehicleRegs = new List();
  String _selectedVehicle;
  Vehicle _vehicle;
  bool _distanceManuallySet = false;
  double _distanceCoveredInKms;
  BuildContext _context;

  @override
  void initState(){
//    prefix0.checkPermissionStatus(PermissionGroup.location).then((status){
//      if (status == PermissionStatus.denied){
//        setState(() {
//          _message = "You need to grant GPS permission for better services";
//        });
//      }
//    });
    _location.serviceEnabled().then((enabled){
      if (enabled){
        getLocation().then((position){
          setState(() {
            _currentPosition = LatLng(position.latitude,position.longitude);
          });
        });
      } else {
        _location.requestService().then((serviceEnabled){
          if (serviceEnabled){
            prefix0.getLocation().then((position){
              setState(() {
                _currentPosition = LatLng(position.latitude, position.longitude);
              });
            });
          } else {
            setState(() {
              _message = "Enable GPS for better services";
            });
          }
        });
      }
    });
    SessionPrefs().getLoggedInUser().then((user){
      setState(() {
        _loggedInUser = user;
      });
    });
    AppDB.appDB.findAll(tbVehicle).then((rows){
      if (rows != null && rows.isNotEmpty){
        for (Map row in rows){
          Vehicle v = Vehicle(
              id: row[prefix0.id],
              regno: row[prefix0.regNo],
              make: row[prefix0.make],
              consumptionRate: row[prefix0.consumptionRate]
          );
          setState(() {
            _vehicleRegs.add(v.toString());
            _vehicles.add(v);
          });
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    _context = context;
    String value = _distanceCoveredInKms.toString();
    if (!_distanceManuallySet && _distanceCoveredInKms != null){
      _distanceCoveredController.text = '$value Kms';
    }
    return Scaffold(
      appBar: AppBar(title: Text('Consumption')),
      body: Form(
        key: _key,
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('This service enables you to see the amount of fuel consumed during a trip.',style: TextStyle(fontStyle: FontStyle.italic),),
            ),
            _searchWidgets(),
            Padding(padding: EdgeInsets.all(20.0),child: Text('You can also enter the distance covered in the input below')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextFormField(
                controller: _distanceCoveredController,
                keyboardType: TextInputType.number,
                onChanged: (value){
                  setState(() {
                    _distanceManuallySet = true;
                    _distanceCoveredInKms = double.parse(value);
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide()
                  ),
                  labelText: 'Distance covered (Kms)',
                  hintText: 'Distance in Kilometres'
                ),
              ),
            ),
            Padding(padding: EdgeInsets.all(20.0),child: DropDownField(
              hintText: 'Select the car used',
              items: _vehicleRegs,
              enabled: _vehicles.isNotEmpty,
              value: _selectedVehicle,
              onValueChanged: (value){
                for (Vehicle v in _vehicles){
                  if (v.toString() == value){
                    setState(() {
                      _selectedVehicle = value;
                      _vehicle = v;
                    });
                  }
                }
              },
              setter: (newVal){
                setState(() {
                  _selectedVehicle = newVal;
                });
              },
            )),
            Padding(padding: EdgeInsets.all(20.0),child: _litresUsedWidget())
          ],
        ),
      ),
    );
  }

  _searchWidgets(){
    if (_currentPosition != null){
      return Card(
        elevation: 5.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('You may enter the origin and destination place names below, to calulate the distance'),
            ),
            _originWidget(),
            _destinationWidget()
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text('$_message'),
    );
  }

  _originWidget() {
    if (_origin != null){
      _originController.text = _origin;
      return Padding(padding: EdgeInsets.all(20.0),child: Row(
        children: <Widget>[
          Expanded(
            child: TextFormField(
              controller: _originController,
              enabled: false,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide()
                ),
                labelText: 'Origin'
              ),
            ),
          ),
          IconButton(icon: Icon(Icons.clear), onPressed: (){
            setState(() {
              _origin = null;
              _originLatLng = null;
              _distanceCoveredInKms = 0;
            });
          })
        ],
      ));
    } else {
      return Column(
        children: <Widget>[
          SearchMapPlaceWidget(
            apiKey: prefix0.googleMapsApiKey,
            language: 'en',
            location: _currentPosition,
            radius: 30000,
            placeholder: 'Enter origin or starting place',
            onSelected: (place) async{
              String name = place.description;
              ProgressDialog dialog = new ProgressDialog(_context);
              dialog.style(message: 'Locating ... ');
              dialog.show();
              Geolocation geolocation;
              try{
                geolocation = await place.geolocation;
              } catch (e){
                if (e is SocketException){
                  dialog.dismiss();
                  Fluttertoast.showToast(msg: 'You may be offline');
                }
              }
              if (geolocation != null){
                dialog.dismiss();
                LatLng latLng = geolocation.coordinates;
                setState(() {
                  _originLatLng = latLng;
                  _origin = name;
                });
                if (_destinationLatLng != null){
                  _calculateDistanceTo();
                }
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: FlatButton(onPressed: () async{
              ProgressDialog dialog = ProgressDialog(_context);
              dialog.style(message: 'Locating ... ');
              dialog.show();
              List<Address> addresses;
              try{
                addresses = await Geocoder.google(prefix0.googleMapsApiKey,language: 'en').findAddressesFromCoordinates(Coordinates(_currentPosition.latitude, _currentPosition.longitude));
              } catch (e){
                dialog.dismiss();
                if (e is SocketException){
                  Fluttertoast.showToast(msg: 'You may be offline');
                }
              }
              if (addresses != null){
                dialog.dismiss();
                Address address = addresses.first;
                String name = address.featureName;
                setState(() {
                  _originLatLng = _currentPosition;
                  _origin = name;
                });
                if (_destinationLatLng != null){
                  _calculateDistanceTo();
                }
              }
            },child: Row(children: <Widget>[Text('Click to select Current Location as origin'),Icon(Icons.gps_fixed)],)),
          )
        ],
      );
    }
  }

  _destinationWidget(){
    if (_destination != null){
      _destinationController.text = _destination;
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _destinationController,
                enabled: false,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide()
                  ),
                  labelText: 'Destination'
                ),
              ),
            ),
            IconButton(icon: Icon(Icons.clear), onPressed: (){
              setState(() {
                _distanceCoveredInKms = 0;
                _destination = null;
                _destinationLatLng = null;
              });
            })
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            SearchMapPlaceWidget(
              apiKey: prefix0.googleMapsApiKey,
              language: 'en',
              location: _currentPosition,
              radius: 3000,
              placeholder: 'Enter the destination',
              onSelected: (place) async{
                ProgressDialog dialog = ProgressDialog(_context);
                dialog.style(message: 'Locating ... ');
                dialog.show();
                Geolocation location = await place.geolocation;
                dialog.dismiss();
                String name = place.description;
                LatLng latLng = location.coordinates;
                double latDest = latLng.latitude;
                double lonDest = latLng.longitude;
                print('Latitude: $latDest, Longitude: $lonDest');
                if (_originLatLng != null){
                  setState(() {
                    _destination = name;
                    _destinationLatLng = latLng;
                  });
                  _calculateDistanceTo();
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: FlatButton(onPressed: () async{
                ProgressDialog dialog = ProgressDialog(_context);
                dialog.style(message: 'Locating ... ');
                dialog.show();
                List<Address> addresses;
                try{
                  addresses =  await Geocoder.google(prefix0.googleMapsApiKey,language: 'en').findAddressesFromCoordinates(Coordinates(_currentPosition.latitude, _currentPosition.longitude));
                } catch(e){
                  dialog.dismiss();
                  if (e is SocketException){
                    Fluttertoast.showToast(msg: 'You may be offline');
                  }
                }
                if (addresses != null){
                  dialog.dismiss();
                  Address address = addresses.first;
                  String name = address.featureName;
                  Coordinates coordinates = address.coordinates;
                  LatLng latLng = LatLng(coordinates.latitude, coordinates.longitude);
                  setState(() {
                    _destination = name;
                    _destinationLatLng = latLng;
                  });
                  if (_originLatLng != null){
                    _calculateDistanceTo();
                  }
                }
              }, child: Row(children: <Widget>[Text('Click to set Current Location as destination'),Icon(Icons.gps_fixed)],)),
            )
          ],
        ),
      );
    }
  }

  _calculateDistanceTo() async{
    double latOrg = _originLatLng.latitude;
    double lonOrg = _originLatLng.longitude;
    double latDest = _destinationLatLng.latitude;
    double lonDest = _destinationLatLng.longitude;
    ProgressDialog dialog = new ProgressDialog(_context);
    dialog.style(message: 'Calculating distance ... ');
//    dialog.show();
    Response response;
    try{
      response = await get(prefix0.distanceMatrixApiURL+'?origins=$latOrg,$lonOrg&destinations=$latDest,$lonDest&key=$googleMapsApiKey');
    } catch (e){
      dialog.dismiss();
      if (e is SocketException){
        Fluttertoast.showToast(msg: 'You may be offline');
      }
    }
    if (response != null){
//      dialog.dismiss();
      Map<String,dynamic> jsonResponse = jsonDecode(response.body);
      String status = jsonResponse['status'];
      if (status == 'OK'){
        List<dynamic> rows = jsonResponse['rows'];
        Map<String,dynamic> row = rows.elementAt(0);
        List<dynamic> elements = row['elements'];
        Map<String,dynamic> element = elements.elementAt(0);
        Map<String,dynamic> distance = element['distance'];
        int distanceValue = distance['value'];
        setState(() {
          _distanceManuallySet = false;
          _distanceCoveredInKms = distanceValue / 1000;
        });
      } else {
        Fluttertoast.showToast(msg: 'Google services failed with error status: $status');
      }
    }
  }

  _litresUsedWidget(){
    if (_vehicle != null && _distanceCoveredInKms != null){
      int rate = _vehicle.consumptionRate;
      String litres = (_distanceCoveredInKms/rate).toStringAsFixed(2);
      return Text('Number of litres of fuel Used : $litres Litres',style: TextStyle(fontSize: 20.0));
    }
    return Text('Enter the Distance covered in Kilometres and select the vehicle used above',style: TextStyle(fontSize: 20.0));
  }
}
