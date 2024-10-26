import 'package:flutter/material.dart';
import 'package:locations/location.dart';
class DatabaseTestScreen extends StatefulWidget {
  @override
  _DatabaseTestScreenState createState() => _DatabaseTestScreenState();
}
class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _accuracyController = TextEditingController();
  final _speedController = TextEditingController();
  final _batteryLevelController = TextEditingController();
  bool _fakeLocationDetected = false;

  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _offLocations = [];
  int _unsyncedCount = 0;
 bool type_off=false;
  final DatabaseHelper _dbHelper = DatabaseHelper(interval: 10, minDistance: 10);

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
    };

    final result = await _dbHelper.insertLocation(location);
    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("لوکیشن با موفقیت اضافه شد."),
      ));
      _getLocations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("خطا در اضافه کردن لوکیشن به دیتابیس."),
      ));
    }
  }


  Future<void> _getLocations() async {
    final locations = await _dbHelper.getLastLocations(10);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Test Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                                    'Latitude: ${location['latitude']}, Longitude: ${location['longitude']}'),
                                subtitle: Text(
                                    'Accuracy: ${location['accuracy']}, Speed: ${location['speed']}, Activity: ${location['activity_type']}, Battery: ${location['battery_level']}, Fake Detected: ${location['fake_location_detected']}'),
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
                                'Accuracy: ${location['accuracy']}, Speed: ${location['speed']}, Activity: ${location['activity_type']}, Battery: ${location['battery_level']}, Fake Detected: ${location['fake_location_detected']}'),
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
