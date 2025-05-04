import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:soil_moisture_app/models/moisture_reading.dart';
import 'package:soil_moisture_app/services/readings_service.dart';

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
      print('Error loading readings: $e');
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
              : ListView.builder(
                itemCount: _readings.length,
                itemBuilder: (context, index) {
                  final reading = _readings[index];
                  return Card(
                    margin: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.water_drop,
                        color: _getMoistureColor(reading.value),
                        size: 36.r,
                      ),
                      title: Text(
                        '${reading.value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat(
                          'MMM dd, yyyy - hh:mm a',
                        ).format(reading.timestamp),
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      trailing: _getMoistureStatus(reading.value),
                    ),
                  );
                },
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
        color: color.withValues(alpha: 0.2),
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
}
