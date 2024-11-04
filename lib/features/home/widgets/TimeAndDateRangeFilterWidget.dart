import 'package:flutter/material.dart';
import 'package:locations/core/values/Strings.dart';
import 'package:locations/core/values/colors.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class TimeAndDateRangeFilterWidget extends StatelessWidget {
  final VoidCallback onCancel;
  final Function(DateTime startDateTime, DateTime endDateTime) onConfirm;

  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  Jalali? fromDate;
  Jalali? toDate;

  final TextEditingController fromTimeController = TextEditingController();
  final TextEditingController toTimeController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  TimeAndDateRangeFilterWidget({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.close),
                onPressed: onCancel,
              ),
              Text(
                Strings.filter_by_time,
                style:Theme.of(context).textTheme.bodyMedium ,

              ),
            ],
          ),
          SizedBox(height: 16),
          _buildDateTimeFields(context),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (fromTime != null && toTime != null && fromDate != null && toDate != null) {
                    final startDateTime = fromDate!.toDateTime().add(
                      Duration(hours: fromTime!.hour, minutes: fromTime!.minute),
                    );
                    final endDateTime = toDate!.toDateTime().add(
                      Duration(hours: toTime!.hour, minutes: toTime!.minute),
                    );
                    onConfirm(startDateTime, endDateTime);
                  }
                },
                child:
                Container(
                    decoration: BoxDecoration(
                      color: ColorSys.blue_color_light,
                      borderRadius: BorderRadius.circular(10), // مقدار گردی گوشه‌ها
                    ),
                    width: 80,
                    height: 50,
                    child:
                    Center(
                      child:
                      Text(
                        Strings.accept,
                        style:Theme.of(context).textTheme.bodyMedium!.copyWith(color: ColorSys.white_text_color_light) ,
                    ),

                    )
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  onCancel();
                },
                child:
                Container(
                    decoration:
                    BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey,width: 1),
                        ),
                    width: 73,
                    height: 50,
                    child:
                    Center(
                      child:
                      Text(
                       Strings.cancel,
                        style:Theme.of(context).textTheme.bodyMedium ,
                      ),

                    )
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeFields(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [



            Expanded(
                child:
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(Strings.time,
                      style:Theme.of(context).textTheme.bodyMedium ,
                    ),
                    _TimePickerField(
                      controller: fromTimeController,
                      onTimePicked: (pickedTime) {
                        fromTime = pickedTime;
                        fromTimeController.text = _formatTimeOfDay(pickedTime);
                      },
                    ),
                  ],
                )

            ),

            SizedBox(width: 16),
                Expanded(
                  child:
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                       Text(Strings.frome_date,
                    style:Theme.of(context).textTheme.bodyMedium ,
                       ),
                      _DatePickerField(
                        controller: fromDateController,
                        onDatePicked: (pickedDate) {
                          fromDate = pickedDate;
                          fromDateController.text = pickedDate.formatCompactDate();
                        },
                      ),
                    ],
                  )

                ),
          ],
        ),
        SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child:
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
              children: [

                Text(Strings.time,
                  style:Theme.of(context).textTheme.bodyMedium ,

                ),
                _TimePickerField(
                  controller: toTimeController,
                  onTimePicked: (pickedTime) {
                    toTime = pickedTime;
                    String time=_formatTimeOfDay(pickedTime);
                    toTimeController.text = _formatTimeOfDay(pickedTime);
                  },
                ),
              ],
              )

            ),
            SizedBox(width: 16),
            Expanded(
              child:
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(Strings.to_date,
        style:Theme.of(context).textTheme.bodyMedium ,

      ),
      _DatePickerField(
        controller: toDateController,
        onDatePicked: (pickedDate) {
          toDate = pickedDate;
          toDateController.text = pickedDate.formatCompactDate();
        },
      ),
    ],
    )

            ),
          ],
        ),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _DatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final Function(Jalali) onDatePicked;

  const _DatePickerField({
    required this.controller,
    required this.onDatePicked,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final pickedDate = await showPersianDatePicker(
          context: context,
          initialDate: Jalali.now(),
          firstDate: Jalali(1390, 1, 1),
          lastDate: Jalali(1450, 12, 29),
        );
        if (pickedDate != null) {
          onDatePicked(pickedDate);
        }
      },
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.date_range),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final TextEditingController controller;
  final Function(TimeOfDay) onTimePicked;

  const _TimePickerField({
    required this.controller,
    required this.onTimePicked,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(

      controller: controller,
      readOnly: true,
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          helpText: Strings.select_time,
          cancelText: Strings.cancel,
          confirmText: Strings.accept,
          initialEntryMode: TimePickerEntryMode.dialOnly,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            );
          },
        );
        if (time != null) {
          onTimePicked(time);
        }
      },
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.access_time),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
