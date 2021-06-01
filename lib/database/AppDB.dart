import 'dart:async';
import 'dart:collection';
import 'dart:core';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:my_fuel_flutter_app/models/VehicleModels.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart';
import 'package:my_fuel_flutter_app/utils/Config.dart' as prefix0;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDB{
  AppDB._privateConstructor();
  static final AppDB appDB = AppDB._privateConstructor();
  static final String _createTbVehicles = 'CREATE TABLE IF NOT EXISTS $tbVehicle('
      '$id INT PRIMARY KEY,'
      '$regNo VARCHAR(50),'
      '$make VARCHAR(100),'
      '$makeId INT,'
      '$mileage INT,'
      '$active INT,'
      '$consumptionRate INT,'
      '$modelId INT,'
      '$keyUser INT,'
      '$ccs VARCHAR(50),'
      '$engineType VARCHAR(50))';
  static final String _createTbDealers = 'CREATE TABLE IF NOT EXISTS $dealer('
      '$id INT PRIMARY KEY,'
      '$name VARCHAR(200),'
      '$stationId VARCHAR(10),'
      '$latitude REAL,'
      '$rating REAL,'
      '$longitude REAL)';
  static final String _dropTbVehicles = 'DROP TABLE IF EXISTS $tbVehicle';
  static final String _dropTbDealers = 'DROP TABLE IF EXISTS $dealer';
  
  static Database _database;
  Future<Database> get database async{
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path,appDb);
    return await openDatabase(path,version: 1,onCreate: _onCreate,onUpgrade: _onUpgrade);
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute(_createTbVehicles);
    await db.execute(_createTbDealers);
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) {
    db.execute(_dropTbDealers);
    db.execute(_dropTbVehicles);
    _onCreate(db, 1);
  }

  Future<int> save(String tableName, Map <String, dynamic> row) async{
    Database db = await appDB.database;
    return await db.insert(tableName, row);
  }

  Future<int> update(String tableName, Map <String, dynamic> row) async{
     int idVal = row[prefix0.id];
     Database db = await appDB.database;
     return await db.update(tableName, row, where: '$id = ?',whereArgs: [idVal]);
  }

  Future<List<Map<String,dynamic>>> findAll(String tableName) async{
    Database db = await appDB.database;
    return db.query(tableName);
  }

  Future<List<Map<String,dynamic>>> findById(String tableName, int id) async{
    print('Insert into table $tableName to be done');
    Database db = await appDB.database;
    return db.query(tableName,distinct: true,where: '$id = ?',whereArgs: [id]);
  }

  Future<List<Map<String,dynamic>>> findByQuery(String query,List<dynamic> selectionArgs) async{
    Database db = await appDB.database;
    print('Find by query invoked');
    return db.rawQuery(query,selectionArgs);
  }

  clearTable(String tbName) async{
    Database db = await appDB.database;
    db.execute('delete from $tbName');
  }
}