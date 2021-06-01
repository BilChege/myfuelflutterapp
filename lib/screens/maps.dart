import 'dart:async';
import 'dart:convert';
import 'dart:core' as prefix3;
import 'dart:core';
import 'dart:io';

import 'package:android_intent/android_intent.dart';
import 'package:search_widget/search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as prefix1;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:location/location.dart';
import 'package:my_fuel_flutter_app/database/AppDB.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/DealerModels.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix0;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher.dart' as prefix2;

class MapsScreen extends StatefulWidget {
  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> with SingleTickerProviderStateMixin,WidgetsBindingObserver{

  Completer<GoogleMapController> _controller;
  List<MobileDealer> _dealers;
  Map<MarkerId,Marker> _markers = <MarkerId,Marker>{};
  MobileUser _loggedInUser;
  var _searchController = new TextEditingController();
  AnimationController _animationController;
  Position _destinationPosition;
  Animation<Color> _animateColor;
  Animation<double> _animateIcon;
  Animation<double> _translateButton;
  Position _currentPosition;
  Position _stationPosition;
  LatLng _northEast;
  LatLng _southWest;
  GoogleMapController _googleMapController;
  var _location = new Location();
  bool _firstTime = true;
  bool _isOpened = false;
  bool _googleMapsInstalled;
  bool _option1visible = false;
  bool _gMapsPopupDone = false,_emptyDealersPopupDone = false,_routeFocusingDone = false;
  prefix3.bool _searchPressed = false;
  Set<Polyline> _polyLines = {};
  List<LatLng> _polyLineCoordinates = [];
  bool _iosPopupDone = false;
  bool _isAndroid = false;
  String _message = "Loading ... ";
  BuildContext _context;
  ProgressDialog _dialog;
  String _searchString = "";

  @override
  void initState(){
    super.initState();
    setState(() {
      _animationController = AnimationController( duration: Duration(milliseconds: 500))..addListener((){
        setState(() {

        });
      });
      _translateButton = Tween<double>(begin: 56.0,end: -14.0).animate(CurvedAnimation(parent: _animationController, curve: Interval(0.0, 0.75,curve: Curves.easeInOut)));
      _animateIcon = Tween<double>(begin: 0.0,end: 1.0).animate(_animationController);
      _animateColor = ColorTween(
        begin: Colors.amber,
        end: Colors.amberAccent,
      ).animate(CurvedAnimation(parent: _animationController, curve: Interval(0.00, 1.00, curve: Curves.easeInOut)));
    });
    checkIfInstalled("com.google.android.apps.maps").then((installed){
      setState((){
        _googleMapsInstalled = installed;
      });
    });
    setState(() {
      _isAndroid = Platform.isAndroid;
    });
    List<MobileDealer> dealers = [];
    SessionPrefs().getLoggedInUser().then((user){
      setState(() {
        _loggedInUser = user;
      });
    });
    AppDB.appDB.findAll(dealer).then((rows){
      for (Map<String,dynamic> row in rows){
        var nameValue = row[name];
        setState(() {
          _markers[MarkerId(nameValue)] = Marker(
            markerId: MarkerId(nameValue),
            position: LatLng(row[latitude], row[longitude]),
            infoWindow: InfoWindow(title: nameValue)
          );
        });
        dealers.add(MobileDealer(
          id: row[id],
          name: row[name],
          stationid: row[stationId],
          latitude: row[latitude],
          longitude: row[longitude],
          userrating: row[userrating]
        ));
      }
      setState(() {
        _dealers = dealers;
      });
    });
    _location.serviceEnabled().then((enabled){
      if (enabled){
        getLocation().then((position){
          double lat = position.latitude;
          double lon = position.longitude;
          print('###################____LOCATION GOTTEN_____________$lat $lon');
          setState(() {
            print('################________SET STATE REACHED_______################');
            _currentPosition = position;
          });
        });
      } else {
        _location.requestService().then((serviced){
          if (serviced){
            getLocation().then((position){
              double lat = position.latitude;
              double lon = position.longitude;
              print('###################____LOCATION GOTTEN_____________$lat $lon');
              setState((){
                print('################________SET STATE REACHED_______################');
                _currentPosition = position;
              });
            });
          } else {
            setState(() {
              _message = 'You need to turn on your mobile GPS setting inorder to access the stations map service';
            });
          }
        });
      }
    });
//    _location.onLocationChanged().listen((currLocation){
//      setState((){
//        _currentPosition = Position(
//          longitude: currLocation.longitude,
//          latitude: currLocation.latitude
//        );
//      });
//    });
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state ==  AppLifecycleState.resumed){
      _location.serviceEnabled().then((enabled){
        if (enabled){
          getLocation().then((position){
            double lat = position.latitude;
            double lon = position.longitude;
            print('###################____LOCATION GOTTEN_____________$lat $lon');
            setState(() {
              print('################________SET STATE REACHED_______################');
              _currentPosition = position;
            });
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    _controller = Completer();
    WidgetsBinding.instance.addPostFrameCallback((_){
      if (!_isAndroid){
        if (!_iosPopupDone){
          showDialog(context: context,builder: (BuildContext bc){
            return AlertDialog(
              title: Text('Platform Constraints'),
              content: Text('We have noticed you are not an android user. Navigation services for google maps might not function on this platform.(Please try to use apple maps if you are using iOS). We are working on it and navigation will be available soon'),
              actions: <Widget>[
                FlatButton(onPressed: (){
                  Navigator.pop(bc);
                }, child: Text('Ok'))
              ],
            );
          });
          _iosPopupDone = true;
        }
      }
      if (_dealers != null){
        if (_dealers.isEmpty){
          if (!_emptyDealersPopupDone){
            showDialog(context: context,builder: (BuildContext bc){
              return AlertDialog(title: Text('No stations mapped'),content: Text('No stations have been registered yet. Service will be available soon.(Also hit the refresh button in the home page)'),actions: <Widget>[FlatButton(onPressed: (){
                Navigator.pop(bc);
              }, child: Text('Ok'))],);
            });
            _emptyDealersPopupDone = true;
          }
        }
      }
    });
    return WillPopScope(
      onWillPop: () async{
        if (_searchPressed == true){
          setState(() {
            _searchPressed = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: _searchPressed ? TextField(controller: _searchController,decoration: InputDecoration(hintText: 'Search dealer name'),onChanged: (value){
          setState(() {
            _searchString = value;
          });
        },) :Text('Stations Map'),actions: <Widget>[Visibility(
          visible: !_searchPressed,
          child: IconButton(icon: Icon(Icons.search ), onPressed: (){
            setState((){
              _searchPressed = true;
            });
          }),
        )],),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_currentPosition != null){
      if (_searchPressed){
        if (_dealers != null && _dealers.isNotEmpty){
          if (_searchString.isNotEmpty){
            prefix3.List<MobileDealer> searchResults = new prefix3.List();
            _dealers.forEach((dealer){
              if (dealer.name.toLowerCase().contains(_searchString)){
                searchResults.add(dealer);
              }
            });
            return ListView.builder(itemBuilder: (context,i){
              MobileDealer dealer = searchResults.elementAt(i);
              prefix3.String dealerName = dealer.name;
              prefix3.String dealerId = dealer.stationid;
              return ListTile(title: Text(dealerName),subtitle: Text(dealerId),onTap: (){
                showDialog(context: _context,builder: (BuildContext bc){
                  return new SimpleDialog(
                    title: Text('$dealerId ($dealerName)'),
                    children: <Widget>[
                      SimpleDialogOption(child: Text('Show Location'),onPressed: (){
                        Navigator.pop(bc);
                        setState(() {
                          _northEast = null;
                          _southWest = null;
                          _polyLines.clear();
                          _polyLineCoordinates.clear();
                          _stationPosition = Position(latitude: dealer.latitude,longitude: dealer.longitude);
                          _searchPressed = false;
                        });
                      },),
                      SimpleDialogOption(child: Text('Route to Location'),onPressed: (){
                        Navigator.pop(bc);
                        if (_polyLines.isNotEmpty){
                          setState((){
                            _stationPosition = null;
                            _polyLines.clear();
                            _polyLineCoordinates.clear();
                          });
                        }
                        LatLng currPos = LatLng(_currentPosition.latitude, _currentPosition.longitude);
                        LatLng closestDealerPos = LatLng(dealer.latitude, dealer.longitude);
                        _drawRouteBetween(currPos, closestDealerPos,true);
                      },)
                    ],
                  );
                });
              });
            },itemCount: searchResults.length,);
          }
          return ListView.builder(itemBuilder: (context,i){
            MobileDealer dealer = _dealers[i];
            String dealerName = dealer.name;
            String dealerId = dealer.stationid;
            return ListTile(title: Text(dealerName),subtitle: Text(dealerId),onTap:() {
              showDialog(context: _context,builder: (BuildContext bc){
                return new SimpleDialog(
                  title: Text('$dealerId ($dealerName)'),
                  children: <Widget>[
                    SimpleDialogOption(child: Text('Show Location'),onPressed: (){
                      Navigator.pop(bc);
                      setState(() {
                        _northEast = null;
                        _southWest = null;
                        _polyLines.clear();
                        _polyLineCoordinates.clear();
                        _stationPosition = Position(latitude: dealer.latitude,longitude: dealer.longitude);
                        _searchPressed = false;
                      });
                    }),
                    SimpleDialogOption(child: Text('Route to Location'),onPressed: (){
                      Navigator.pop(bc);
                      if (_polyLines.isNotEmpty){
                        setState(() {
                          _stationPosition = null;
                          _polyLines.clear();
                          _polyLineCoordinates.clear();
                        });
                      }
                      LatLng currPos = LatLng(_currentPosition.latitude, _currentPosition.longitude);
                      LatLng closestDealerPos = LatLng(dealer.latitude, dealer.longitude);
                      _drawRouteBetween(currPos, closestDealerPos,true);
                    },)
                  ],
                );
              });
            },);
          },itemCount: _dealers.length,);
        }
        return Text('No stations have been registered yet. Service will be available soon');
      }
      return Stack(
        children: <Widget>[
//          Align(
//            alignment: Alignment.topCenter,
//            child: ,
//          ),
          GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapType: MapType.normal,
            initialCameraPosition: _stationPosition != null ? CameraPosition(target: LatLng(_stationPosition.latitude, _stationPosition.longitude),zoom: 14) : CameraPosition(target: LatLng(_currentPosition.latitude,_currentPosition.longitude),zoom: 14.0),
            onMapCreated: (GoogleMapController controller){
              prefix3.print('@@@@@@@@@@@@@@@@@@@@@@@@@___________________ MAP CREATED METHOD CALLED _____________________@@@@@@@@@@@@@@@@@@@@@@@@');
              _controller.complete(controller);
              if (_northEast != null && _southWest != null){
                controller.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: _southWest,northeast: _northEast), 20));
              }
              _googleMapController = controller;
            },
            markers: Set<Marker>.of(_markers.values),
            polylines: _polyLines,
          ),
          Positioned(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Transform(transform: Matrix4.translationValues(0.0, _translateButton.value, 0.0),child: FloatingActionButton(
                      onPressed: (){
                        _animationController.reverse();
                        showDialog(context: _context,builder: (BuildContext bc){
                          return AlertDialog(
                            title: Text('Nearest Station'),
                            content: Text('Would you like to view route to the nearest station? '),
                            actions: <Widget>[
                              FlatButton(onPressed: (){
                                Navigator.pop(bc);
                              }, child: Text('No')),
                              FlatButton(onPressed: (){
                                Navigator.pop(bc);
                                _routeToNearestStation();
                              }, child: Text('Yes'))
                            ],
                          );
                        });
                      },
                      child: Icon(Icons.directions),
                    ),),
                    FloatingActionButton(onPressed: (){
                      if (!_isOpened){
                        _animationController.forward();
                      } else {
                        _animationController.reverse();
                      }
                      setState(() {
                        _option1visible = !_option1visible;
                      });
                      setState(() {
                        _isOpened = !_isOpened;
                      });
                    },child: AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _animateIcon)),
                  ],
                ),
              ),
            ),
          )
        ],
      );
    }
    print('#################______________LOCATION NOT GOTTEN__________________');
    return Text('$_message');
  }

