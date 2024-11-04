import 'package:flutter/material.dart';
import 'package:locations/core/values/Strings.dart';
import 'package:locations/core/values/colors.dart';
import '../../../core/functions/functions.dart';
import 'package:intl/intl.dart';
import 'CustomNavigationButton.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class ExpandableCard extends StatefulWidget {
  int totalStopTime = 0;
  DateTime? entryTime;
  DateTime? exitTime;
  BuildContext context;
  Map<String, dynamic> geofence;
  List<Map<String, dynamic>> allLocations = [];
  ExpandableCard(
      {required this.context,
      required this.geofence,
      required this.allLocations});

  @override
  _ExpandableCardState createState() => _ExpandableCardState();

  static void showAsBottomSheet(BuildContext context,
      Map<String, dynamic> geofence, List<Map<String, dynamic>> allLocations2) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all( Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ExpandableCard(
            context: context, geofence: geofence, allLocations: allLocations2);
      },
    );
  }
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;
  int totalStopTime = 0;
  DateTime? entryTime;
  DateTime? exitTime;



  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> stopPointsInGeofence =
        getPointsInGeofence(context, widget.geofence,widget.allLocations);
    List<Map<String, dynamic>> stopPointsOutOfGeofence =
        getPointsOutOfGeofence(context, widget.geofence,widget.allLocations);
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
    final formattedTime =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';



// Convert to Jalali
    Jalali? jalaliEntryTime;
    Jalali? jalaliExitTime;

    if (entryTime != null) {
      jalaliEntryTime = Jalali.fromDateTime(entryTime!);
    }
    if (exitTime != null) {
      jalaliExitTime = Jalali.fromDateTime(exitTime!);
    }

    return
      Container(
      child: Column(
        mainAxisSize: MainAxisSize.min, // تنظیم ارتفاع بر اساس محتوا
        children: [
          IconButton(
            icon: Icon(
              _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
            ),
            onPressed: _toggleExpand,
          ),
          ListTile(
            title: Container(
              alignment: Alignment.topRight,
                child:
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                          Text(style:Theme.of(context).textTheme.titleMedium ,
                            widget.geofence['label'] ?? ''),
                        SizedBox(height: 10,),
                        if (!_isExpanded)
                          CustomNavigationButton(lat:  widget.geofence['label'],lng:  widget.geofence['label']),
                        SizedBox(height: 10,),
                        ]
            ),
            )
          ),
          if (_isExpanded)
            Column(
              children: [
                Divider(color: ColorSys.gray_color_light,),
                Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (jalaliEntryTime != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              style: Theme.of(context).textTheme.bodyMedium,
                              '${jalaliEntryTime.year}/${jalaliEntryTime.month.toString().padLeft(2, '0')}/${jalaliEntryTime.day.toString().padLeft(2, '0')} ${DateFormat.Hm().format(entryTime!)}', // Changed to Hm() to show hours and minutes
                            ),
                            Text(
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ColorSys.gray_color_light),
                              Strings.enter_time,
                            ),
                          ],
                        ),

                      SizedBox(height: 5,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                     /*     if (exitTime != null)
                            Text(style:Theme.of(context).textTheme.bodyMedium,
                                '${DateFormat('yyyy/MM/dd HH:mm:ss').format(exitTime)}'),
                            Text(style:Theme.of(context).textTheme.bodyMedium?.copyWith(color: ColorSys.gray_color_light),Strings.exite_time,),
*/
                          if (jalaliExitTime != null)
                            Text(
                              style: Theme.of(context).textTheme.bodyMedium,
                              '${jalaliExitTime.year}/${jalaliExitTime.month.toString().padLeft(2, '0')}/${jalaliExitTime.day.toString().padLeft(2, '0')} ${DateFormat.Hm().format(exitTime!)}', // Changed to Hm() to show hours and minutes
                            ),
                          Text(
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ColorSys.gray_color_light),
                            Strings.exite_time,
                          ),
                        ],
                      ),
                      SizedBox(height: 5,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                            Text(style:Theme.of(context).textTheme.bodyMedium ,'$formattedTime'),
                          Text(style:Theme.of(context).textTheme.bodyMedium?.copyWith(color: ColorSys.gray_color_light),Strings.stop_time,),

                        ],
                      ),

                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
