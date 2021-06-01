import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dropdownfield/dropdownfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix1;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:my_fuel_flutter_app/database/AppDB.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/models/VehicleModels.dart';
import 'package:my_fuel_flutter_app/screens/home.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix0;
import 'package:progress_dialog/progress_dialog.dart';

class MyCars extends StatefulWidget {

  @override
  _MyCarsState createState() => _MyCarsState();
}

class _MyCarsState extends State<MyCars> with RouteAware{

  List<Vehicle> _vehicles;
  bool _corporateUser = false;

  @override
  void initState() {
    SessionPrefs().getLoggedInUser().then((user){
      setState(() {
        _corporateUser = (user.role == corporateUserRole);
      });
    });
    AppDB.appDB.findAll(tbVehicle).then((onValue){
      List<Vehicle> vehicles = new List(onValue.length);
      int indx = 0;
      for (var i = 0; i < onValue.length; i++){
        Map<String,dynamic> obj = onValue[i];
        Vehicle vehicle = Vehicle(
          id: obj[id],
          make: obj[make],
          regno: obj[regNo],
          consumptionRate: obj[consumptionRate],
          active: obj[prefix0.active] == 1,
          makeid: obj[prefix0.makeId],
          modelid: obj[prefix0.modelId],
          CCs: obj[prefix0.ccs],
          mileage: obj[prefix0.mileage]
        );
        print('Vehicle consumption rate: '+vehicle.consumptionRate.toString());
        vehicles[indx] = vehicle;
        indx += 1;
      }
      setState((){
        _vehicles = vehicles;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('My Cars'),
        backgroundColor: Colors.amber,
      ),
      body: _body(),
      floatingActionButton: Visibility(
        visible: !_corporateUser,
        child: FloatingActionButton(
          backgroundColor: Colors.amber,
          child: Icon(
              Icons.add
          ),
          onPressed: () {
            print('Push context from mycars detected');
            Navigator.push(context, MaterialPageRoute(builder: (context) => CarDetails()));
          },
        ),
      ),
    );
  }

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Widget _body() {
    Widget response;
    if (_vehicles != null && _vehicles.isNotEmpty){
      response = ListView.builder(
        itemCount: _vehicles.length,
        itemBuilder: (context,i){
          Vehicle vehicle = _vehicles[i];
          String regNo = vehicle.regno;
          String make = vehicle.make;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: ListTile(
                title: Text(vehicle.active ? regNo : '$regNo (Car deactivated)'),
                subtitle: Text(make),
                onTap: (){
                  print('Context push from mycars');
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> CarDetails(vehicle: vehicle)));
                },
              ),
            ),
          );
        },
      );
    } else {
      response = Center(
        child: Text('There were no vehicles found'),
      );
    }
    return response;
  }

  @override
  void didPopNext(){
    print('Did pop next from manage vehicles');
    AppDB.appDB.findAll(tbVehicle).then((onValue){
      List<Vehicle> vehicles = new List();
      for (var i = 0; i < onValue.length; i++){
        Map<String,dynamic> obj = onValue[i];
        Vehicle vehicle = Vehicle(
          id: obj[id],
          make: obj[make],
          active: obj[prefix0.active] == 1,
          regno: obj[regNo],
          makeid: obj[prefix0.makeId],
          modelid: obj[prefix0.modelId],
          mileage: obj[prefix0.mileage],
          CCs: obj[prefix0.ccs],
          consumptionRate: obj[prefix0.consumptionRate]
        );
        vehicles.add(vehicle);
      }
      setState(() {
        _vehicles = vehicles;
      });
    });
  }
}

// ignore: must_be_immutable
class CarDetails extends StatefulWidget{

  Vehicle vehicle;
  CarDetails({this.vehicle});

  @override
  _CarDetailsState createState() => _CarDetailsState();
}

class _CarDetailsState extends State<CarDetails> with SingleTickerProviderStateMixin{

