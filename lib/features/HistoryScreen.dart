import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:soil_moisture_app/common/util/toast%20util.dart';
import 'package:soil_moisture_app/models/moisture_reading.dart';
import 'package:soil_moisture_app/services/readings_service.dart';
import 'package:velocity_x/velocity_x.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ReadingsService _readingsService = ReadingsService();
  List<MoistureReading> _readings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final readings = await _readingsService.getReadings();
      readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _readings = readings;
      });
    } catch (e) {
      showErrorToast('Failed to load readings. Please try again.');
      setState(() {
        _readings = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Moisture Reading History'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadReadings),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _showClearConfirmation,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _readings.isEmpty
              ? Center(
                child: Text(
                  'No readings recorded yet',
                  style: TextStyle(fontSize: 18.sp),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _readings.length,
                      itemBuilder: (context, index) {
                        final reading = _readings[index];
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.water_drop,
                                          color: _getMoistureColor(reading.average),
                                          size: 24.r,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          DateFormat(
                                            'MMM dd, yyyy - hh:mm a',
                                          ).format(reading.timestamp),
                                          style: TextStyle(fontSize: 14.sp),
                                        ),
                                      ],
                                    ),
                                    _getMoistureStatus(reading.average),
                                  ],
                                ),
                                Divider(height: 16.h),
                                Text(
                                  'Sensor readings:',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                ...reading.values.mapIndexed((entry, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 4.h),
                                    child: Text(
                                      'Sensor ${index + 1}: ${entry.toStringAsFixed(1)}%',
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                  );
                                }).toList(),
                                Divider(height: 16.h),
                                Row(
                                  children: [
                                    Text(
                                      'Average: ',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${reading.average.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: _getMoistureColor(reading.average),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.all(16.0),
                  //   child: Row(
                  //     children: [
                  //       Text(
                  //         'Overall Average: ',
                  //         style: TextStyle(
                  //           fontSize: 16.sp,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //       Text(
                  //         '${_calculateOverallAverage().toStringAsFixed(1)}%',
                  //         style: TextStyle(
                  //           fontSize: 16.sp,
                  //           fontWeight: FontWeight.bold,
                  //           color: _getMoistureColor(_calculateOverallAverage()),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
    );
  }

  Color _getMoistureColor(double value) {
    if (value < 30) {
      return Colors.red;
    } else if (value < 60) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Widget _getMoistureStatus(double value) {
    String status;
    Color color;

    if (value < 30) {
      status = 'Dry';
      color = Colors.red;
    } else if (value < 60) {
      status = 'Moist';
      color = Colors.orange;
    } else {
      status = 'Wet';
      color = Colors.green;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Clear History'),
            content: Text(
              'Are you sure you want to clear all reading history?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _readingsService.clearReadings();
                  _loadReadings();
                },
                child: Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  double _calculateOverallAverage() {
    if (_readings.isEmpty) {
      return 0;
    }

    double sum = 0;
    for (var reading in _readings) {
      sum += reading.average;
    }

    return sum / _readings.length;
  }
}