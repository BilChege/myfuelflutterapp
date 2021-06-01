import 'dart:convert';
import 'dart:io';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:my_fuel_flutter_app/database/SessionPrefs.dart';
import 'package:my_fuel_flutter_app/models/UserModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:page_view_indicators/page_view_indicators.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog/progress_dialog.dart';

class SambazaPageView extends StatefulWidget {
  @override
  _SambazaPageViewState createState() => _SambazaPageViewState();
}

class _SambazaPageViewState extends State<SambazaPageView> {

  PageController _controller = PageController(initialPage: 0);
  final _currentPageNotifier = ValueNotifier<int>(0);
  var _amountController = new TextEditingController();
  var _searchTextController = new TextEditingController();
  var _phoneNumberController = new TextEditingController();
  var _pinInputController = new TextEditingController();
  final _amountInputKey = GlobalKey<FormState>();
  final _pinInputKey = GlobalKey<FormState>();
  final _phoneInputKey = GlobalKey<FormState>();
  bool _pinVisible = true;
  List<Contact> _contacts;
  Balances _balances;
  BuildContext _context,_dialogContext;
  ProgressDialog _dialog;
  ProgressDialog _progressDialog;
  String _recipientsPhone;
  String _message = "Loading your contacts list ... ";
  String _amtToSend;
  bool _visible = true;
  String _searchString = "";
  MobileUser _loggedInUser;
  bool _putNumManually = false;
  bool _btnContactsVisible = true;
  bool _readContactsPermissionGranted = false;

  @override
  void initState(){
    super.initState();
    SessionPrefs().getLoggedInUser().then((user){
      setState(() {
        _loggedInUser = user;
      });
    });
    SessionPrefs().getBalances().then((balances){
      setState(() {
        _balances = balances;
      });
    });
    checkPermissionStatus(PermissionGroup.contacts).then((status){
      if(status != PermissionStatus.granted && status != PermissionStatus.disabled){
        List<PermissionGroup> permissions = [];
        permissions.add(PermissionGroup.contacts);
        requestPermission(permissions).then((status){
          PermissionStatus permissionStatus = status[PermissionGroup.contacts];
          if (permissionStatus == PermissionStatus.granted){
            setState(() {
              _readContactsPermissionGranted = true;
            });
            getContacts().then((contacts){
              int size  = contacts.length;
              print('$size contacts found, permission just granted');
              if (contacts != null){
                if (contacts.isNotEmpty){
                  List<Contact> theContacts = List<Contact>();
                  contacts.forEach((ct){
                    theContacts.add(ct);
                  });
                  setState(() {
                    _contacts = theContacts;
                  });
                } else {
                  setState(() {
                    _message = "Your contacts list is empty";
                  });
                }
              } else {
                setState(() {
                  _message = "Contacts were not found";
                });
              }
            });
          } else if (permissionStatus == PermissionStatus.denied){
            setState(() {
              _message = 'You need to give permission to MyFuel App to access your contacts';
            });
          }
        });
      } else if (status == PermissionStatus.granted){
        setState(() {
          _readContactsPermissionGranted = true;
        });
        getContacts().then((contacts){
          if (contacts != null){
            if (contacts.isNotEmpty){
              int size  = contacts.length;
              print('$size contacts found permission previously granted');
              List<Contact> theContacts = List<Contact>();
              contacts.forEach((ct){
                theContacts.add(ct);
              });
              setState(() {
                _contacts = theContacts;
              });
            } else {
              setState(() {
                _message = "Your contacts list is empty";
              });
            }
          } else {
            setState(() {
              _message = "Contacts were not found";
            });
          }
        });
      } else if (status == PermissionStatus.disabled){
        setState(() {
          _message = "You need to enable contacts permission in your settings. Go to settings -> Apps and notifications -> MyFuelApp -> Permissions and enable contacts permission";
        });
      }
    });
  }

