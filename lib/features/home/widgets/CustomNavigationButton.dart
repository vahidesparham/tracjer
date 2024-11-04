import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/values/Strings.dart';
import '../../../core/values/colors.dart';

class CustomNavigationButton extends StatefulWidget {
  final String lat;
  final String lng;

  const CustomNavigationButton({Key? key, required this.lat, required this.lng}) : super(key: key);

  @override
  _CustomNavigationButtonState createState() => _CustomNavigationButtonState();
}

class _CustomNavigationButtonState extends State<CustomNavigationButton> {
  void _launchMaps() async {

    launchUrl(
      Uri.parse("geo:${widget.lat},${widget.lng}"),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _launchMaps,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: ColorSys.blue_color_light,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Strings.navigation,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ColorSys.white_text_color_light),
              ),
              SizedBox(width: 8.0),
              Image.asset(
                "assets/images/png/navigation.png",
                fit: BoxFit.fill,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
