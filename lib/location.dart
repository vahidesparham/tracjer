import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static double? intervalBase;
  static double? minDistanceBase;
  factory DatabaseHelper({required double interval, required double minDistance}) {
   intervalBase=interval;
   minDistanceBase=minDistance;
    return _instance;

  }
  DatabaseHelper._internal();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }


Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(),'my_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: onCreate,
    );
  }

  Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL,
        speed REAL,
        activity_type TEXT CHECK(activity_type IN ('walking', 'running', 'driving', 'off')),
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        battery_level INTEGER,
        geofence_id INTEGER,
        isSync BOOLEAN,
        fake_location_detected BOOLEAN DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE geofences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius REAL NOT NULL,
        label TEXT
      );
    ''');
  }

  Future<bool> insertLocation(Map<String, dynamic> location) async {
    final db = await database;

    List<Map<String, dynamic>> lastLocations = await db.query(
      'locations',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (lastLocations.isNotEmpty) {
      Map<String, dynamic> lastLocation = lastLocations.first;

      DateTime lastTimestamp = DateTime.parse(lastLocation['timestamp']);
      DateTime currentTimestamp = DateTime.now();
      double timeDifference = currentTimestamp.difference(lastTimestamp).inSeconds.toDouble();
      double distance = _calculateDistance(lastLocation['latitude'], lastLocation['longitude'], location['latitude'], location['longitude']);

      if (timeDifference < intervalBase!

           || distance < minDistanceBase!) {
        return false;
      }
    }

    int? geofenceId = await _checkGeofence(location);
    await db.insert('locations', {
      ...location,
      'geofence_id': geofenceId,
      'isSync': false,
    });
    return true;
  }


  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3;
    double phi1 = lat1 * (3.14159265359 / 180);
    double phi2 = lat2 * (3.14159265359 / 180);
    double deltaPhi = (lat2 - lat1) * (3.14159265359 / 180);
    double deltaLambda = (lon2 - lon1) * (3.14159265359 / 180);

    double a = (sin(deltaPhi / 2) * sin(deltaPhi / 2)) +
        (cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  Future<int?> _checkGeofence(Map<String, dynamic> location) async {
    final db = await database;

    List<Map<String, dynamic>> geofences = await db.query('geofences');

    for (var geofence in geofences) {
      double distance = _calculateDistance(
        location['latitude'],
        location['longitude'],
        geofence['latitude'],
        geofence['longitude'],
      );

      if (distance <= geofence['radius']) {
        return geofence['id'];
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getLastLocations(int n) async {
    final db = await database;
    return await db.query(
      'locations',
      where: 'isSync = ?',
      whereArgs: [false],
      orderBy: 'timestamp DESC',
      limit: n,
    );
  }

  Future<int> numberOfUnSyncedLocations() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'locations',
      where: 'isSync = ?',
      whereArgs: [false],
    );
    return result.length;
  }

  Future<Map<String, dynamic>?> getLastLocation() async {
    final db = await database;
    List<Map<String, dynamic>> lastLocations = await db.query(
      'locations',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    return lastLocations.isNotEmpty ? lastLocations.first : null;
  }

  Future<void> setSyncedLocations(List<int> ids) async {
    final db = await database;
    for (int id in ids) {
      await db.update(
        'locations',
        {'isSync': true},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> deleteSyncedLocations() async {
    final db = await database;
    await db.delete('locations', where: 'isSync = ?', whereArgs: [true]);
  }

  Future<List<Map<String, dynamic>>> getOffLocations() async {
    final db = await database;
    return await db.query(
      'locations',
      where: 'activity_type = ?',
      whereArgs: ['off'],
    );
  }

  Future<void> eraseDatabase() async {
    final db = await database;
    await db.delete('locations');
    await db.delete('geofences');
  }

  Future<int> insertGeofence(Map<String, dynamic> geofence) async {
    final db = await database;
    return await db.insert('geofences', geofence);
  }

  Future<int> editGeofence(int id, Map<String, dynamic> updatedGeofence) async {
    final db = await database;
    return await db.update(
      'geofences',
      updatedGeofence,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGeofence(int id) async {
    final db = await database;
    return await db.delete(
      'geofences',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllGeofences() async {
    final db = await database;
    return await db.query('geofences');
  }
}
