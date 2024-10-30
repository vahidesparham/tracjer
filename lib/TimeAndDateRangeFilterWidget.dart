import 'package:flutter/material.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                'فیلتر براساس بازه زمانی',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildDateTimeFields(context),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
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
                child: Text('تایید'),
              ),
              SizedBox(width: 20),
              OutlinedButton(
                onPressed: onCancel,
                child: Text('انصراف'),
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
              child: _TimePickerField(
                controller: fromTimeController,
                labelText: 'ساعت',
                onTimePicked: (pickedTime) {
                  fromTime = pickedTime;
                  fromTimeController.text = _formatTimeOfDay(pickedTime);
                },
              ),
            ),

            SizedBox(width: 16),
            Expanded(
              child: _DatePickerField(
                controller: fromDateController,
                labelText: 'از تاریخ',
                onDatePicked: (pickedDate) {
                  fromDate = pickedDate;
                  fromDateController.text = pickedDate.formatCompactDate();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _TimePickerField(
                controller: toTimeController,
                labelText: 'ساعت',
                onTimePicked: (pickedTime) {
                  toTime = pickedTime;
                  toTimeController.text = _formatTimeOfDay(pickedTime);
                },
              ),
            ),
            SizedBox(width: 16),

            Expanded(
              child: _DatePickerField(
                controller: toDateController,
                labelText: 'تا تاریخ',
                onDatePicked: (pickedDate) {
                  toDate = pickedDate;
                  toDateController.text = pickedDate.formatCompactDate();
                },
              ),
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
  final String labelText;
  final Function(Jalali) onDatePicked;

  const _DatePickerField({
    required this.controller,
    required this.labelText,
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
        labelText: labelText,
        prefixIcon: Icon(Icons.date_range),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final Function(TimeOfDay) onTimePicked;

  const _TimePickerField({
    required this.controller,
    required this.labelText,
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
        labelText: labelText,
        prefixIcon: Icon(Icons.access_time),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
