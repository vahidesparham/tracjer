import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../core/functions/functions.dart';
import '../../../core/values/Strings.dart';
import '../../../core/values/colors.dart';
import 'CustomNavigationButton.dart';

class ExpandableCardDialog extends StatefulWidget {
  final Map<String, dynamic> geofence;
  final List<Map<String, dynamic>> allLocations;

  ExpandableCardDialog({required this.geofence, required this.allLocations});

  @override
  _ExpandableCardDialogState createState() => _ExpandableCardDialogState();
}

class _ExpandableCardDialogState extends State<ExpandableCardDialog> {
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
  void initState() {
    super.initState();
    calculateTimes();
  }

  void calculateTimes() {
    List<Map<String, dynamic>> stopPointsInGeofence =
        getPointsInGeofence(context, widget.geofence, widget.allLocations);
    for (var stopPoint in stopPointsInGeofence) {
      totalStopTime += (stopPoint['stop_time'] as num? ?? 0).toInt();
      if (entryTime == null) {
        entryTime = DateTime.parse(stopPoint['timestamp']);
      }
    }

    List<Map<String, dynamic>> stopPointsOutOfGeofence =
        getPointsOutOfGeofence(context, widget.geofence, widget.allLocations);
    for (var stopPoint in stopPointsOutOfGeofence) {
      DateTime exitCandidateTime = DateTime.parse(stopPoint['timestamp']);
      if (entryTime != null && exitCandidateTime.isAfter(entryTime!)) {
        exitTime = exitCandidateTime;
        break;
      }
    }
    setState(() {}); // Refresh the UI after calculations
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> stopPointsInGeofence =
        getPointsInGeofence(context, widget.geofence, widget.allLocations);
    List<Map<String, dynamic>> stopPointsOutOfGeofence =
        getPointsOutOfGeofence(context, widget.geofence, widget.allLocations);
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
      Dialog(
        insetPadding: EdgeInsets.only(bottom: 0), // تنظیم فاصله به پایین
        backgroundColor: Colors.transparent,
        child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Material(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        // تنظیم ارتفاع بر اساس محتوا
                        children: [
                          IconButton(
                            icon: Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                            ),
                            onPressed: _toggleExpand,
                          ),
                          Container(
                            margin: EdgeInsets.only(right: 12, left: 12),
                            alignment: Alignment.topRight,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                      widget.geofence['label'] ?? ''),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  if (!_isExpanded)
                                    CustomNavigationButton(
                                        lat: widget.geofence['label'],
                                        lng: widget.geofence['label']),
                                  SizedBox(
                                    height: 12,
                                  ),
                                ]),
                          ),
                          if (_isExpanded)
                            Column(
                              children: [
                                Container(
                                    margin:
                                        EdgeInsets.only(left: 12, right: 12),
                                    child: Divider(
                                      color:
                                          ColorSys.divider_border_color_light,
                                    )),
                                Container(
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (jalaliEntryTime != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                                 style: Theme.of(context)
                                    .textTheme
                                    .titleSmall,

                                              '${jalaliEntryTime.year}/${jalaliEntryTime.month.toString().padLeft(2, '0')}/${jalaliEntryTime.day.toString().padLeft(2, '0')} ${DateFormat.Hm().format(entryTime!)}', // Changed to Hm() to show hours and minutes
                                            ),
                                            Text(
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                                Strings.enter_time),
                                          ],
                                        ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          /*     if (exitTime != null)
                            Text(style:Theme.of(context).textTheme.bodyMedium,
                                '${DateFormat('yyyy/MM/dd HH:mm:ss').format(exitTime)}'),
                            Text(style:Theme.of(context).textTheme.bodyMedium?.copyWith(color: ColorSys.gray_color_light),Strings.exite_time,),
*/
                                          if (jalaliExitTime != null)
                                            Text(style:
    Theme.of(context)
        .textTheme
        .titleSmall,
                                              '${jalaliExitTime.year}/${jalaliExitTime.month.toString().padLeft(2, '0')}/${jalaliExitTime.day.toString().padLeft(2, '0')} ${DateFormat.Hm().format(exitTime!)}', // Changed to Hm() to show hours and minutes
                                            ),
                                          Text(
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              Strings.exite_time),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text( style:
                                          Theme.of(context)
                                              .textTheme
                                              .titleSmall,'$formattedTime'),
                                          Text(
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              Strings.stop_time
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    )))));
  }
}

void showExpandableCardDialog(BuildContext context,
    Map<String, dynamic> geofence, List<Map<String, dynamic>> allLocations) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      return ExpandableCardDialog(
          geofence: geofence, allLocations: allLocations);
    },
  );
}