  _routeToNearestStation(){
    if (_polyLines.isNotEmpty){
      setState(() {
        _polyLines.clear();
        _polyLineCoordinates.clear();
      });
    }
    String urlDestinations = "";
    int counter = 0;
    if (_dealers != null && _dealers.isNotEmpty){
      for (MobileDealer md in _dealers){
        double lat = md.latitude;
        double lon = md.longitude;
        urlDestinations += '$lat,$lon';
        if (counter < _dealers.length - 1){
          urlDestinations += "|";
        }
        counter += 1;
      }
      _dialog = ProgressDialog(
        _context
      );
      _dialog.style(message: 'Calculating distances ... ');
      _dialog.show();
      _distancesToStations(_currentPosition, urlDestinations).then((distances){
        int size = distances.length;
        print('########################### SIZE OF DATA RETURNED: $size');
        if (distances != null && distances.isNotEmpty){
          MobileDealer closestDealer = _dealers[0];
          print('#################### INITIAL CLOSEST DEALER NAME : '+closestDealer.name);
          int shortestDistance = distances[0];
          for (var i = 0;i < distances.length;i++){
            int distance = distances[i];
            print('@@@@@@@@@@@@@@@@@@@  DISTANCE VALUE : $distance');
            if (distance < shortestDistance){
              shortestDistance = distance;
              closestDealer = _dealers[i];
              print('#################### CLOSEST DEALER CHANGED TO: '+closestDealer.name);
            }
          }
          _dialog.update(message: 'Finding route ... ');
          LatLng currPos = LatLng(_currentPosition.latitude, _currentPosition.longitude);
          LatLng closestDealerPos = LatLng(closestDealer.latitude, closestDealer.longitude);
          _drawRouteBetween(currPos, closestDealerPos,false);
        }
      });
    } else {
      Fluttertoast.showToast(msg: 'Dealers not yet found.',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
  }

  _drawRouteBetween(LatLng origin,LatLng destination,prefix3.bool fromSearch){
    getRoutePointsBetween(origin, destination).then((pointLatLngs){
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
        if (_dialog != null && _dialog.isShowing()){
          _dialog.dismiss();
        }
        setState(() {
          _polyLines.add(Polyline(polylineId: PolylineId('Route to destination'),points: _polyLineCoordinates,width: 5));
        });
      });
      LatLng northEast = LatLng(maxLat, maxLon);
      LatLng southWest = LatLng(minLat, minLon);
      if (fromSearch){
        setState(() {
          _northEast = northEast;
          _southWest = southWest;
          _searchPressed = false;
        });
      } else {
        _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: southWest,northeast: northEast), 20));
      }
      double originLat = origin.latitude;
      double originLon = origin.longitude;
      double destinationLat = destination.latitude;
      double destinationLon = destination.longitude;
      String originValue = '$originLat,$originLon';
      String destinationValue = '$destinationLat,$destinationLon';
      String url = 'https://www.google.com/maps/dir/?api=1&origin=$originValue&destination=$destinationValue&travelmode=driving&dir_action=navigate';
//      if(_isAndroid){
        showModalBottomSheet(context: _context,builder: (BuildContext bc){
          return Container(
            padding: EdgeInsets.all(20.0),
            child: Wrap(
              children: <Widget>[
                Text('Would you like to switch to native maps inorder to navigate to your destination? (Device maps may suggest a better route to your destination and also other services)'),
                ListTile(title: Text('Navigate with google maps'),onTap: (){
                  if (_isAndroid){
                    Navigator.pop(bc);
                    AndroidIntent intent = new AndroidIntent(action: 'action_view',data: prefix3.Uri.encodeFull(url));
                    intent.launch();
                  } else {
                    _tryLaunchOnOtherVersions(url);
                  }
                },)
              ],
            ),
          );
        });
//      }
    });
  }

  _tryLaunchOnOtherVersions(prefix3.String url) async{
    prefix3.bool canLaunch = await prefix2.canLaunch(url);
    if (canLaunch){
      await launch(url);
    } else {
      Fluttertoast.showToast(msg: 'Sorry. Maps navigation not supported on your platform');
    }
  }

  Future<List<int>> _distancesToStations(Position currentPosition, String urlDestinations) async{
    double myLat = currentPosition.latitude;
    double myLon = currentPosition.longitude;
    print('@@@@@@@@@@@@@@@@@@ URL DESTINATIONS $urlDestinations , My current coordinates $myLat,$myLon');
    Response response;
    try{
      response = await get(prefix0.distanceMatrixApiURL+'?units=imperial&origins=$myLat,$myLon&destinations=$urlDestinations&key=$googleMapsApiKey');
    } on SocketException{
      Fluttertoast.showToast(msg: 'Service is unreachable. You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    if (response != null){
      print(response.body);
      int statusCode = response.statusCode;
      if (statusCode == 200){
        Map<String,dynamic> jsonResponse = jsonDecode(response.body);
        String status = jsonResponse['status'];
        if (status == 'OK'){
          List<dynamic> rows = jsonResponse['rows'];
          prefix3.print('_______________________  THE ROWS   ________________________');
          print(rows);
          List<int> result = [];
          int numRows = rows.length;
          print('Size of rows json array $numRows');
          if (numRows > 0){
            Map<String,dynamic> row = rows[0];
            List<dynamic> elements = row['elements'];
            if (elements.length > 0){
              for (var i = 0; i < elements.length; i++){
                Map<String,dynamic> element = elements[i];
                String elementStatus = element['status'];
                if(elementStatus == 'OK'){
                  Map<String,dynamic> distance = element['distance'];
                  int value = distance['value'];
                  print('XXXXXXXXXXXXXXXXXXX   ADDED $value');
                  result.add(value);
                }
              }
            }
          }
          return result;
        } else {
          Fluttertoast.showToast(msg: 'Google services responded with error status: $status');
        }
      } else {
        Fluttertoast.showToast(msg: 'Error $statusCode occured while contacting google services', toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      }
    } else {
      Fluttertoast.showToast(msg: 'No response from Google Services',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    return null;
  }

}