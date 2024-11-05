import 'package:flutter/material.dart';
import '../values/colors.dart';

class AppTheme {
  static final defaultTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,

    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontFamily: 'Bold',
        color: ColorSys.black_color_light,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),

      titleMedium: TextStyle(
        fontFamily: 'normal',
        color: ColorSys.title_color_normal_light,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'normal',
        color: ColorSys.title_color_normal_light,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      labelMedium: TextStyle(
        fontFamily: 'normal',
        color: ColorSys.title_color_normal_light,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      titleSmall: TextStyle(
        fontFamily: 'normal',
        color: ColorSys.title_color_light,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'normal',
        color: ColorSys.black_color_light,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),

      bodySmall: TextStyle(
        fontFamily: 'normal',
        color: ColorSys.gray_color_light,
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
    ),
  );
}
