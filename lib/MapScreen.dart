import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'TimeAndDateRangeFilterWidget.dart';
import 'DatabaseHelper.dart';
import 'package:intl/intl.dart';

class MapScreen extends StatefulWidget {
  late  List<LatLng> points;

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng initialPosition = LatLng(35.6892, 51.3890);

  List<Marker> _locationMarkers = [];
  List<CircleMarker> _geofenceCircles = [];
  List<Marker> _geofenceStopMarkers = [];
  List<LatLng> _polylinePoints = [];
  final TextEditingController _idsController = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;
  List<Map<String, dynamic>> _allLocations = [];


  @override
  void initState() {
    super.initState();
    _loadLocationsAndGeofences();
  }

  Future<void> _loadLocationsAndGeofences() async {
    final dbHelper = DatabaseHelper(
        interval: 10, minDistance: 10, stopTime: 10);
    List<Map<String, dynamic>> geofences = await dbHelper.getAllGeofences();
    List<Map<String, dynamic>> locations = await dbHelper.getAllLocations();
    setState(() {
      if (locations.isNotEmpty) {
        initialPosition = LatLng(locations.first['latitude'], locations.first['longitude']);
      }
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

        Color geofenceColor = hasPointInside
            ? Colors.green.withOpacity(0.5)
            : Colors.red.withOpacity(0.5);

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
              List<Map<String,
                  dynamic>> stopPointsInGeofence = _getPointsInGeofence(
                  context, geofence);
              List<Map<String, dynamic>> stopPointsOutOfGeofence = _getPointsOutOfGeofence(context, geofence);

              return
                GestureDetector(
                  onTap: () {
                    _showBottomSheetStopPointsInGeofence(context, geofence);
                  },
                  child: stopPointsInGeofence.isNotEmpty
                      ?
                  Container(
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
                  ) : SizedBox.shrink(),
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

    _locationMarkers = _polylinePoints
        .asMap()
        .entries
        .map((entry) {
      int idx = entry.key;
      LatLng point = entry.value;

      return Marker(
        point: point,
        builder: (ctx) {
          final timestamp = _allLocations[idx]['timestamp'];
          DateTime locationTime = DateTime.parse(timestamp);
          Jalali jalaliDate = Jalali.fromDateTime(locationTime);
          String formattedDateTime = '${jalaliDate.year}/${jalaliDate.month
              .toString().padLeft(2, '0')}/${jalaliDate.day.toString().padLeft(
              2, '0')} ${DateFormat.Hms().format(locationTime)}';
          return
            GestureDetector(
            onTap: () {
              final int stopTimeInSeconds = _allLocations[idx]['stop_time'] ??
                  0;
              Duration duration = Duration(seconds: stopTimeInSeconds);
              String formattedStopTime = '${duration.inHours.toString().padLeft(
                  2, '0')}:'
                  '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:'
                  '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Center(
                            child: Text(
                              'اطلاعات مارکر',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('مارکر #$idx'),
                          ),
                          SizedBox(height: 8.0),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('زمان ثبت: $formattedDateTime'),
                          ),

                          SizedBox(height: 8.0),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text('زمان توقف: $formattedStopTime'),
                          ),
                          SizedBox(height: 16.0),
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              child: Text('بستن'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );



            },
            child: idx == 0
                ? Icon(Icons.play_arrow, color: Colors.green, size: 30)
                : idx == _polylinePoints.length - 1
                ? Icon(Icons.stop,color: Colors.red, size: 30)
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

              List<Map<String, dynamic>> filteredLocations = _allLocations
                  .where((location) {
                DateTime locationTime = DateTime.parse(location['timestamp']);
                return locationTime.isAfter(startDateTime) &&
                    locationTime.isBefore(endDateTime);
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
          center: initialPosition,
          zoom: 13,
          onTap: (tapPosition, point) {
            final textToCopy = 'lat: ${point.latitude}, lon: ${point
                .longitude}';
            Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('کپی شد: $textToCopy')),
              );
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          CircleLayer(circles: _geofenceCircles),
          PolylineLayer(
            polylines: [
              Polyline(
                points: _polylinePoints,
                strokeWidth: 4.0,
                color: Colors.blue,
              ),
            ],
          ),
          MarkerLayer(markers: _locationMarkers),
          MarkerLayer(markers: _geofenceStopMarkers),
        ],
      ),

    );
  }

