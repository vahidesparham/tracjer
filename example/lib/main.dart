import 'package:flutter/material.dart';
import 'core/theme/theme.dart';
import 'features/home/presentation/HomeScreen.dart';
void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.defaultTheme,
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}