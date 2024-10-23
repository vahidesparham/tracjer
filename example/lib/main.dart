import 'package:flutter/material.dart';
import 'package:locations/location.dart';
import 'package:locations_example/DatabaseTestScreen.dart';

void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DatabaseTestScreen(),
    );
  }
}