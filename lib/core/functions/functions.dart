import 'package:flutter/cupertino.dart';

import '../../features/home/data/DatabaseHelper.dart';

List<Map<String, dynamic>> getPointsInGeofence(
    BuildContext context, Map<String, dynamic> geofence,List<Map<String, dynamic>> allLocations) {
  final dbHelper =
  DatabaseHelper(interval: 10, minDistance: 10, stopTime: 10);
  List<Map<String, dynamic>> stopPointsInGeofence =
  allLocations.where((location) {
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

List<Map<String, dynamic>> getPointsOutOfGeofence(
    BuildContext context, Map<String, dynamic> geofence,List<Map<String, dynamic>> allLocations) {
  final dbHelper =
  DatabaseHelper(interval: 10, minDistance: 10, stopTime: 10);
  List<Map<String, dynamic>> pointsOutOfGeofence =
  allLocations.where((location) {
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