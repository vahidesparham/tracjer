import 'package:flutter/material.dart';
import 'package:locations/features/home/data/DatabaseHelper.dart';
class DatabaseTestScreen extends StatefulWidget {
  @override
  _DatabaseTestScreenState createState() => _DatabaseTestScreenState();
}
class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  void initState() {
    super.initState();
    _getGeofences();
    _getLocations();
  }
  final _latitudeGeofenceController = TextEditingController();
  final _longitudeGeofenceController = TextEditingController();
  final _radiusGeofenceController = TextEditingController();
  final _labelGeofenceController = TextEditingController();

  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _accuracyController = TextEditingController();
  final _speedController = TextEditingController();
  final _batteryLevelController = TextEditingController();
  bool _fakeLocationDetected = false;
  final TextEditingController _idsController = TextEditingController(); // کنترلر برای تکستفیلد

  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _offLocations = [];
  int _unsyncedCount = 0;
 bool type_off=false;
  final DatabaseHelper _dbHelper = DatabaseHelper(interval: 10, minDistance: 10,stopTime: 20);

  String _selectedActivityType = 'walking';
  final List<String> _activityTypes = ['walking', 'running', 'driving', 'off'];

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _accuracyController.dispose();
    _speedController.dispose();
    _batteryLevelController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _geofences = [];

  Future<void> _addGeofence() async {
    // اطلاعات محدوده جغرافیایی جدید
    final geofence = {
      'latitude': double.tryParse(_latitudeGeofenceController.text),
      'longitude': double.tryParse(_longitudeGeofenceController.text),
      'radius': double.tryParse(_radiusGeofenceController.text), // شعاع محدوده جغرافیایی (مثال)
      'label': _labelGeofenceController.text,
    };
    final result = await _dbHelper.insertGeofence(geofence);
    if (result>0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("محدوده جغرافیایی اضافه شد."),
      ));
      _getGeofences();
    }
  }

  Future<void> _getGeofences() async {
    final geofences = await _dbHelper.getAllGeofences();
    setState(() {
      _geofences = geofences;
    });
  }

  Future<void> _deleteGeofence(int id) async {
    await _dbHelper.deleteGeofence(id);
    _getGeofences();
  }

  Future<void> _updateGeofence(int id) async {
    final updatedGeofence = {
      'latitude': double.tryParse(_latitudeGeofenceController.text),
      'longitude': double.tryParse(_longitudeGeofenceController.text),
      'radius': double.tryParse(_radiusGeofenceController.text),
      'label': _labelGeofenceController.text,
    };
    await _dbHelper.editGeofence(id, updatedGeofence);
    _getGeofences();
  }
  Future<void> _addLocation() async {
    final latitude = double.tryParse(_latitudeController.text);
    final longitude = double.tryParse(_longitudeController.text);
    final accuracy = double.tryParse(_accuracyController.text);
    final speed = double.tryParse(_speedController.text);
    final batteryLevel = int.tryParse(_batteryLevelController.text);

    if (latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("لطفاً مقدار صحیح برای Latitude وارد کنید."),
      ));
      return;
    }

    if (longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("لطفاً مقدار صحیح برای Longitude وارد کنید."),
      ));
      return;
    }

    if (accuracy == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("لطفاً مقدار صحیح برای Accuracy وارد کنید."),
      ));
      return;
    }

    if (speed == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("لطفاً مقدار صحیح برای Speed وارد کنید."),
      ));
      return;
    }

    if (batteryLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("لطفاً مقدار صحیح برای Battery Level وارد کنید."),
      ));
      return;
    }

    final location = {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'activity_type': _selectedActivityType,
      'battery_level': batteryLevel,
      'fake_location_detected': _fakeLocationDetected,
      'timestamp': DateTime.now().toIso8601String(),
      'stop_time': 0,
    };

    int result = await _dbHelper.insertLocation(location);
    if (result==1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("لوکیشن با موفقیت اضافه شد."),
      ));
      _getLocations();
    } else if(result==2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("رکورد بروزرسانی شد"),
      ));
    }else{
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("خطا در اضافه کردن لوکیشن به دیتابیس."),
      ));
    }
  }

  Future<void> _getLocations() async {
    final locations = await _dbHelper.getAllLocations();
    setState(() {
      _locations = locations;
      type_off=false;

    });
  }

  Future<void> _getUnsyncedCount() async {
    final count = await _dbHelper.numberOfUnSyncedLocations();
    setState(() {
      _unsyncedCount = count;
    });
  }

  Future<void> _deleteSyncedLocations() async {
    await _dbHelper.deleteSyncedLocations();
    _getLocations();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("لوکیشن‌های synced حذف شدند"),
    ));
  }

  Future<void> _getOffLocations() async {
    final offLocations = await _dbHelper.getOffLocations();
    setState(() {
      _offLocations = offLocations;
      type_off=true;
    });
  }


  Future<void> _eraseDatabase() async {
    await _dbHelper.eraseDatabase();
    _getLocations();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("دیتابیس پاک شد"),
    ));
  }
  Future<void> setSyncedLocations(List<int> ids) async {

    await _dbHelper.setSyncedLocations(ids);

  }

  void _syncLocations() {
    String inputText = _idsController.text;
    List<int> ids = inputText.split(',').map((id) => int.tryParse(id.trim())!).toList();

    setSyncedLocations(ids).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بروزرسانی شد')),

      );
      _idsController.clear();
      _getLocations();

    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $error')),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Test Screen'),
      ),
      body:
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('add Geofence'),
              TextField(
                controller: _latitudeGeofenceController,
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _longitudeGeofenceController,
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _radiusGeofenceController,
                decoration: InputDecoration(labelText: 'radius'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _labelGeofenceController,
                decoration: InputDecoration(labelText: 'label'),
                keyboardType: TextInputType.text,
              ),
              ElevatedButton(
                onPressed: _addGeofence,
                child: Text('اضافه کردن محدوده جغرافیایی'),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _geofences.length,
                itemBuilder: (context, index) {
                  final geofence = _geofences[index];
                  return ListTile(
                    title: Text('Latitude: ${geofence['latitude']}, Longitude: ${geofence['longitude']}'),
                    subtitle: Text('radius: ${geofence['radius']} - label: ${geofence['label']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _updateGeofence(geofence['id']),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteGeofence(geofence['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 20,),
              Text('add Location'),
              TextField(
                controller: _latitudeController,
                decoration: InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _longitudeController,
                decoration: InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _accuracyController,
                decoration: InputDecoration(labelText: 'Accuracy'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _speedController,
                decoration: InputDecoration(labelText: 'Speed'),
                keyboardType: TextInputType.number,
              ),
              DropdownButton<String>(
                value: _selectedActivityType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedActivityType = newValue!;
                  });
                },
                items: _activityTypes.map((String activity) {
                  return DropdownMenuItem<String>(
                    value: activity,
                    child: Text(activity),
                  );
                }).toList(),
              ),
              TextField(
                controller: _batteryLevelController,
                decoration: InputDecoration(labelText: 'Battery Level'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fake Location Detected:'),
                  Switch(
                    value: _fakeLocationDetected,
                    onChanged: (value) {
                      setState(() {
                        _fakeLocationDetected = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),



              TextField(
                controller: _idsController,
                decoration: InputDecoration(

                    labelText: 'Enter IDs (comma separated)'
                ),
                keyboardType: TextInputType.text,
              ),
              ElevatedButton(
                onPressed: _syncLocations,
                child: Text('true کزدن مقادیر isSync'),
              ),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addLocation,
                      child: Text('اضافه کردن لوکیشن'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _eraseDatabase,
                      child: Text('پاک کردن دیتابیس'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _getUnsyncedCount,
                      child: Text('تعداد unsynced locations'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _deleteSyncedLocations,
                      child: Text('حذف synced locations'),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _getLocations,
                      child: Text('دریافت لوکیشن‌ها'),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _getOffLocations,
                      child: Text('دریافت لوکیشن‌های off'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              new Center(
                  child: type_off == false ?
                      new Column(
                        children: [
                          Text('تعداد unsynced locations: $_unsyncedCount'),
                          SizedBox(height: 20),
                          _locations.isEmpty
                              ? Center(child: Text('هیچ لوکیشنی وجود ندارد'))
                              : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _locations.length,
                            itemBuilder: (context, index) {
                              final location = _locations[index];
                              return ListTile(
                                title: Text(
                                    'id: ${location['id']},Latitude: ${location['latitude']}, Longitude: ${location['longitude']}'),
                                subtitle: Text(
                                    'Accuracy: ${location['accuracy']}, Speed: ${location['speed']}, Activity: ${location['activity_type']}, Battery: ${location['battery_level']}'
                                        ', Fake Detected: ${location['fake_location_detected']}'', time&date: ${location['timestamp']}, stop_time: ${location['stop_time']}, is_sync: ${location['isSync']==0?'false':'true'}'),
                              );
                            },
                          ),
                        ],
                      )
                      :   new Column(
                    children: [
                      Text('تعداد unsynced locations: $_unsyncedCount'),
                      SizedBox(height: 20),
                      _offLocations.isEmpty
                          ? Center(child: Text('هیچ لوکیشنی وجود ندارد'))
                          : ListView.builder(


                        shrinkWrap: true,
                        itemCount: _offLocations.length,
                        itemBuilder: (context, index) {
                          final location = _offLocations[index];
                          return ListTile(
                            title: Text(
                                'Latitude: ${location['latitude']}, Longitude: ${location['longitude']}'),
                            subtitle: Text(
                                'Accuracy: ${location['accuracy']}, '
                                    'Speed: ${location['speed']},'
                                    ' Activity: ${location['activity_type']},'
                                    ' Battery: ${location['battery_level']}'
                                    ', Fake Detected: ${location['fake_location_detected']}'
                                    ', Fake Detected: ${location['fake_location_detected']}'),
                          );
                        },
                      ),
                    ],
                  )
              ),

            ],
          ),
        ),
      ),
    );
  }
}
