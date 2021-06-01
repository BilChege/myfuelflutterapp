import 'dart:collection';
import 'dart:convert';
import 'dart:core' as prefix2;
import 'dart:core';
import 'dart:io';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:dropdownfield/dropdownfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix1;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:my_fuel_flutter_app/database/AppDB.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/PackageModels.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/models/VehicleModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix0;

class Reports extends StatefulWidget {
  @override
  _ReportsState createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {

  MobileUser _loggedInUser;
  BuildContext _context;
  int _pageIndex;
  List<MobileRedemption> _itemsRedeemed;
  List<FuelCar> _usageList;
  DateFormat _dateFormat = new DateFormat('yyyy-MM-dd');
  var _totalSpentFromDateController = new TextEditingController();
  var _totalSpentToDateController = new TextEditingController();
  var _itemsRedeemedFromDateController = new TextEditingController();
  var _totalSpentValueController = new TextEditingController();
  var _mileageReportFromDateController = new TextEditingController();
  var _mileageReportToDateController = new TextEditingController();
  var _totalMileage = new TextEditingController();
  String _itemsRedeemedFromDate,_itemsRedeemedToDate,_totalSpentFromDate,_totalSpentToDate,_mileageReportFromDate,_mileageReportToDate;
  String _selectedVehicle;
  String _itemsRedeemedMessage = "Loading ... ",_totalSpentReportMessage = "Loading ... ",_mileageReportMessage = "Loading ... ";
  prefix2.List<int> _selectedVehicles = new prefix2.List();
  Vehicle _vehicle;
  prefix2.bool _updatedTtSpent = false;
  List<Vehicle> _vehicles = new List();
  double _totalSpent, _mileagediff;
  List<String> _vehicleStrings = new List();
  var _formKey = GlobalKey<FormState>();

  @override
  void initState(){
    AppDB.appDB.findAll(tbVehicle).then((rows){
      if (rows.isNotEmpty){
        rows.forEach((row){
          Vehicle vehicle = Vehicle(
            id: row[prefix0.id],
            regno: row[prefix0.regNo],
            make: row[prefix0.make],
            consumptionRate: row[prefix0.consumptionRate]
          );
          setState(() {
            _vehicles.add(vehicle);
            _vehicleStrings.add(vehicle.toString());
          });
        });
      }
    });
    setState(() {
      _pageIndex = 0;
    });
    SessionPrefs().getLoggedInUser().then((user){
      prefix0.getTokenBasicAuth().then((token){
        allUsagesByUser(user.id,token).then((usages){
          if (usages != null){
            if (usages.isNotEmpty){
              double ttSpent = 0;
              usages.forEach((usage){
                ttSpent += usage.amount;
              });
              setState(() {
                _totalSpent = ttSpent;
                _usageList = usages;
              });
            } else {
              setState(() {
                _totalSpentReportMessage = "You have not spent anything yet. Start by fueling a car at the station";
                _mileageReportMessage = "You have not spent anything yet.";
              });
            }
          }
        });
        getItemsRedeemedForUser(user.id,token).then((itemsRedeemed){
          if (itemsRedeemed != null){
            if (itemsRedeemed.isNotEmpty){
              setState((){
                _itemsRedeemed = itemsRedeemed;
              });
            } else {
              setState(() {
                _itemsRedeemedMessage = "You have not redeemed any items yet";
              });
            }
          }
        });
      });
      setState(() {
        _loggedInUser = user;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context){
    prefix2.print('Vehicle: $_vehicle');
    _context = context;
    return Scaffold(
      appBar: AppBar(title: Text('Reports')),
      body: _body(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index){
          setState((){
            _pageIndex = index;
          });
        },
          currentIndex: _pageIndex
          ,items: [
        BottomNavigationBarItem(icon: Icon(Icons.score),title: Text('Total Spent')),
        BottomNavigationBarItem(icon: Icon(Icons.forward),title: Text('Millage Covered'))
      ]),
    );
  }

  Future<List<MobileRedemption>> getItemsRedeemedForUser(int id,prefix2.String token) async{
    Response response;
    try{
      response = await get(baseUrlLocal+'itemsRedeemed/$id',headers: prefix0.getHeaders(token));
    } on SocketException{
      Fluttertoast.showToast(msg: 'You may be offline');
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        var jsonResponse = json.decode(response.body);
        var list = jsonResponse as List;
        return list.map<MobileRedemption>((json) => MobileRedemption.fromJson(json)).toList();
      } else {
        setState(() {
          _itemsRedeemedMessage = "An Error occurred while fetching data";
        });
        Fluttertoast.showToast(msg: 'Error $statusCode occurred');
      }
    } else {
      setState(() {
        _itemsRedeemedMessage = "No Response from Server";
      });
    }
    return null;
  }

  Future<prefix2.List<FuelCar>> allUsagesByUser(prefix2.int userId,prefix2.String token) async{
    Response response;
    try{
      response = await get(prefix0.baseUrlLocal+'usages/$userId',headers: prefix0.getHeaders(token));
    } on SocketException{
      setState(() {
        _totalSpentReportMessage = "You may be offline";
      });
    }
    if (response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        var jsonResponse = json.decode(response.body);
        var list = jsonResponse as prefix2.List;
        return list.map<FuelCar>((json) => FuelCar.fromJson(json)).toList();
      } else {
        _totalSpentReportMessage = "An error occurred while loading data from server";
      }
    } else {
      setState(() {
        _totalSpentReportMessage = "No response from the server";
      });
    }
    return null;
  }

  _body() {
    switch (_pageIndex){
      case 0 : {
        if (_usageList != null && _usageList.isNotEmpty){
          _totalSpentValueController.text = _totalSpent != null ? _totalSpent.toString() : "";
          return ListView(children: <Widget>[
            Padding(padding: EdgeInsets.all(10.0),child: Card(
              elevation: 5.0,
              child: Column(
                children: <Widget>[
                  Padding(padding: EdgeInsets.all(10.0),child: Text('Total Spent Summary',style: TextStyle(fontStyle: FontStyle.italic),)),
                  Padding(padding: EdgeInsets.all(10.0),child: Row(
                    children: <Widget>[
                      Expanded(child: DateTimeField(format: _dateFormat ,decoration: InputDecoration(
                          labelText: 'From Date',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.pink
                              )
                          )
                      ), onShowPicker: (context,currentValue){
                        return showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
                      },
                        controller: _totalSpentFromDateController,
                        onChanged: (value){
                        if (value != null){
                          String toDate = _totalSpentToDateController.text;
                          if (toDate != null && toDate.isNotEmpty){
                            prefix2.DateTime toDateVal = _dateFormat.parse(toDate);
                            if (value.isAfter(toDateVal)){
                              prefix1.showDialog(context: _context,builder: (prefix1.BuildContext bc){
                                return prefix1.AlertDialog(
                                  title: prefix1.Text('Error'),
                                  content: prefix1.Text('From Date cannot be after to Date'),
                                  actions: <Widget>[
                                    prefix1.FlatButton(onPressed: (){
                                      prefix1.Navigator.pop(bc);
                                    }, child: prefix1.Text('Ok'))
                                  ],
                                );
                              });
                              _totalSpentFromDateController.clear();
                            } else {
                              setState(() {
                                _updatedTtSpent = false;
                                _totalSpentFromDate = _dateFormat.format(value);
                              });
                            }
                          } else {
                            setState(() {
                              _updatedTtSpent = false;
                              _totalSpentFromDate = _dateFormat.format(value);
                            });
                          }
                        } else {
                          setState(() {
                            _updatedTtSpent = false;
                            _totalSpentFromDate = null;
                          });
                        }
                      }
                      )),
                      Expanded(
                        child: DateTimeField(
//                          controller: _totalSpentToDateController,
                          onChanged: (value){
                            if (value != null){
                              prefix2.String fromDate = _totalSpentFromDateController.text;
                              DateTime fromDateValue;
                              if (fromDate != null && fromDate.isNotEmpty){
                                fromDateValue = _dateFormat.parse(fromDate);
                              }
                              if (fromDateValue != null){
                                if (value.isBefore(fromDateValue)){
                                  showDialog(context: _context,builder:(prefix1.BuildContext bc){
                                    return prefix1.AlertDialog(
                                      title: prefix1.Text('Error'),
                                      content: prefix1.Text('To Date cannot be before From date'),
                                      actions: <Widget>[
                                        prefix1.FlatButton(onPressed: (){
                                          prefix1.Navigator.pop(bc);
                                        }, child: prefix1.Text('Ok'))
                                      ],
                                    );
                                  });
                                  _totalSpentToDateController.clear();
                                } else {
                                  setState(() {
                                    _updatedTtSpent = false;
                                    _totalSpentToDate = _dateFormat.format(value);
                                  });
                                }
                              } else {
                                setState(() {
                                  _updatedTtSpent = false;
                                  _totalSpentToDate = _dateFormat.format(value);
                                });
                              }
                            } else {
                              setState(() {
                                _updatedTtSpent = false;
                                _totalSpentToDate = null;
                              });
                            }
                          },
                          decoration: InputDecoration(
                              labelText: 'To Date',
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.pink
                                  )
                              )
                          ),
                          format: _dateFormat,
                          onShowPicker: (context,currentValue){
                            return showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
                          },
                        ),
                      )
                    ],
                  )),
                  Padding(padding: EdgeInsets.all(10.0),child: ExpansionTile(title: Text('Filter Result By Selecting Vehicles'),children: _carCheckBoxes(),)),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      controller: _totalSpentValueController,
                      enabled: false,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(borderSide: prefix1.BorderSide()),
                          labelText: 'Total Spent on fuel'
                      ),
                    ),
                  )
                ],
              ),
            )),
            _expenditureBody()
          ]);
        }
        return prefix1.Center(child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: prefix1.Text(_totalSpentReportMessage),
        ));
      }
      case 1 : {
        if (_usageList != null && _usageList.isNotEmpty){
          Set<String> regs = new Set();
          for (FuelCar fc in _usageList){
            regs.add(fc.vehicle.regno);
          }
          Map data = new HashMap<String,double>();
          for(String s in regs){
            double amt = 0;
            for(FuelCar fc in _usageList){
              if (fc.vehicle.regno == s){
                amt += fc.amount;
              }
            }
            data[s] = amt;
          }
          return ListView(
            children: <Widget>[
              Padding(padding: EdgeInsets.all(10.0),child: Text('Mileage Summary Report, per vehicle. Use date filters to see total distance covered between time periods.',style: TextStyle(fontStyle: FontStyle.italic))),
              Padding(padding: EdgeInsets.all(10.0),child: DropDownField(
                value: _selectedVehicle,
                labelText: 'Select vehicle to filter result',
                items: _vehicleStrings,
                onValueChanged: (vehicle){
                  String regVal = vehicle;
                  String reg = regVal.split('(').elementAt(0).trim();
                  if (vehicle != null){
                    Vehicle selected;
                    for (Vehicle v in _vehicles){
                      if (v.regno == reg){
                        selected = v;
                      }
                    }
                    setState(() {
                      _selectedVehicle = vehicle;
                      _vehicle = selected;
                    });
                  } else {
                    setState((){
                      _vehicle = null;
                    });
                  }
                },
                setter: (vehicle){
                  _selectedVehicle = vehicle;
                },
              )),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10.0),child: Row(
                children: <Widget>[
                  Expanded(child: DateTimeField(
                      format: _dateFormat,
                      controller: _mileageReportFromDateController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide()
                        ),
                        labelText: 'From Date'
                      ),
                      onChanged: (date){
                        if (date != null){
                          String mileageReportToDate = _mileageReportToDateController.text;
                          prefix2.DateTime todate;
                          if (mileageReportToDate.isNotEmpty){
                            todate = _dateFormat.parse(mileageReportToDate);
                          }
                          if (todate != null){
                            if (date.isAfter(todate)){
                              showDialog(context: _context,builder: (context){
                                return AlertDialog(
                                  title: Text('Error'),
                                  content: Text('From date cannot be after to date'),
                                  actions: <Widget>[
                                    FlatButton(onPressed: (){
                                      Navigator.pop(context);
                                    }, child: Text('Ok'))
                                  ],
                                );
                              });
                              setState(() {
                                _mileageReportFromDateController.clear();
                              });
                            } else {
                              setState((){
                                _mileageReportFromDate = _dateFormat.format(date);
                              });
                            }
                          } else {
                            setState((){
                              _mileageReportFromDate = _dateFormat.format(date);
                            });
                          }
                        } else {
                          setState(() {
                            _mileageReportFromDate = null;
                          });
                        }
                      },
                      onShowPicker: (bc,currentValue){
                        return showDatePicker(context: bc, initialDate: prefix2.DateTime.now(), firstDate: prefix2.DateTime(1900), lastDate: prefix2.DateTime.now());
                      }
                      )),
                  Expanded(child: DateTimeField(format: _dateFormat, onShowPicker: (bc,currentValue){
                    return showDatePicker(context: bc, initialDate: prefix2.DateTime.now(), firstDate: prefix2.DateTime(1900), lastDate: prefix2.DateTime.now());
                  },decoration: InputDecoration(border: OutlineInputBorder(
                    borderSide: BorderSide()
                  ), labelText: 'To Date'),controller: _mileageReportToDateController,onChanged: (date){
                    if (date != null){
                      prefix2.String mrFromDate = _mileageReportFromDateController.text;
                      prefix2.DateTime fromDate;
                      if (mrFromDate.isNotEmpty){
                        fromDate = _dateFormat.parse(mrFromDate);
                      }
                      if (fromDate != null){
                        if (date.isBefore(fromDate)){
                          showDialog(context: _context, builder: (bc){
                            return AlertDialog(
                              title: Text('Error'),
                              content: Text('To date cannot be before from date'),
                              actions: <Widget>[
                                FlatButton(onPressed: (){
                                  Navigator.pop(bc);
                                }, child: Text('Ok'))
                              ],
                            );
                          });
                          setState(() {
                            _mileageReportToDateController.clear();
                          });
                        } else {
                          setState((){
                            _mileageReportToDate = _dateFormat.format(date);
                          });
                        }
                      } else {
                        setState((){
                          _mileageReportToDate = _dateFormat.format(date);
                        });
                      }
                    } else {
                      setState(() {
                        _mileageReportToDate = null;
                      });
                    }
                  },))
                ],
              )),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextFormField(
                  enabled: false,
                  controller: _totalMileage,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide()
                    ),
                    labelText: 'Total Estimated Mileage covered'
                  ),
                ),
              ),
              Padding(padding: EdgeInsets.all(10.0),child: _mileages(),)
            ],
          );
        }
        return Center(child: Text('$_mileageReportMessage'));
      }
      case 2 : {
        return _itemsRedeemedReportPage();
      }
    }
  }

  _itemsRedeemedReportPage() {
    if (_itemsRedeemed != null && _itemsRedeemed.isNotEmpty){
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Card(
              elevation: 5.0,
              child: Column(
                children: <Widget>[
                  Padding(padding: EdgeInsets.all(10.0),child: Text('List of items Redeemed.\n Select date range to filter results below',style: TextStyle(fontStyle: FontStyle.italic))),
                  Padding(padding: EdgeInsets.all(10.0), child: Row(
                    children: <Widget>[
                      Expanded(child: DateTimeField(format: _dateFormat, onShowPicker: (context,currentValue){
                        return prefix1.showDatePicker(context: _context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
                      },
                        controller: _itemsRedeemedFromDateController,
                        onChanged: (value){
                        if (value != null){
                          setState(() {
                            _itemsRedeemedFromDate = _dateFormat.format(value);
                          });
                        } else {
                          setState(() {
                            _itemsRedeemedFromDate = null;
                          });
                        }
                      },decoration: prefix1.InputDecoration(labelText: 'From Date' ,border: prefix1.OutlineInputBorder(borderSide: prefix1.BorderSide(color: prefix1.Colors.pinkAccent))),)),
                      Expanded(child: DateTimeField(format: _dateFormat, onShowPicker: (context,currentValue){
                        return prefix1.showDatePicker(context: _context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
                      },decoration: prefix1.InputDecoration(labelText: 'To Date' ,border: prefix1.OutlineInputBorder(borderSide: prefix1.BorderSide())),onChanged: (value){
                        if (value != null){
                          DateTime fromDate;
                          String fromDateInput = _itemsRedeemedFromDateController.text;
                          if (fromDateInput != null && fromDateInput.isNotEmpty){
                            fromDate = _dateFormat.parse(fromDateInput);
                          }
                          if (fromDate != null){
                            if (fromDate.isAfter(value)){
                              prefix1.showDialog(context: _context,builder: (BuildContext bc){
                                return prefix1.AlertDialog(
                                  title: prefix1.Text('Error'),
                                  content: prefix1.Text('Date selected is after from Date'),
                                  actions: <Widget>[
                                    prefix1.FlatButton(onPressed: (){
                                      prefix1.Navigator.pop(bc);
                                    }, child: prefix1.Text('Ok'))
                                  ],
                                );
                              });
                            }
                          }
                          setState(() {
                            _itemsRedeemedToDate = _dateFormat.format(value);
                          });
                        } else {
                          setState(() {
                            _itemsRedeemedToDate = null;
                          });
                        }
                      },))
                    ],
                  ))
                ],
              ),
            ),
          ),
          Expanded(child: _itemsList())
        ],
      );
    }
    return prefix1.Center(child: prefix1.Text('$_itemsRedeemedMessage'));
  }

  _itemsList() {
    if (_itemsRedeemedFromDate != null){
      List<MobileRedemption> filteredItems = new List();
      DateTime fromdate = _dateFormat.parse(_itemsRedeemedFromDate);
      if (_itemsRedeemedToDate != null){
        DateTime todate = _dateFormat.parse(_itemsRedeemedToDate);
        _itemsRedeemed.forEach((item){
          DateTime dateRedeemed = _dateFormat.parse(item.datepurchased);
          if (dateRedeemed.isAfter(fromdate) && dateRedeemed.isBefore(todate)){
            filteredItems.add(item);
          }
        });
        return _itemsRedeemedList(filteredItems);
      }
      _itemsRedeemed.forEach((item){
        DateTime dateRedeemed = _dateFormat.parse(item.datepurchased);
        if (dateRedeemed.isAtSameMomentAs(fromdate) || dateRedeemed.isAfter(fromdate)){
          filteredItems.add(item);
        }
      });
      return _itemsRedeemedList(filteredItems);
    }
    if (_itemsRedeemedToDate != null){
      prefix2.List<MobileRedemption> filteredItems = new prefix2.List();
      prefix2.DateTime toDate = _dateFormat.parse(_itemsRedeemedToDate);
      _itemsRedeemed.forEach((item){
        prefix2.DateTime dateRedeemed = _dateFormat.parse(item.datepurchased);
        if (dateRedeemed.isAtSameMomentAs(toDate) || dateRedeemed.isBefore(toDate)){
          filteredItems.add(item);
        }
      });
      return _itemsRedeemedList(filteredItems);
    }
    return _itemsRedeemedList(_itemsRedeemed);
  }

  _expenditureBody(){
    prefix2.List<FuelCar> filteredUsages = new prefix2.List();
    double ttSpent = 0;
    if (_totalSpentFromDate != null){
      prefix2.DateTime fromDate  = _dateFormat.parse(_totalSpentFromDate);
      if (_totalSpentToDate != null){
        DateTime toDate = _dateFormat.parse(_totalSpentToDate);
        if (_selectedVehicles.isNotEmpty){
          _usageList.forEach((usage){
            Vehicle v = usage.vehicle;
            prefix2.DateTime dateFueled = _dateFormat.parse(usage.dateFueled);
            if ((dateFueled.isAtSameMomentAs(fromDate) || dateFueled.isAfter(fromDate)) && (dateFueled.isAtSameMomentAs(toDate) || dateFueled.isBefore(toDate)) && _selectedVehicles.contains(v.id)){
              filteredUsages.add(usage);
              ttSpent += usage.amount;
            }
          });
          if (!_updatedTtSpent){
            prefix1.WidgetsBinding.instance.addPostFrameCallback((_){
              setState(() {
                _totalSpent = ttSpent;
              });
            });
            _updatedTtSpent = true;
          }
          return _listViewBuilder(filteredUsages);
        }
        _usageList.forEach((_usage){
          prefix2.DateTime dateFueled = _dateFormat.parse(_usage.dateFueled);
          if ((dateFueled.isAtSameMomentAs(fromDate) || dateFueled.isAfter(fromDate)) && (dateFueled.isAtSameMomentAs(toDate) || dateFueled.isBefore(toDate))){
            ttSpent += _usage.amount;
            filteredUsages.add(_usage);
          }
        });
        if (!_updatedTtSpent){
          prefix1.WidgetsBinding.instance.addPostFrameCallback((_){
            setState(() {
              _totalSpent = ttSpent;
            });
          });
          _updatedTtSpent = true;
        }
        return _listViewBuilder(filteredUsages);
      }
      if (_selectedVehicles.isNotEmpty){
        _usageList.forEach((usage){
          Vehicle v = usage.vehicle;
          prefix2.DateTime dateFueled = _dateFormat.parse(usage.dateFueled);
          if ((dateFueled.isAtSameMomentAs(fromDate) || dateFueled.isAfter(fromDate)) && _selectedVehicles.contains(v.id)){
            filteredUsages.add(usage);
            ttSpent += usage.amount;
          }
        });
        if (!_updatedTtSpent){
          prefix1.WidgetsBinding.instance.addPostFrameCallback((_){
            setState(() {
              _totalSpent = ttSpent;
            });
          });
          _updatedTtSpent = true;
        }
        return _listViewBuilder(filteredUsages);
      }
      _usageList.forEach((usage){
        prefix2.DateTime dateSpent = _dateFormat.parse(usage.dateFueled);
        if (dateSpent.isAtSameMomentAs(fromDate) || dateSpent.isAfter(fromDate)){
          ttSpent += usage.amount;
          filteredUsages.add(usage);
        }
      });
      if (!_updatedTtSpent){
        prefix1.WidgetsBinding.instance.addPostFrameCallback((_){
          setState(() {
            _totalSpent = ttSpent;
          });
        });
        _updatedTtSpent = true;
      }
      return _listViewBuilder(filteredUsages);
    }
    if (_totalSpentToDate != null){
      prefix2.DateTime toDate = _dateFormat.parse(_totalSpentToDate);
      if (_selectedVehicles.isNotEmpty){
        double ttSpent = 0;
        _usageList.forEach((usage){
          DateTime dateSpent = _dateFormat.parse(usage.dateFueled);
          double amt = usage.amount;
          Vehicle v = usage.vehicle;
          if ((dateSpent.isAtSameMomentAs(toDate) || dateSpent.isBefore(toDate)) && _selectedVehicles.contains(v.id)){
            filteredUsages.add(usage);
            ttSpent += amt;
          }
        });
        if (!_updatedTtSpent){
          prefix1.WidgetsBinding.instance.addPostFrameCallback((_){
            setState(() {
              _totalSpent = ttSpent;
            });
          });
          _updatedTtSpent = true;
        }
        return _listViewBuilder(filteredUsages);
      }
      prefix2.double ttSpent = 0;
      _usageList.forEach((usage){
        prefix2.DateTime dateSpent = _dateFormat.parse(usage.dateFueled);
        prefix2.double amtSpent = usage.amount;
        if (dateSpent.isAtSameMomentAs(toDate) || dateSpent.isBefore(toDate)){
          ttSpent += amtSpent;
          filteredUsages.add(usage);
        }
      });
      if (!_updatedTtSpent){
        prefix1.WidgetsBinding.instance.addPostFrameCallback((_){
          setState(() {
            _totalSpent = ttSpent;
          });
        });
        _updatedTtSpent = true;
      }
      return _listViewBuilder(filteredUsages);
    }
    if (_selectedVehicles.isNotEmpty){
      prefix2.double ttSpent = 0;
      _usageList.forEach((usage){
        Vehicle v = usage.vehicle;
        prefix2.double amt = usage.amount;
        if (_selectedVehicles.contains(v.id)){
          ttSpent += amt;
          filteredUsages.add(usage);
        }
      });
      if (!_updatedTtSpent){
        prefix1.WidgetsBinding.instance.addPostFrameCallback((_){
          setState(() {
            _totalSpent = ttSpent;
          });
        });
        _updatedTtSpent = true;
      }
      return _listViewBuilder(filteredUsages);
    }
    _usageList.forEach((usage){
      ttSpent += usage.amount;
    });
    if (!_updatedTtSpent){
      prefix1.WidgetsBinding.instance.addPostFrameCallback((_){
        setState(() {
          _totalSpent = ttSpent;
        });
      });
      _updatedTtSpent = true;
    }
    return _listViewBuilder(_usageList);
  }

  _listViewBuilder(List<FuelCar> filteredUsages){
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ListView.builder(
        shrinkWrap: true,
        itemBuilder: (context,i){
        FuelCar usage = filteredUsages.elementAt(i);
        Vehicle vehicle = usage.vehicle;
        prefix2.String regNo = vehicle.regno;
        prefix2.String make = vehicle.make;
        prefix2.double amt = usage.amount;
        prefix2.String dateSpent = usage.dateFueled;
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: prefix1.Column(
            children: <Widget>[
              prefix1.Text('Amount Spent: $amt'),
              prefix1.Text('Date spent: $dateSpent'),
              prefix1.Text('Spent on vehicle: $regNo ($make)'),
              prefix1.Divider(thickness: 1.0)
            ],
          ),
        );
      },itemCount: filteredUsages.length,),
    );
  }

  _mrFilteredList(List<FuelCar> list){
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ListView.builder(
        shrinkWrap: true,
        itemBuilder: (context,i){
          FuelCar usage = list.elementAt(i);
          prefix2.int mileage = usage.mileage;
          Vehicle v = usage.vehicle;
          prefix2.String reg = v.regno;
          prefix2.String dateSpent = usage.dateFueled;
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: prefix1.Column(
              children: <Widget>[
                ListTile(title: Text('Vehicle: $reg'),subtitle: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Date of Transaction: $dateSpent'),
                    Text('Mileage by then: $mileage'),
                  ],
                )),
                prefix1.Divider(thickness: 1.0)
              ],
            ),
          );
        },itemCount: list.length,),
    );
  }

  _itemsRedeemedList(List<MobileRedemption> filteredItems) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ListView.builder(itemBuilder: (context,i){
        MobileRedemption redemption = filteredItems.elementAt(i);
        OffersForMobile offerRedeemed = redemption.offer;
        String promoName = offerRedeemed.promoname;
        String promoDesc = offerRedeemed.promodesc;
        int points = offerRedeemed.points;
        String dateRedeemed = redemption.datepurchased;
        String stationId = redemption.stationId;
        return prefix1.Column(
          children: <Widget>[
            prefix1.Text('Offer Name: $promoName'),
            prefix1.Text('Offer Description: $promoDesc'),
            prefix1.Text('Number of points redeemed: $points'),
            prefix1.Text('Date Redeemed: $dateRedeemed'),
            prefix1.Text('Redeemed at Station: $stationId'),
            prefix1.Divider(thickness: 1.0)
          ],
        );
      },itemCount: filteredItems.length,),
    );
  }

  _carCheckBoxes(){
    List<Widget> results = new prefix2.List();
    for (Vehicle v in _vehicles){
      prefix2.String reg = v.regno;
      prefix2.String make = v.make;
      results.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            Text('$reg ($make)'),
            Checkbox(value: _selectedVehicles.contains(v.id), onChanged: (checked){
              if (checked){
                setState(() {
                  _updatedTtSpent = false;
                  _selectedVehicles.add(v.id);
                });
              } else {
                setState(() {
                  _updatedTtSpent = false;
                  _selectedVehicles.remove(v.id);
                });
              }
            })
          ],
        ),
      ));
    }
    return results;
  }

  _mileages(){
    prefix2.List<FuelCar> filtered = new prefix2.List();
    if (_usageList != null){
      if (_usageList.isNotEmpty){
        if (_mileageReportFromDate != null){
          if (_mileageReportToDate != null){
            if (_vehicle != null){
              _usageList.forEach((usage){
                DateTime date = _dateFormat.parse(usage.dateFueled);
                DateTime inputFrm = _dateFormat.parse(_mileageReportFromDate);
                prefix2.DateTime inputTo = _dateFormat.parse(_mileageReportToDate);
                Vehicle v = usage.vehicle;
                if ((date.isAtSameMomentAs(inputFrm) || date.isAfter(inputFrm)) && (date.isAtSameMomentAs(inputTo) || date.isBefore(inputTo)) && _vehicle.id == v.id){
                  filtered.add(usage);
                }
              });
              FuelCar initialUsage = filtered.elementAt(0);
              int biggest = initialUsage.mileage;
              int smallest = initialUsage.mileage;
              prefix2.int mileagediff = 0;
              if (filtered.isNotEmpty){
                for (FuelCar fc in filtered){
                  if (fc.mileage > biggest){
                    biggest = fc.mileage;
                  }
                  if (fc.mileage < smallest){
                    smallest = fc.mileage;
                  }
                }
                mileagediff = biggest - smallest;
              }
              _totalMileage.text = mileagediff.toString();
              return _mrFilteredList(filtered);
            }
            _usageList.forEach((usage){
              DateTime date = _dateFormat.parse(usage.dateFueled);
              DateTime inputFrm = _dateFormat.parse(_mileageReportFromDate);
              prefix2.DateTime inputTo = _dateFormat.parse(_mileageReportToDate);
              if ((date.isAtSameMomentAs(inputFrm) || date.isAfter(inputFrm)) && (date.isAtSameMomentAs(inputTo) || date.isBefore(inputTo))){
                filtered.add(usage);
              }
            });
            FuelCar initialUsage = filtered.elementAt(0);
            int biggest = initialUsage.mileage;
            int smallest = initialUsage.mileage;
            prefix2.int mileagediff = 0;
            if (filtered.isNotEmpty){
              for (FuelCar fc in filtered){
                if (fc.mileage > biggest){
                  biggest = fc.mileage;
                }
                if (fc.mileage < smallest){
                  smallest = fc.mileage;
                }
              }
              mileagediff = biggest - smallest;
            }
            _totalMileage.text = mileagediff.toString();
            return _mrFilteredList(filtered);
          }
          _usageList.forEach((usage){
            DateTime date = _dateFormat.parse(usage.dateFueled);
            DateTime inputFrm = _dateFormat.parse(_mileageReportFromDate);
            if (date.isAtSameMomentAs(inputFrm) || date.isAfter(inputFrm)){
              filtered.add(usage);
            }
          });
          FuelCar initialUsage = filtered.elementAt(0);
          int biggest = initialUsage.mileage;
          int smallest = initialUsage.mileage;
          prefix2.int mileagediff = 0;
          if (filtered.isNotEmpty){
            for (FuelCar fc in filtered){
              if (fc.mileage > biggest){
                biggest = fc.mileage;
              }
              if (fc.mileage < smallest){
                smallest = fc.mileage;
              }
            }
            mileagediff = biggest - smallest;
          }
          _totalMileage.text = mileagediff.toString();
          return _mrFilteredList(filtered);
        }
        if (_mileageReportToDate != null){
          if (_vehicle != null){
            _usageList.forEach((usage){
              prefix2.DateTime date = _dateFormat.parse(usage.dateFueled);
              prefix2.DateTime inputTo = _dateFormat.parse(_mileageReportToDate);
              Vehicle v = usage.vehicle;
              if ((date.isAtSameMomentAs(inputTo) || date.isBefore(inputTo)) && _vehicle.id == v.id){
                filtered.add(usage);
              }
            });
            FuelCar initialUsage = filtered.elementAt(0);
            int biggest = initialUsage.mileage;
            int smallest = initialUsage.mileage;
            prefix2.int mileagediff = 0;
            if (filtered.isNotEmpty){
              for (FuelCar fc in filtered){
                if (fc.mileage > biggest){
                  biggest = fc.mileage;
                }
                if (fc.mileage < smallest){
                  smallest = fc.mileage;
                }
              }
              mileagediff = biggest - smallest;
            }
            _totalMileage.text = mileagediff.toString();
            return _mrFilteredList(filtered);
          }
          _usageList.forEach((usage){
            prefix2.DateTime date = _dateFormat.parse(usage.dateFueled);
            prefix2.DateTime inputTo = _dateFormat.parse(_mileageReportToDate);
            if (date.isAtSameMomentAs(inputTo) || date.isBefore(inputTo)){
              filtered.add(usage);
            }
          });
          FuelCar initialUsage = filtered.elementAt(0);
          int biggest = initialUsage.mileage;
          int smallest = initialUsage.mileage;
          prefix2.int mileagediff = 0;
          if (filtered.isNotEmpty){
            for (FuelCar fc in filtered){
              if (fc.mileage > biggest){
                biggest = fc.mileage;
              }
              if (fc.mileage < smallest){
                smallest = fc.mileage;
              }
            }
            mileagediff = biggest - smallest;
          }
          _totalMileage.text = mileagediff.toString();
          return _mrFilteredList(filtered);
        }
        if (_vehicle != null){
          int id = _vehicle.id;
          _usageList.forEach((usage){
            Vehicle v = usage.vehicle;
            int vid = v.id;
            prefix2.print('Selected vehicle id: $id, Usage vehicle id: $vid');
            if (_vehicle.id == v.id){
              filtered.add(usage);
            }
          });
          FuelCar initialUsage = filtered.elementAt(0);
          int biggest = initialUsage.mileage;
          int smallest = initialUsage.mileage;
          prefix2.int mileagediff = 0;
          if (filtered.isNotEmpty){
            for (FuelCar fc in filtered){
              if (fc.mileage > biggest){
                biggest = fc.mileage;
              }
              if (fc.mileage < smallest){
                smallest = fc.mileage;
              }
            }
            mileagediff = biggest - smallest;
          }
          _totalMileage.text = mileagediff.toString();
          return _mrFilteredList(filtered);
        }
        FuelCar initialUsage = _usageList.elementAt(0);
        int biggest = initialUsage.mileage;
        int smallest = initialUsage.mileage;
        prefix2.int mileagediff = 0;
        if (filtered.isNotEmpty){
          for (FuelCar fc in _usageList){
            if (fc.mileage > biggest){
              biggest = fc.mileage;
            }
            if (fc.mileage < smallest){
              smallest = fc.mileage;
            }
          }
          mileagediff = biggest - smallest;
        }
        _totalMileage.text = mileagediff.toString();
        return _mrFilteredList(_usageList);
      }
      return Center(child: Text('There were no transactions found'));
    }
    return Center(child: Text(_totalSpentReportMessage));
  }
}