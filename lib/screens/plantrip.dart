import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';
import 'package:my_fuel_flutter_app/database/AppDB.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/models/VehicleModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix0;
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:search_map_place/search_map_place.dart';

class PlanTrip extends StatefulWidget {
  @override
  _PlanTripState createState() => _PlanTripState();
}

class _PlanTripState extends State<PlanTrip> {

  MobileUser _loggedInUser;
  Completer<GoogleMapController> _mapController;
  GoogleMapController _googleMapController;
  List<Vehicle> _vehicles = new List();
  LatLng _destinationLatLng, _originLatLng, _currentLocation;
  String _origin, _destination;
  var _location = new Location();
  String _message = "Loading ... ";
  BuildContext _context;
  Set<Marker> _markers = new Set();
  Set<Polyline> _polylines = new Set();
  List<LatLng> _polyLineCoordinates = new List();
  LatLng _station, _northEast, _southWest;
  LatLngBounds _initialBounds;
  var _originController = new TextEditingController();
  var _destinationController = new TextEditingController();
  var _distanceController = new TextEditingController();
  bool _distanceManuallySet = false;
  double _distanceCoveredInKms;

  @override
  void initState() {
    _location.serviceEnabled().then((enabled){
      if (enabled){
        prefix0.getLocation().then((position){
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });
        });
      } else {
        _location.requestService().then((serviceEnabled){
          if (serviceEnabled){
            prefix0.getLocation().then((position){
              setState(() {
                _currentLocation = LatLng(position.latitude,position.longitude);
              });
            });
          } else {
            setState(() {
              _message = "You need to allow GPS for better services";
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
    prefix0.checkPermissionStatus(PermissionGroup.location).then((status){
      if (status == PermissionStatus.denied){
        setState(() {

        });
      }
    });
    AppDB.appDB.findAll(tbVehicle).then((rows){
      for (Map m in rows){
        setState((){
          _vehicles.add(Vehicle(
            id: m[prefix0.id],
            makeid: m[prefix0.makeId],
            modelid: m[prefix0.modelId],
            make: m[prefix0.make],
            regno: m[prefix0.regNo],
            consumptionRate: m[prefix0.consumptionRate]
          ));
        });
      }
    });
    AppDB.appDB.findAll(prefix0.dealer).then((rows){
      for (Map m in rows){
        setState(() {
          _markers.add(Marker(
            markerId: MarkerId(m[prefix0.name]),
            position: LatLng(m[prefix0.latitude], m[prefix0.longitude]),
            infoWindow: InfoWindow(title: m[prefix0.name])
          ));
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    _mapController = Completer();
    if (!_distanceManuallySet && _distanceCoveredInKms != null){
      String distance = _distanceCoveredInKms.toString();
      _distanceController.text = '$distance Kms';
    }
    _context = context;
    return Scaffold(
      appBar: AppBar(title: Text('Plan Trip')),
      body: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[
          Padding(padding: EdgeInsets.all(20.0),child: Text('Find how much fuel is required for each of your vehicles for a trip you want to make.')),
          _searchWidgets(),
          Padding(padding: EdgeInsets.all(10.0),child: Card(
            elevation: 5.0,
//            child: _searchWidgets(),
            child: SizedBox(
              height: 250.0,
              child: Stack(
                children: <Widget>[
                  _mapDisplay()
                ],
              ),
            ),
          )),
          Padding(padding: EdgeInsets.all(10.0),child: TextFormField(
            controller: _distanceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide()
              ),
              labelText: 'Distance to be covered (in Kms)'
            ),
            onChanged: (value){
              setState(() {
                _distanceManuallySet = true;
                _distanceCoveredInKms = double.parse(value);
              });
            },
          )),
          _vehicleConsumptionValues()
        ],
      ),
    );
  }
  _searchWidgets(){
    if (_currentLocation != null){
      return Column(
        children: <Widget>[
          _originWidget(),
          _destinationWidget()
        ],
      );
    }
    return Padding(padding: EdgeInsets.all(20.0),child: Text('$_message'));
  }

  _originWidget() {
    if (_origin != null && _originLatLng != null){
      _originController.text = _origin;
      return Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
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
              Marker toBeRemoved;
              _markers.forEach((marker){
                if (_originLatLng.latitude == marker.position.latitude && _originLatLng.longitude == marker.position.longitude){
                  toBeRemoved = marker;
                }
              });
              setState(() {
                _markers.remove(toBeRemoved);
                _polyLineCoordinates.clear();
                _polylines.clear();
                _originLatLng = null;
                _origin = null;
                _distanceCoveredInKms = 0;
              });
              _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(_initialBounds, 20.0));
            })
          ],
        ),
      );
    }
    return Column(
      children: <Widget>[
        SearchMapPlaceWidget(
          apiKey: prefix0.googleMapsApiKey,
          language: 'en',
          location: _currentLocation,
          radius: 30000,
          placeholder: 'Enter the origin',
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
                _markers.add(Marker(markerId: MarkerId(name),infoWindow: InfoWindow(title: name),position: latLng));
              });
              _googleMapController.animateCamera(CameraUpdate.newLatLng(latLng));
              if (_destinationLatLng != null){
                _calculateDistanceTo();
              }
              _drawRouteTo();
            }
          },
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 20.0),child: FlatButton(onPressed: () async{
          ProgressDialog dialog = ProgressDialog(_context);
          dialog.style(message: 'Locating ... ');
          dialog.show();
          List<Address> addresses;
          try{
            addresses = await Geocoder.google(prefix0.googleMapsApiKey,language: 'en').findAddressesFromCoordinates(Coordinates(_currentLocation.latitude, _currentLocation.longitude));
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
              _originLatLng = _currentLocation;
              _origin = name;
              _markers.add(Marker(markerId: MarkerId(name),infoWindow: InfoWindow(title: name),position: LatLng(_currentLocation.latitude, _currentLocation.longitude)));
            });
            _googleMapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
            if (_destinationLatLng != null){
              _calculateDistanceTo();
            }
            _drawRouteTo();
          }
        }, child: Row(children: <Widget>[Expanded(child: Text('Click to set current location as origin')),Icon(Icons.gps_fixed)],)))
      ],
    );
  }

  _destinationWidget(){
    if (_destination != null && _destinationLatLng != null){
      _destinationController.text = _destination;
      return Padding(
        padding: const EdgeInsets.all(10.0),
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
                  labelText: 'destination'
                ),
              ),
            ),
            IconButton(icon: Icon(Icons.clear), onPressed: (){
              Marker toBeRemoved;
              _markers.forEach((marker){
                if (_destinationLatLng.latitude == marker.position.latitude && _destinationLatLng.longitude == marker.position.longitude){
                  toBeRemoved = marker;
                }
              });
              setState(() {
                _markers.remove(toBeRemoved);
                _polyLineCoordinates.clear();
                _polylines.clear();
                _destinationLatLng = null;
                _destination = null;
                _distanceCoveredInKms = 0;
              });
              _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(_initialBounds, 20.0));
            })
          ],
        ),
      );
    }
    return Column(
      children: <Widget>[
        SearchMapPlaceWidget(
          apiKey: googleMapsApiKey,
          placeholder: 'Enter destination',
          location: _currentLocation,
          language: 'en',
          radius: 30000,
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
              setState((){
                print(' @@@@@@@@@@@@@@@@@@@@@@@ DESTINATION STATE IS SET');
                _destination = name;
                _destinationLatLng = latLng;
                _station = latLng;
              });
              _calculateDistanceTo();
              setState(() {
                _markers.add(Marker(markerId: MarkerId(name),infoWindow: InfoWindow(title: name),position: latLng));
              });
              _googleMapController.animateCamera(CameraUpdate.newLatLng(latLng));
              _drawRouteTo();
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
              addresses =  await Geocoder.google(prefix0.googleMapsApiKey,language: 'en').findAddressesFromCoordinates(Coordinates(_currentLocation.latitude, _currentLocation.longitude));
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
              setState((){
                _destination = name;
                _destinationLatLng = latLng;
                _station = latLng;
                _markers.add(Marker(markerId: MarkerId(name),position: latLng,infoWindow: InfoWindow(title: name)));
              });
              _drawRouteTo();
              _googleMapController.animateCamera(CameraUpdate.newLatLng(latLng));
              if (_originLatLng != null){
                _calculateDistanceTo();
              }
            }
          }, child: Row(children: <Widget>[Expanded(child: Text('Click to set current location as destination')),Icon(Icons.gps_fixed)],)),
        )
      ],
    );
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

  _vehicleConsumptionValues(){
    List<Widget> widgets = new List();
    if (_vehicles.isNotEmpty){
      if (_distanceCoveredInKms != null){
        _vehicles.forEach((vehicle){
          String reg = vehicle.regno;
          String make = vehicle.make;
          int consumptionRate = vehicle.consumptionRate;
          double litresRequired = _distanceCoveredInKms / consumptionRate;
          String ltsValueRequired = litresRequired.toStringAsFixed(2);
          double kshsRequired = litresRequired * prefix0.cashPerLitre;
          String kshsValueRequired = kshsRequired.toStringAsFixed(2);
          widgets.add(
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ListTile(
                  title: Text('$reg ($make)'),
                  subtitle: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text('Consumption rate: $consumptionRate Kms per Litre'),
                      Text('Number of litres required: $ltsValueRequired Litres'),
                      Text('Cost of the fuel required: $kshsValueRequired Kshs'),
                      Divider(thickness: 1.0)
                    ],
                  ),
                ),
              )
          );
        });
        return Column(children: widgets,mainAxisAlignment: MainAxisAlignment.start);
      }
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text('Specify the distance to be covered above'),
      );
    }
    return Padding(padding: EdgeInsets.all(20.0),child: Text('You have no vehicles yet'));
  }

  void _drawRouteTo(){
    print('#################### DRAW ROUTE CALLED ###################');
    print('ORIGIN LATLNG -------------->>>>>>>> $_originLatLng');
    print('DESTINATION LATLNG ----------->>>>>>>>>> $_destinationLatLng');
    if (_originLatLng != null && _destinationLatLng != null){
      print('################## CODITION PASSED ##################');
      prefix0.getRoutePointsBetween(_originLatLng, _destinationLatLng).then((pointLatLngs){
        PointLatLng initial = pointLatLngs[0];
        double maxLat = initial.latitude;
        double maxLon = initial.longitude;
        double minLat = initial.latitude;
        double minLon = initial.longitude;
        pointLatLngs.forEach((PointLatLng pointLatLng){
          if (pointLatLng.latitude > maxLat){
            maxLat = pointLatLng.latitude;
          }
          if (pointLatLng.longitude > maxLon){
            maxLon = pointLatLng.longitude;
          }
          if (pointLatLng.latitude < minLat){
            minLat = pointLatLng.latitude;
          }
          if (pointLatLng.longitude < minLon){
            minLon = pointLatLng.longitude;
          }
          _polyLineCoordinates.add(new LatLng(pointLatLng.latitude, pointLatLng.longitude));
        });
        LatLng northEast = LatLng(maxLat, maxLon);
        LatLng southWest = LatLng(minLat, minLon);
        setState(() {
          _polylines.add(Polyline(polylineId: PolylineId('Route to destination'),points: _polyLineCoordinates,width: 5));
        });
        _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: southWest,northeast: northEast),25));
      });
    }
  }

  _mapDisplay() {
    if (_markers.isNotEmpty){
      return GoogleMap(
        initialCameraPosition: CameraPosition(target: LatLng(0.1768696, 37.9083264),zoom: 5),
        markers: _markers,
        onMapCreated: (GoogleMapController controller){
          _mapController.complete(controller);
          _googleMapController = controller;
          Marker m = _markers.elementAt(0);
          double maxLat = m.position.latitude;
          double maxLon = m.position.longitude;
          double minLat = m.position.latitude;
          double minLon = m.position.longitude;
          _markers.forEach((marker){
            if (marker.position.latitude > maxLat){
              maxLat = marker.position.latitude;
            }
            if (marker.position.longitude > maxLon){
              maxLon = marker.position.longitude;
            }
            if (marker.position.latitude < minLat){
              minLat = marker.position.latitude;
            }
            if (marker.position.longitude < minLon){
              minLon = marker.position.longitude;
            }
          });
          LatLng sWest = LatLng(minLat, minLon);
          LatLng nEast = LatLng(maxLat, maxLon);
          _initialBounds = LatLngBounds(southwest: sWest, northeast: nEast);
          print('#############  TO ANIMATE ###############');
          controller.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sWest, northeast: nEast),20.0));
        },
        polylines: _polylines,
      );
    }
    return Padding(padding: EdgeInsets.all(10.0),child: Column(
      children: <Widget>[
        Text('Loading map ...'),
        CircularProgressIndicator()
      ],
    ));
  }
}