  Future<Iterable<Contact>> getContacts() async{
    Iterable<Contact> contacts;
    try{
      print('Contacts to be fetched');
      contacts = await ContactsService.getContacts();
      int size = contacts.length;
      print('$size contacts found in background');
    } catch (e){
      setState(() {
        _message = "An error occured while fetching contacts";
      });
      print(e);
    }
    return contacts;
  }


  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      appBar: AppBar(title: Text('Sambaza Package'),backgroundColor: Colors.amber),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StepPageIndicator(
              size: 16,
              currentPageNotifier: _currentPageNotifier,
              onPageSelected: (int index){
                if (_currentPageNotifier.value > index){
                  _controller.jumpToPage(index);
                }
              },
              itemCount: 3),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              pageSnapping: true,
              onPageChanged: (int index){
                _currentPageNotifier.value = index;
              },
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Container(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,children: <Widget>[
                  Visibility(
                    visible: !_putNumManually,
                    child: Padding(padding: EdgeInsets.all(20.0),child: TextField(
                      controller: _searchTextController,
                      onChanged: (value){
                        setState(() {
                          _searchString = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search contact name",
                        prefix: Icon(Icons.search),
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.all(new Radius.circular(10.0)),
                          borderSide: new BorderSide(
                            color: Colors.pink,
                          ),
                        ),
                        labelText: 'Search'
                      ),
                    ),),
                  ),
                  _viewZeroBody()
                ],)),
                Container(
                  child: Center(child: Form(
                    key: _amountInputKey,
                    child: Column(
                      children: <Widget>[
                        Padding(padding: EdgeInsets.all(20.0),child: Text('Specify the amount to send in the input below'),),
                        Padding(padding: EdgeInsets.all(20.0),child: TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber)
                            ),
                            labelText: 'Amount',
                            hintText: 'Specify the amount to send'
                          ),
                          validator: (value){
                            double accBal = _balances.account;
                            if (value.isEmpty){
                              return 'Specify the amount to send';
                            } else{
                              double input = double.parse(_amountController.text);
                              if (input > accBal){
                                return 'Specified amount is greater than your current balance';
                              } else if (input <= 0){
                                return 'Invalid amount specified';
                              }
                            }
                            return null;
                          },
                          keyboardType: TextInputType.number,
                        ),),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: ButtonTheme( height: 50.0, child: RaisedButton(
                            color: Colors.amber,
                            onPressed: (){
                              if (_amountInputKey.currentState.validate()){
                                String toSend = _amountController.text;
                                setState(() {
                                  _amtToSend = toSend;
                                });
                                _controller.jumpToPage(2);
                              }
                            },child: Text('Next'),
                          ),),
                        )
                      ],
                    ),
                  ),),
                ),
                Container(
                  child: Center(child: Form(key:_pinInputKey,child: Column(
                    children: <Widget>[
                      Padding(padding: EdgeInsets.all(20.0),child: Text('Enter your pin below'),),
                      Padding(padding: EdgeInsets.all(20.0),child: TextFormField(
                        decoration: InputDecoration(
                          suffixIcon: IconButton(icon: Icon(_pinVisible ? Icons.visibility_off : Icons.visibility), onPressed: (){
                            setState(() {
                              _pinVisible ^= true;
                            });
                          })
                        ),
                        controller: _pinInputController,
                        obscureText: _pinVisible,
                        validator: (value){
                          if (value.isEmpty){
                            return 'Enter your pin first';
                          }
                          return null;
                        },
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                      ),),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 20.0),child: ButtonTheme(
                        height: 50.0,child: RaisedButton(child: Text('Ok'),onPressed: (){
                         if (_pinInputKey.currentState.validate()){
                           String plainTextPin = _pinInputController.text;
                           String encodedPin = base64Encode(utf8.encode(plainTextPin));
                           _progressDialog = new ProgressDialog(_context);
                           _progressDialog.style(message: 'Verifying pin ... ');
                           _progressDialog.show();
                           getTokenBasicAuth().then((token){
                             print(token);
                             verifyPin(_loggedInUser.id, encodedPin,token).then((valid){
                               if (valid){
                                 _progressDialog.update(message: 'Processing transaction ... ');
                                 String sentFrom = _loggedInUser.id.toString();
                                 String amount = _amtToSend.toString();
                                 sambazaPackage(sentFrom, _recipientsPhone, amount,token).then((balances){
                                   _progressDialog.dismiss();
                                   if (balances != null){
                                     SessionPrefs().setBalances(balances);
                                     showDialog(context: _context,builder: (BuildContext context){
                                       return AlertDialog(
                                         title: Text('Transaction Successful'),
                                         content: Text('$amount Kshs has been deducted from your MyFuel Prepay account and sent to $_recipientsPhone.'),
                                         actions: <Widget>[
                                           FlatButton(onPressed: (){
                                             Navigator.pop(context);
                                             Navigator.pop(_context);
                                           }, child: Text('Ok'))
                                         ],
                                       );
                                     });
                                   }
                                 });
                               } else {
                                 _progressDialog.dismiss();
                                 Fluttertoast.showToast(msg: 'You entered the wrong pin',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
                               }
                             });
                           });
                         }
                      }),
                      ),)
                    ],
                  ))),
                )
              ],
              physics: new NeverScrollableScrollPhysics(),
            ),
          )
        ],
      ),
      floatingActionButton: Visibility(
        visible: _btnContactsVisible,
        child: FloatingActionButton(child: Icon(_putNumManually ? Icons.contacts : Icons.dialpad),backgroundColor: Colors.amber,onPressed: (){
          setState(() {
            _putNumManually ^= true;
          });
        },),
      ),
    );
  }

  _viewZeroBody(){
    if (_putNumManually){
      return Expanded(
        child: Center(
          child: Form(
            key: _phoneInputKey,
            child: ListView(
              scrollDirection: Axis.vertical,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Enter the recipient\'s phone number manually below'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextFormField(
                    controller: _phoneNumberController,
                    decoration: InputDecoration(
                      border: new OutlineInputBorder(
                        borderSide: new BorderSide(
                          color: Colors.pink
                        )
                      ),
                      labelText: 'Enter recipient\'s phone number',
                      hintText: '(e.g 07xxxxxxxx)'
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value){
                      String ownersPhone = _loggedInUser.phone;
                      if (value.isEmpty){
                        return 'Enter recipient\'s phone number';
                      } else if (!value.startsWith('07') || value.length != 10){
                        return 'Invalid phone number';
                      } else {
                        int absInput = int.parse(value);
                        String inputVal = absInput.toString();
                        if (inputVal == ownersPhone){
                          return 'You entered your own number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                Padding(padding: EdgeInsets.all(20.0),child: ButtonTheme(
                  height: 50.0,child: RaisedButton(onPressed: (){
                    if(_phoneInputKey.currentState.validate()){
                      _doVerification(_formatPhoneNumber(_phoneNumberController.text));
                    }
                },child: Text('Validate User'),),
                ),)
              ],
            ),
          ),
        ),
      );
    }
    if (_readContactsPermissionGranted && _contacts != null){
      if (_searchString.isNotEmpty){
        List<Contact> searchResults = List<Contact>();
        _contacts.forEach((contact){
          if(contact.displayName.toLowerCase().contains(_searchString)){
            searchResults.add(contact);
          }
        });
        return Expanded(
          child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context,i){
                Contact current = searchResults.elementAt(i);
                String name = current.displayName;
                Iterable<Item> items = current.phones;
                if (items.length > 0){
                  if (items.length > 1){
                    List<Widget> children = List();
                    for (Item i in items){
                      String number = i.value;
                      children.add(ListTile(title: Text(number),onTap: (){
                        Navigator.pop(_dialogContext);
                        _doVerification(_formatPhoneNumber(number));
                      },));
                    }
                    return Column(
                      children: <Widget>[
                        ListTile(
                          title: Text(name),
                          subtitle: Text('Multiple Numbers'),
                          onTap: (){
                            showDialog(context: _context,builder: (BuildContext bc){
                              _dialogContext = bc;
                              return SimpleDialog(
                                children: children,
                              );
                            });
                          },
                        ),Divider(
                          thickness: 1.0,
                        )
                      ],
                    );
                  }
                  String number = items.elementAt(0).value;
                  return Column(
                    children: <Widget>[
                      ListTile(
                        title: Text(name),
                        subtitle: Text(number),
                        onTap: (){
                          _doVerification(_formatPhoneNumber(number));
                        },
                      ),
                      Divider(
                        thickness: 1.0,
                      )
                    ],
                  );
                }
                return Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(name),
                      subtitle: Text('No number found'),
                      onTap: (){

                      },
                    ),
                    Divider(thickness: 1.0)
                  ],
                );
              }
          ),
        );
      }
      return Expanded(
        child: ListView.builder(
            itemCount: _contacts.length,
            itemBuilder: (context,i){
              Contact current = _contacts.elementAt(i);
              String name = current.displayName;
              Iterable<Item> items = current.phones;
              if (items.length > 0){
                if (items.length > 1){
                  List<Widget> children = new List();
                  for (Item i in items){
                    String number = i.value;
                    children.add(ListTile(title: Text(number),onTap: (){
                      _doVerification(_formatPhoneNumber(number));
                    },));
                  }
                  return Column(
                    children: <Widget>[
                      ListTile(
                        title: Text(name != null ? name : 'no name'),
                        subtitle: Text('Multiple Numbers'),
                        onTap: (){
                          showDialog(context: _context,builder: (BuildContext bc){
                            return SimpleDialog(
                              contentPadding: EdgeInsets.all(8.0),
                              children: children,
                            );
                          });
                        },
                      ),
                      Divider(
                        thickness: 1.0,
                      )
                    ],
                  );
                }
                String number = items.elementAt(0).value;
                return Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(name != null ? name : 'no name'),
                      subtitle: Text(number),
                      onTap: (){
                        _doVerification(_formatPhoneNumber(number));
                      },
                    ),
                    Divider(thickness: 1.0)
                  ],
                );
              }
              return Column(
                children: <Widget>[
                  ListTile(
                    title: Text(name != null ? name : 'no name'),
                    subtitle: Text('No number found'),
                    onTap: (){

                    },
                  ),
                  Divider(thickness: 1.0)
                ],
              );
            }
        ),
      );
    }
    return Container(child: Center(child: Text('$_message')));
  }

  _doVerification(String phone){
    if(phone != flagInvalidPhoneNumber){
      int absCont = int.parse(phone);
      String phoneVal = absCont.toString();
      _dialog = new ProgressDialog(_context,isDismissible: false);
      _dialog.style(message: 'Checking user ... ');
      _dialog.show();
      getTokenBasicAuth().then((token){
        verifySystemUser(phone,token).then((user){
          _dialog.dismiss();
          if (user.id > 0){
            if (user.role != corporateUserRole){
              setState(() {
                _recipientsPhone = phoneVal;
                _btnContactsVisible = false;
              });
              _controller.jumpToPage(1);
            } else {
              Fluttertoast.showToast(msg: 'You cannot Sambaza to a corporate User',gravity: ToastGravity.BOTTOM,toastLength: Toast.LENGTH_LONG);
            }
          } else {
            Fluttertoast.showToast(msg: 'The user does not have a MyFuel prepay Account yet.',toastLength: Toast.LENGTH_LONG,gravity: ToastGravity.BOTTOM);
          }
        });
      });
    } else {
      Fluttertoast.showToast(msg: 'Invalid contact entered or selected',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
  }

  Future<MobileUser> verifySystemUser(String phoneNumber, String token) async{
    MobileUser result;
    Response response;
    try{
      response = await get(baseUrlLocal+'verifyuser?phone=$phoneNumber',headers: getHeaders(token));
    } on SocketException{
      _dialog.dismiss();
      Fluttertoast.showToast(msg: 'You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    var jsonResponse;
    if(response != null){
      int statusCode = response.statusCode;
      if (statusCode == 200){
        jsonResponse = json.decode(response.body);
        result = MobileUser.fromJson(jsonResponse);
      } else {
        _dialog.dismiss();
        Fluttertoast.showToast(msg: 'Error $statusCode occured while checking phone number',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      }
    } else {
      _dialog.dismiss();
      Fluttertoast.showToast(msg: 'No response from the server',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    return result;
  }

  Future<bool> verifyPin(int id,String input,String token) async {
    Response response;
    try{
      response = await get(baseUrlLocal+'verifypin/$id?encodedPin=$input',headers: getHeaders(token));
    } catch (e){
      _progressDialog.dismiss();
      if (e is SocketException){
        Fluttertoast.showToast(msg: 'Service is unreachable. You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      } else {
        print(e);
      }
    }
    bool result;
    var jsonResponse;
    if (response != null){
      int statusCode = response.statusCode;
      if(statusCode == 200){
        jsonResponse = json.decode(response.body);
        result = jsonResponse as bool;
      } else {
        _progressDialog.dismiss();
        Fluttertoast.showToast(msg: 'Error $statusCode Occured',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      }
    } else {
      _progressDialog.dismiss();
      Fluttertoast.showToast(msg: 'No response from the server',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    return result;
  }

  Future<Balances> sambazaPackage(String sentFrom,String sentTo,String amount,String token) async{
    Response response;
    try{
      response = await post(baseUrlLocal+'sambaza?sentfrom=$sentFrom&recipientphone=$sentTo&amount=$amount&access_token=$token');
    } on SocketException{
      _progressDialog.dismiss();
      Fluttertoast.showToast(msg: 'Service is unreachable. You may be offline',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    if (response != null){
      int responseCode =  response.statusCode;
      if (responseCode == 200){
        var jsonResponse = json.decode(response.body);
        return Balances.fromJson(jsonResponse);
      } else {
        _progressDialog.dismiss();
        Fluttertoast.showToast(msg: 'Error $responseCode Occurred',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
      }
    } else {
      _progressDialog.dismiss();
      Fluttertoast.showToast(msg: 'No response from the Server',toastLength: Toast.LENGTH_SHORT,gravity: ToastGravity.BOTTOM);
    }
    return null;
  }

  String _formatPhoneNumber(String number){
    print(number);
    if ((number.startsWith('07') || number.startsWith('+254')) && number.length>=10 && number.length<=15){
      if(number.startsWith('+254')){
        String replacement = number.replaceFirst('+254', '0');
        return replacement.replaceAll(' ', '').trim();
      }
      return number.replaceAll(' ', '').trim();
    } else {
      return flagInvalidPhoneNumber;
    }
  }
}

