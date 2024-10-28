import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'TimeAndDateRangeFilterWidget.dart';
import 'location.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> _locationMarkers = [];
  List<CircleMarker> _geofenceCircles = [];
  List<Marker> _geofenceStopMarkers = []; // دکمه استاپ برای هر Geofence
  List<LatLng> _polylinePoints = [];

  DateTime? _startTime;
  DateTime? _endTime;
  List<Map<String, dynamic>> _allLocations = [];

  @override
  void initState() {
    super.initState();
    _loadLocationsAndGeofences();
  }

  Future<void> _loadLocationsAndGeofences() async {
    final dbHelper = DatabaseHelper(interval: 10, minDistance: 10, stopTime: 10);
    List<Map<String, dynamic>> geofences = await dbHelper.getAllGeofences();
    List<Map<String, dynamic>> locations = await dbHelper.getLastLocations(10);

    setState(() {
      _allLocations = locations;
      _geofenceCircles = geofences.map((geofence) {
        bool hasPointInside = locations.any((location) {
          double distance = dbHelper.calculateDistance(
            location['latitude'],
            location['longitude'],
            geofence['latitude'],
            geofence['longitude'],
          );
          return distance <= geofence['radius'];
        });

        Color geofenceColor = hasPointInside ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5);

        return CircleMarker(
          point: LatLng(geofence['latitude'], geofence['longitude']),
          color: geofenceColor,
          borderStrokeWidth: 1.5,
          borderColor: hasPointInside ? Colors.green : Colors.red,
          useRadiusInMeter: true,
          radius: geofence['radius'],
        );
      }).toList();

      // Check if the last location is inside any geofence
      for (var geofence in geofences) {
        bool isInside = locations.any((location) {
          double distance = dbHelper.calculateDistance(
            location['latitude'],
            location['longitude'],
            geofence['latitude'],
            geofence['longitude'],
          );
          return distance <= geofence['radius'];
        });

        _geofenceStopMarkers.add(
          Marker(
            point: LatLng(geofence['latitude'], geofence['longitude']),
            builder: (ctx) {
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Geofence Options'),
                            TextButton(
                              onPressed: () {
                                // Stop functionality
                                Navigator.pop(context);
                              },
                              child: Text('Stop'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Tooltip(
                  message: 'Stop Time: ${_allLocations.isNotEmpty ? _allLocations[0]['stopTime'] : 'N/A'}',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pause,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }

      _updateMarkers(locations);
    });
  }

  void _updateMarkers(List<Map<String, dynamic>> locations) {
    _polylinePoints = locations.map((location) {
      return LatLng(location['latitude'], location['longitude']);
    }).toList();

    _locationMarkers = _polylinePoints.asMap().entries.map((entry) {
      int idx = entry.key;
      LatLng point = entry.value;

      return Marker(
        point: point,
        builder: (ctx) {
          return GestureDetector(
            onTap: () {
              final stopTime = _allLocations[idx]['stopTime'];
              showDialog(
                context: ctx,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Stop Time'),
                    content: Text('Stop Time: $stopTime'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: idx == 0
                ? Icon(Icons.play_arrow, color: Colors.green, size: 30)
                : idx == _polylinePoints.length - 1
                ? Icon(Icons.stop, color: Colors.red, size: 30)
                : Icon(Icons.location_on, color: Colors.blue, size: 25),
          );
        },
      );
    }).toList();
  }

  void showTimeAndDateRangeFilter(BuildContext context) {
    DateTime? selectedStartTime;
    DateTime? selectedEndTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TimeAndDateRangeFilterWidget(
          onConfirm: (startDateTime, endDateTime) {
            Navigator.pop(context);
            selectedStartTime = startDateTime;
            selectedEndTime = endDateTime;

            if (selectedStartTime != null && selectedEndTime != null) {
              setState(() {
                _startTime = selectedStartTime;
                _endTime = selectedEndTime;
              });

              List<Map<String, dynamic>> filteredLocations = _allLocations.where((location) {
                DateTime locationTime = DateTime.parse(location['timestamp']);
                return locationTime.isAfter(startDateTime) && locationTime.isBefore(endDateTime);
              }).toList();

              _updateMarkers(filteredLocations);
            }
          },
          onCancel: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: () => showTimeAndDateRangeFilter(context),
            ),
            Text('Map with Geofences', style: TextStyle(fontSize: 18)),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(35.6892, 51.3890),
          zoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          CircleLayer(circles: _geofenceCircles),
          MarkerLayer(markers: _locationMarkers),
          MarkerLayer(markers: _geofenceStopMarkers), // لایه برای دکمه‌های استاپ
          PolylineLayer(
            polylines: [
              Polyline(
                points: _polylinePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
