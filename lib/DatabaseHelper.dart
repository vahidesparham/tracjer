import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static double? intervalBase;
  static double? minDistanceBase;
  static int? minStopTime;

  factory DatabaseHelper({required double interval, required double minDistance,required int stopTime }) {
   intervalBase=interval;
   minDistanceBase=minDistance;
   minStopTime = stopTime;
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
        fake_location_detected BOOLEAN DEFAULT 0,
        stop_time INTEGER DEFAULT 0
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


  Future<int> insertLocation(Map<String, dynamic> location) async {
    final db = await database;

    List<Map<String, dynamic>> lastLocations = await db.query(
      'locations',
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    Map<String, dynamic>? lastGeofence,newGeofence;
    if (lastLocations.isNotEmpty) {
      Map<String, dynamic> lastLocation = lastLocations.first;

     lastGeofence = await _checkGeofence(lastLocation);
     newGeofence = await _checkGeofence(location);

      DateTime lastTimestamp = DateTime.parse(lastLocation['timestamp']);
      DateTime currentTimestamp = DateTime.now();
      double timeDifference = currentTimestamp.difference(lastTimestamp).inSeconds.toDouble();
      double distance = calculateDistance(lastLocation['latitude'], lastLocation['longitude'], location['latitude'], location['longitude']);

      // چک کردن فاصله و زمان
      if (timeDifference < intervalBase! || distance < minDistanceBase!) {
        int stopTime = calculateStopTime(distance, timeDifference);

          await db.update(
            'locations',
            {
              'timestamp': currentTimestamp.toIso8601String(),
              'isSync': false,
              'stop_time': stopTime,
            },
            where: 'id = ?',
            whereArgs: [lastLocation['id']],
          );
          return 2;
      }
    else if (lastGeofence != null && lastGeofence['id'] == newGeofence?['id'])
    {
        int previousStopTime = lastLocation['stop_time'] ?? 0;
        int stopTime = previousStopTime + timeDifference.toInt();
        await db.update(
        'locations',
        {
        'timestamp': currentTimestamp.toIso8601String(),
        'isSync': false,
        'stop_time': stopTime,
         'latitude':lastGeofence['latitude'],
         'longitude':lastGeofence['longitude']
        },
        where: 'id = ?',
        whereArgs: [lastLocation['id']],
        );
        return 2;
    }
    }

    Map<String, dynamic>?   geofence = await  _checkGeofence(location);
    if(geofence==null){
      int? geofenceId=geofence?['id'];
      await db.insert('locations', {
        ...location,
        'geofence_id': geofenceId,
        'isSync': true,
        'stop_time': 0,
      });
    }else{
      int? geofenceId=geofence?['id'];
      await db.insert('locations', {
        ...location,
        'geofence_id': geofenceId,
        'isSync': false,
        'stop_time': 0,
        'latitude':geofence['latitude'],
        'longitude':geofence['longitude']
      });
    }

    return 1;
  }

  int calculateStopTime(double distance, double timeDifference) {
    // محاسبه زمان توقف فقط در صورتی که فاصله کمتر از حداقل فاصله و زمان بیشتر از حداقل زمان باشد
    if (distance < minDistanceBase! && timeDifference > minStopTime!) {
      return timeDifference.toInt();
    }
    return 0;
  }
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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

  Future<Map<String, dynamic>?> _checkGeofence(Map<String, dynamic> location) async {
    final db = await database;
    List<Map<String, dynamic>> geofences = await db.query('geofences');
    for (var geofence in geofences) {
      double distance = calculateDistance(
        location['latitude'],
        location['longitude'],
        geofence['latitude'],
        geofence['longitude'],
      );

      if (distance <= geofence['radius']) {
        return geofence;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getLastLocations(int n) async {
    final db = await database;
    return await db.query(
      'locations',
      where: 'isSync = ?',
      whereArgs: [true],
      orderBy: 'timestamp DESC',
      limit: n,
    );
  }

  Future<List<Map<String, dynamic>>> getAllLocations() async {
    final db = await database;
    return await db.query(
      'locations'
        /*,
      where: 'isSync = ?',
      whereArgs: [true]*/
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
    return await db.query('geofences',
      orderBy: 'id DESC',
    );
  }
}