  List<Map<String, dynamic>> _getPointsInGeofence(BuildContext context,
      Map<String, dynamic> geofence) {
    final dbHelper = DatabaseHelper(
        interval: 10, minDistance: 10, stopTime: 10);

    // فیلتر کردن نقاط توقفی که در این ناحیه قرار دارند
    List<Map<String, dynamic>> stopPointsInGeofence = _allLocations.where((
        location) {
      double distance = dbHelper.calculateDistance(
        location['latitude'],
        location['longitude'],
        geofence['latitude'],
        geofence['longitude'],
      );
      return distance <= geofence['radius'] && (location['stop_time'] ?? 0) > 0;
    }).toList();
    return stopPointsInGeofence;
  }
  List<Map<String, dynamic>> _getPointsOutOfGeofence(BuildContext context, Map<String, dynamic> geofence) {
    final dbHelper = DatabaseHelper(interval: 10, minDistance: 10, stopTime: 10);

    // فیلتر کردن نقاط توقفی که در این ناحیه قرار ندارند
    List<Map<String, dynamic>> pointsOutOfGeofence = _allLocations.where((location) {
      double distance = dbHelper.calculateDistance(

        location['latitude'],
        location['longitude'],
        geofence['latitude'],
        geofence['longitude'],
      );
      return distance > geofence['radius'];
    }).toList();

    return pointsOutOfGeofence;
  }
  void _showBottomSheetStopPointsInGeofence(BuildContext context,
      Map<String, dynamic> geofence) {
    final label = geofence['label'];

    // فیلتر کردن نقاط توقفی که در این ناحیه قرار دارند
    List<Map<String, dynamic>> stopPointsInGeofence = _getPointsInGeofence(
        context, geofence);
    List<
        Map<String, dynamic>> stopPointsOutOfGeofence = _getPointsOutOfGeofence(
        context, geofence);

    int totalStopTime = 0;
    DateTime? entryTime;
    DateTime? exitTime;

    for (var stopPoint in stopPointsInGeofence) {
      totalStopTime += (stopPoint['stop_time'] as num? ?? 0).toInt();
      if (entryTime == null) {
        entryTime = DateTime.parse(stopPoint['timestamp']); // زمان ورود
      }
    }

    for (var stopPoint in stopPointsOutOfGeofence) {
      DateTime exitCandidateTime = DateTime.parse(stopPoint['timestamp']);
      if (entryTime != null && exitCandidateTime.isAfter(entryTime!)) {
        exitTime = exitCandidateTime;
        break;
      }
    }

    final int hours = totalStopTime ~/ 3600;
    final int minutes = (totalStopTime % 3600) ~/ 60;
    final int seconds = totalStopTime % 60;

    final formattedTime = '${hours.toString().padLeft(2, '0')}:${minutes
        .toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              stopPointsInGeofence.isNotEmpty
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مجموع زمان توقف: $formattedTime'),
                  SizedBox(height: 10),
                  if (entryTime != null)
                    Text('زمان ورود: ${DateFormat('yyyy/MM/dd HH:mm:ss').format(
                        entryTime)}'),
                  if (exitTime != null)
                    Text('زمان خروج: ${DateFormat('yyyy/MM/dd HH:mm:ss').format(
                        exitTime)}'),
                ],
              )
                  : Text('هیچ نقطه توقفی در این محدوده یافت نشد.'),
              Container(
                alignment: Alignment.center,
                child: TextButton(
                  child: Text('بستن'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

