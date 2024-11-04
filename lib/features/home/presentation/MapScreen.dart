import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:locations/core/values/Strings.dart';
import 'package:locations/core/values/colors.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/functions/functions.dart';
import '../data/DatabaseHelper.dart';
import '../widgets/CustomTooltip.dart';
import '../widgets/ExpandableCard.dart';
import '../widgets/TimeAndDateRangeFilterWidget.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/appbar_map.dart';
class MapScreen extends StatefulWidget {
  late List<LatLng> points;
  @override
  _MapScreenState createState() => _MapScreenState();
}
class _MapScreenState extends State<MapScreen> {
  LatLng initialPosition = LatLng(35.6892, 51.3890);
  final MapController _mapController = MapController();
  List<Marker> _locationMarkers = [];
  List<CircleMarker> _geofenceCircles = [];
  List<Marker> _geofenceStopMarkers = [];
  List<LatLng> _polylinePoints = [];
  DateTime? _startTime;
  DateTime? _endTime;
  List<Map<String, dynamic>> allLocations = [];
  @override
  void initState() {
    super.initState();
    _loadLocationsAndGeofences();
  }

  Future<void> _goToCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // پیغام خطا یا درخواست دوباره دسترسی
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        16.0, // میزان زوم
      );
    });
  }

  Future<void> _loadLocationsAndGeofences() async {
    final dbHelper =
    DatabaseHelper(interval: 10, minDistance: 10, stopTime: 10);
    List<Map<String, dynamic>> geofences = await dbHelper.getAllGeofences();
    List<Map<String, dynamic>> locations = await dbHelper.getAllLocations();
    setState(() {
      if (locations.isNotEmpty) {
        initialPosition =
            LatLng(locations.last['latitude'], locations.last['longitude']);
        setState(() {
          _mapController.move(
            LatLng(initialPosition.latitude, initialPosition.longitude),
            13.0, // میزان زوم
          );
        });
      }
      allLocations = locations;
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
            ? ColorSys.green_color_light.withOpacity(0.12)
            : ColorSys.red_color_light.withOpacity(0.12);

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
              List<Map<String, dynamic>> stopPointsInGeofence =
              getPointsInGeofence(context, geofence,allLocations);
              List<Map<String, dynamic>> stopPointsOutOfGeofence =
              getPointsOutOfGeofence(context, geofence,allLocations);

              return GestureDetector(
                onTap: () {
                  ExpandableCard.showAsBottomSheet(context, geofence,allLocations);
                },
                child: stopPointsInGeofence.isNotEmpty
                    ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ColorSys.yellow_color_light,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pause,
                    color: Colors.white,
                    size: 20,
                  ),
                )
                    : SizedBox.shrink(),
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
          final timestamp = allLocations[idx]['timestamp'];
          DateTime locationTime = DateTime.parse(timestamp);
          Jalali jalaliDate = Jalali.fromDateTime(locationTime);
          String formattedDateTime =
              '${jalaliDate.year}/${jalaliDate.month.toString().padLeft(2, '0')}/${jalaliDate.day.toString().padLeft(2, '0')} ${DateFormat.Hms().format(locationTime)}';

          final int stopTimeInSeconds = allLocations[idx]['stop_time'] ?? 0;
          bool hasStop = stopTimeInSeconds > 0;

          Duration duration = Duration(seconds: stopTimeInSeconds);
          String formattedStopTime =
              '${duration.inHours.toString().padLeft(2, '0')}:'
              '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:'
              '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

          return GestureDetector(
            onTap: () {
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
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
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
            child: CustomTooltip(
              message: hasStop
                  ? "$formattedStopTime"
                  : idx == 0
                  ? "شروع مسیر"
                  : idx == _polylinePoints.length - 1
                  ? "پایان مسیر"
                  : "مارکر #$idx",
              child: allLocations[idx].containsKey('stop_time') &&
                  allLocations[idx]['stop_time'] > 0
                  ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorSys.yellow_color_light,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pause,
                  color: Colors.white,
                  size: 20,
                ),
              )
                  : idx == 0
                  ? Image.asset(
                width: 16,
                height: 16,
                "assets/images/png/start.png",
                fit: BoxFit.fill,
              )
                  : idx == _polylinePoints.length - 1
                  ? Image.asset(
                width: 16,
                height: 16,
                "assets/images/png/end.png",
                fit: BoxFit.fill,
              )
                  : SizedBox.shrink(),
            ),
          );
        },
      );

    }).toList();
  }

  void showTimeAndDateRangeFilter() {
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

              List<Map<String, dynamic>> filteredLocations =
              allLocations.where((location) {
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
      appBar: appbar_map(
          title: Strings.app_name, action: showTimeAndDateRangeFilter),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: initialPosition,
          zoom: 13,
          onTap: (tapPosition, point) {
            final textToCopy = '${point.latitude},${point.longitude}';
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
                  color: ColorSys.red_color_light),
            ],
          ),
          MarkerLayer(markers: _locationMarkers),
          MarkerLayer(markers: _geofenceStopMarkers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        backgroundColor: Colors.white,
        // پس‌زمینه سفید، مشابه دکمه گوگل
        shape: CircleBorder(),
        // شکل دایره‌ای
        child: Icon(
          Icons.my_location,
          color: Colors.blue, // رنگ آیکون آبی
          size: 28, // اندازه آیکون کمی بزرگ‌تر
        ),
        elevation: 5, // ایجاد سایه برای شبیه‌تر شدن به دکمه گوگل
      ),
    );
  }
}
