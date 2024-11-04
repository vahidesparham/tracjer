import 'package:flutter/material.dart';
import '../values/colors.dart';
class theme {
  static final lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontFamily: 'regular',
        color: ColorSys.text_title_color_lighte,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),

    ),

  );

}