  ProgressDialog _dialog;
  BuildContext _context;
  final _formKey = GlobalKey<FormState>();
  var _regNumController = new TextEditingController();
  var _numCCsController = new TextEditingController();
  var _consumptionController = new TextEditingController();
  var _makeController = new TextEditingController();
  var _mileageController = new TextEditingController();
  TabController _tabController;
  List<VehicleMake> _makes;
  List<VehicleModel> _models;
  VehicleMake _make;
  MobileUser _loggedIn;
  String _selectedMake;
  VehicleModel _model;
  String _selectedModel;
  String _fuelType;
  ProgressDialog _progressDialog;
  List<String> fuelTypes;
  List<String> _makeNames;
  List<String> _modelNames;
  String _message = "Loading ... ";
  bool _loaded = false;
  bool _makeSelected = false,_disableModelsDropDown = false;
  bool _corporateUser = false;
  bool _active = true;

  @override
  void initState(){
    super.initState();
    if (widget.vehicle != null){
      setState((){
        _active = widget.vehicle.active;
      });
    }
    _tabController = TabController(length: 2, vsync: this);
    SessionPrefs().getLoggedInUser().then((loggedIn){
      setState(() {
        _loggedIn = loggedIn;
        _corporateUser = (loggedIn.role == corporateUserRole);
      });
    });
    prefix0.getTokenBasicAuth().then((token){
      allMakes(token).then((makes){
        if (makes != null){
          List<String> names = [];
          for (VehicleMake m in makes){
            names.add(m.toString());
          }
          setState(() {
            _loaded = true;
            _makeNames = names;
            _makes = makes;
          });
        }
        if (widget.vehicle != null){
          print(widget.vehicle.toString()+'makeId'+widget.vehicle.makeid.toString());
          String makeForThis;
          Vehicle _vehicle = widget.vehicle;
          VehicleMake _selectedVehicleMake;
          VehicleModel _selectedVehicleModel;
          _makes.forEach((make){
            if(make.id == _vehicle.makeid){
              makeForThis = make.vehiclemake;
              _selectedVehicleMake = make;
            }
          });
          setState(() {
            _make = _selectedVehicleMake;
          });
          List<VehicleModel> models = _selectedVehicleMake != null ? _selectedVehicleMake.models : [];
          if (models.isNotEmpty){
            print('models are not empty');
            List<String> modelNames = new List();
            setState((){
              _models = models;
              _modelNames = modelNames;
            });
            models.forEach((model){
              modelNames.add(model.model);
            });
            for (VehicleModel vmd in models){
              if (vmd.id == _vehicle.modelid){
                setState(() {
                  _selectedModel = vmd.model;
                  _model = vmd;
                });
              }
            }
          } else {
            setState((){
              _disableModelsDropDown = true;
            });
          }
          String reg = _vehicle.regno;
          print('Vehicle consumption: $reg');
          setState((){
            _make = _selectedVehicleMake;
            _makeSelected =true;
            _selectedMake = makeForThis;
            _regNumController.text = _vehicle.regno;
            _numCCsController.text = _vehicle.CCs;
            _mileageController.text = (_vehicle.mileage).toString();
            _consumptionController.text = _vehicle.consumptionRate.toString();
          });
        }
      });
    });
  }

  Future<List<VehicleMake>> allMakes(String token) async{
    Response response;
    try{
      response = await get(baseUrlLocal+'allmakes',headers: prefix0.getHeaders(token));
    } catch (e){
      if (e is SocketException){
        setState(() {
          _message = 'Service is currently unreachable. You may be offline';
        });
      }
    }
    List<VehicleMake> vms;
    var jsonResponse;
    if (response != null){
      int responseCode = response.statusCode;
      if (responseCode == 200){
        jsonResponse = json.decode(response.body);
        var list = jsonResponse as List;
        vms = list.map<VehicleMake>((json) => VehicleMake.fromJson(json)).toList();
      } else {
        Fluttertoast.showToast(msg: 'Error $responseCode Occured',gravity: ToastGravity.BOTTOM,toastLength: Toast.LENGTH_SHORT);
      }
    } else {
      Fluttertoast.showToast(msg: 'Server is unreachable',gravity: ToastGravity.BOTTOM,toastLength: Toast.LENGTH_SHORT);
    }
    return vms;
  }

  @override
  Widget build(BuildContext context){
    if (widget.vehicle != null){
      Vehicle v = widget.vehicle;
      if (_make == null){
        _makeController.text = v.make;
        _tabController.index = 1;
      } else {
        _tabController.index = 0;
      }
    }
    _context = context;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle != null ? 'Vehicle Details' : 'Create Vehicle'),
        backgroundColor: Colors.amber,
      ),
      body: _body(),
    );
  }

  Widget vehicleModel(){
    if (_makeSelected){
      return DropDownField(
        value: _selectedModel,
        strict: true,
        enabled: !_disableModelsDropDown,
        labelText: 'Vehicle model',
        items: _modelNames,
        onValueChanged: (val){
          VehicleModel selected;
          for (VehicleModel mdl in _models){
            if (mdl.toString() == val){
              selected = mdl;
            }
          }
          setState(() {
            _selectedMake = (val as String).trim();
            _model = selected;
          });
        },
        setter: (dynamic newValue){
          _selectedModel = newValue;
        },
      );
    }
    return Text('Select the make first');
  }

  Widget _body(){
    if (_loaded){
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            Card(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        textCapitalization: prefix1.TextCapitalization.characters,
                        enabled: !_corporateUser,
                        controller: _regNumController,
                        decoration: new InputDecoration(
                            border: new OutlineInputBorder(
                                borderSide: new BorderSide(color: Colors.pink)
                            ),
                            labelText: 'Vehicle Registration Number'
                        ),
                        validator: (value){
                          if (value.isEmpty){
                            return 'Enter the registration number';
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(padding: EdgeInsets.all(8.0),child: TabBar(
                      controller: _tabController,
                      tabs: <Widget>[
                        Tab(text: 'Availabe options'),
                        Tab(text: 'Enter mannually')
                      ],
                    )),
                    SizedBox(
                      height: 150.0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TabBarView(children: [
                          ListView(
                            children: <Widget>[
                              DropDownField(
                                enabled: !_corporateUser,
                                value: _selectedMake,
                                labelText: 'Vehicle Make * ',
                                items: _makeNames,
                                onValueChanged: (val){
                                  String sval = (val as String).trim();
                                  VehicleMake vm;
                                  for (VehicleMake m in _makes){
                                    if (sval == m.toString()){
                                      vm = m;
                                    }
                                  }
                                  List<String> models = [];
                                  List<VehicleModel> modelsformake = vm.models;
                                  for (VehicleModel m in modelsformake){
                                    models.add(m.toString());
                                  }
                                  setState((){
                                    _disableModelsDropDown = false;
                                    _makeSelected = true;
                                    _models = modelsformake;
                                    _selectedMake = (val as String).trim();
                                    _make = vm;
                                    _modelNames = models;
                                  });
                                },
                                setter: (dynamic newVal){
                                  _selectedMake = (newVal as String).trim();
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: vehicleModel(),
                              )
                            ],
                          ),
                          TextFormField(
                            controller: _makeController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide()
                              ),
                              labelText: 'make and model',
                              hintText: 'Enter make and model'
                            ),
                          )
                        ],controller: _tabController),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        enabled: !_corporateUser,
                        controller: _numCCsController,
                        validator: (value){
                          if (value.isEmpty){
                            return 'Enter the number of CCs';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                            border: new OutlineInputBorder(
                                borderSide: new BorderSide(color: Colors.pink)
                            ),
                            labelText: 'Number of CCs',
                            hintText: 'Enter the number of CCs'
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Padding(padding: prefix1.EdgeInsets.all(8.0),child: Row(
                      children: <Widget>[
                        prefix1.Expanded(child: TextFormField(
                          controller: _consumptionController,
                          validator: (value){
                            if (value.isEmpty){
                              return 'Please specify consumption rate';
                            }
                            else {
                              int consumption = int.parse(value);
                              if (consumption <= 0){
                                return 'Invalid value entered';
                              }
                            }
                            return null;
                          },
                          decoration: prefix1.InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: prefix1.BorderSide(
                                color: Colors.pink
                              )
                            ),
                            labelText: 'Consumption Rate'
                          ),
                          keyboardType: TextInputType.number,
                        )),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Kilometers per Litre'),
                        )
                      ],
                    )),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        enabled: widget.vehicle == null,
                        controller: _mileageController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide()
                          ),
                          labelText: 'Initial mileage reading',
                          hintText: '(Current odometer reading)'
                        ),
                        validator: (value){
                          if (value.isEmpty){
                            return 'Please specify mileage reading of the car';
                          } else {
                            int val = int.parse(value);
                            if (val < 0){
                              return 'Invalid value entered';
                            }
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: DropdownButton(
                          value: _fuelType,
                          items: <String>['Petrol','Diesel'].map<DropdownMenuItem<String>>((String val){
                            return DropdownMenuItem<String>(
                                value: val,
                                child: Text(val)
                            );
                          }).toList(),
                          onChanged: (String val){
                            setState(() {
                              _fuelType = val;
                            });
                          }
                      ),
                    ),
                    prefix1.Visibility(
                      visible: widget.vehicle != null,
                      child: Container(
                        color: prefix1.Colors.pinkAccent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            prefix1.Text(_active ? 'active (toggle switch to deactivate)' : 'inactive (toggle switch to activate)'),
                            prefix1.Switch(value: _active, onChanged: (value) {
                              prefix1.showDialog(context: _context, builder: (prefix1.BuildContext bc){
                                return prefix1.AlertDialog(
                                  title: prefix1.Text('Confirmation'),
                                  content: prefix1.Text(_active ? 'Are you sure you want to deactivate this car?' : 'Are you sure you want to activate this car'),
                                  actions: <Widget>[
                                    prefix1.FlatButton(onPressed: (){
                                      prefix1.Navigator.pop(bc);
                                    }, child: Text('No')),
                                    prefix1.FlatButton(onPressed: (){
                                      prefix1.Navigator.pop(bc);
                                      setState((){
                                        _active = value;
                                      });
                                      ProgressDialog dialog = new ProgressDialog(_context);
                                      dialog.style(message: 'Updating status ... ');
                                      dialog.show();
                                      Vehicle v = widget.vehicle;
                                      v.active = _active;
                                      String jsonData = json.encode(v);
                                      getTokenBasicAuth().then((token) async{
                                        Response response;
                                        try{
                                          response = await put(prefix0.baseUrlLocal+'updatevehicle',body: jsonData,headers: prefix0.postHeaders(token));
                                        } on SocketException{
                                          Fluttertoast.showToast(msg: 'You may be offline');
                                        }
                                        dialog.dismiss();
                                        if (response != null){
                                          int statusCode = response.statusCode;
                                          if (statusCode == 200){
                                            var jsonResponse = json.decode(response.body);
                                            Vehicle vehicle = Vehicle.fromJson(jsonResponse);
                                            Map<String,dynamic> row = {
                                              prefix0.id:vehicle.id,
                                              prefix0.active:vehicle.active
                                            };
                                            AppDB.appDB.update(prefix0.tbVehicle, row);
                                            Fluttertoast.showToast(msg: 'Vehicle updated successfully');
                                          } else {
                                            Fluttertoast.showToast(msg: 'Error $statusCode occured while updating data');
                                          }
                                        } else {
                                          Fluttertoast.showToast(msg: 'No response from the server');
                                        }
                                      });
                                    }, child: prefix1.Text('Yes'))
                                  ],
                                );
                              });
                            }),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Visibility(
              visible: !_corporateUser && _active,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                child: ButtonTheme(
                  height: 50.0,
                  child: RaisedButton(
                    color: Colors.amber,
                    onPressed: _doSave,
                    child: Text(widget.vehicle != null ? 'Update Vehicle' : 'Add Vehicle'),
                  ),
                ),
              ),
            )
          ],
        ),
      );
    }
    return Center(child: Text('$_message'));
  }

  _doSave(){
    if (_formKey.currentState.validate()){
      String makeAndModel = _makeController.text;
      String mileageInput = _mileageController.text;
      print('make: $_make');
      print('makeandmodel: $makeAndModel');
      if ((makeAndModel.isNotEmpty && _make == null) || (makeAndModel.isEmpty && _make != null)){
        print('############ Clicked ');
        Vehicle vehicle;
        SessionPrefs().getLoggedInUser().then((user){
          if (widget.vehicle != null){
            vehicle = widget.vehicle;
            vehicle.regno = _regNumController.text;
            vehicle.owner = user;
            vehicle.active = _active;
            vehicle.makeid = _make != null ? _make.id : 0;
            vehicle.modelid = _model != null ? _model.id : 0;
            vehicle.make = makeAndModel.isNotEmpty ? makeAndModel : _make.vehiclemake+' '+(_model != null ? _model.model : "" );
            vehicle.CCs = _numCCsController.text;
            vehicle.enginetype = _fuelType;
            vehicle.consumptionRate = int.parse(_consumptionController.text);
          } else {
            vehicle = Vehicle(
                regno: _regNumController.text,
                makeid: _make != null ? _make.id : 0,
                owner: user,
                active: _active,
                mileage: int.parse(mileageInput),
                modelid: _model != null ? _model.id : 0,
                make: makeAndModel.isNotEmpty ? makeAndModel : _model != null ? _make.vehiclemake+' '+_model.model : _make.vehiclemake,
                CCs: _numCCsController.text,
                enginetype: _fuelType,
                consumptionRate: int.parse(_consumptionController.text)
            );
          }
          String data = jsonEncode(vehicle);
          _dialog = new ProgressDialog(_context,isDismissible: false);
          _dialog.style(
              message: 'Saving vehicle ... ',
              progressWidget: CircularProgressIndicator(),
              insetAnimCurve: Curves.easeInOut
          );
          _dialog.show();
          getTokenBasicAuth().then((token){
            saveOrUpdateVehicle(data,token).then((onValue){
              _dialog.dismiss();
              if (onValue){
                Fluttertoast.showToast(
                    msg: widget.vehicle != null ? 'Vehicle updated successfully' : 'Vehicle added successfully',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM
                );
                Navigator.pop(_context);
              }
            });
          });
        });
      } else if (makeAndModel.isNotEmpty && _make != null){
        setState(() {
          _make = null;
        });
        Fluttertoast.showToast(msg: 'Specify make and model either from available options or by keying in mannually. Not both',toastLength: Toast.LENGTH_LONG);
      } else if (makeAndModel.isEmpty && _make == null){
        Fluttertoast.showToast(msg: 'You have not entered the vehicle make and model');
      }
    }
  }

  Future<bool> saveOrUpdateVehicle(String vehicle, String token) async{
    bool result;
    Response response;
    if (widget.vehicle != null){
      try {
        response = await put(baseUrlLocal+'updatevehicle',headers: postHeaders(token),body: vehicle);
      } catch (e){
        if (e is SocketException){
          _dialog.dismiss();
          Fluttertoast.showToast(msg: 'Service is currently unreachable. You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
        } else {
          print(e);
        }
      }
      if (response != null){
        int statusCode = response.statusCode;
        var jsonResponse;
        if (statusCode == 200){
          jsonResponse = jsonDecode(response.body);
          Vehicle v = Vehicle.fromJson(jsonResponse);
          print('Consumption rate : '+v.consumptionRate.toString());
          Map row = new HashMap<String,dynamic>();
          row[id] = v.id;
          row[regNo] = v.regno;
          row[make] = v.make;
          row[makeId] = v.makeid;
          row[active] = v.active ? 1 : 0;
          row[modelId] = v.modelid;
          row[ccs] = v.CCs;
          row[keyUser] = _loggedIn.id;
          row[engineType] = v.enginetype;
          row[prefix0.consumptionRate] = v.consumptionRate;
          AppDB.appDB.update(tbVehicle, row);
          result = true;
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
    } else {
      try{
        response = await post(baseUrlLocal+'addvehicle',headers: prefix0.postHeaders(token), body: vehicle);
      } catch (e){
        _dialog.dismiss();
        if (e is SocketException){
          Fluttertoast.showToast(msg: 'Service is currently unreachable. You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
        }
      }
      if (response != null){
        int statusCode = response.statusCode;
        var jsonResponse;
        if (statusCode == 200){
          jsonResponse = jsonDecode(response.body);
          Vehicle v = Vehicle.fromJson(jsonResponse);
          Map row = new HashMap<String,dynamic>();
          row[id] = v.id;
          row[regNo] = v.regno;
          row[make] = v.make;
          row[makeId] = v.makeid;
          row[mileage] = v.mileage;
          row[active] = v.active ? 1 : 0;
          row[modelId] = v.modelid;
          row[ccs] = v.CCs;
          row[keyUser] = _loggedIn.id;
          row[engineType] = v.enginetype;
          row[consumptionRate] = v.consumptionRate;
          AppDB.appDB.save(tbVehicle, row);
          result = true;
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
        setState(() {
          _message = 'Service is currently unreachable';
        });
        result = false;
        Fluttertoast.showToast(
          msg: 'Server is unreachable',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM
        );
      }
    }
    return result;
  }

}