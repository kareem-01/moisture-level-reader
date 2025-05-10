import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soil_moisture_app/common/extensions/context_extension.dart';
import 'package:soil_moisture_app/constants/AppImages.dart';
import 'package:soil_moisture_app/models/moisture_reading.dart';
import 'package:soil_moisture_app/services/readings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Bluetooth state
  final FlutterBluePlus flutterBlue = FlutterBluePlus();
  List<ScanResult> _devicesList = [];
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;
  bool _isScanning = false;
  List<String> _measurements = [];
  final ReadingsService _readingsService = ReadingsService();
  bool _isConnectingToDevice = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _scanBluetoothDevices() async {
    setState(() {
      _isScanning = true;
    });

    if (await FlutterBluePlus.isSupported == false) {
      _showDialog(
        context,
        "Bluetooth Error",
        "Bluetooth is not available on this device",
      );
      setState(() {
        _isScanning = false;
      });
      return;
    }
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen(
      (results) {
        setState(() {
          _devicesList = results;
        });

        _logBluetoothDevices(results);
      },
      onDone: () {
        setState(() {
          _isScanning = false;
        });
      },
    );

    await Future.delayed(Duration(seconds: 4));
    FlutterBluePlus.stopScan();
    setState(() {
      _isScanning = false;
    });
  }

  void _showDialog(
    BuildContext context,
    String title,
    String message, {
    Function()? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E2A45),
          title: Text(title, style: TextStyle(color: Colors.white)),
          content: Text(message, style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              child: Text("OK", style: TextStyle(color: Color(0xFF51CF66))),
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) {
                  onConfirm();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _logBluetoothDevices(List<ScanResult> results) {
    print(
      "Found devices: ${results.map((result) => result.device.name).join(', ')}",
    );
  }

  // Method to connect to a device
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        _isConnectingToDevice = true;
      });

      // Connect to the device
      await device.connect();

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Look for a service with a characteristic for data
      for (BluetoothService service in services) {
        print('service');
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.notify ||
              characteristic.properties.read) {

            // If the characteristic supports notifications, subscribe to them
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              characteristic.lastValueStream.listen((value) {
                scheduleMicrotask(() {
                  try {
                    final decodedData = utf8.decode(value);

                    // Parse the list of measurements
                    List<String> newMeasurements = decodedData.split(',');

                    // Update UI on the main thread
                    setState(() {
                      _measurements = newMeasurements;
                    });

                    // Save each reading in the list
                    _saveReadings(newMeasurements);
                  } catch (e) {
                    setState(() {
                      _measurements = ["Error decoding: ${value.toString()}"];
                    });
                  }
                });
              });
            }

            // If the characteristic is readable, read the initial value
            if (characteristic.properties.read) {
              final value = await characteristic.read();
              // Use a microtask to avoid blocking the main thread
              scheduleMicrotask(() {
                try {
                  final decodedData = utf8.decode(value);

                  // Parse the list of measurements
                  List<String> newMeasurements = decodedData.split(',');

                  // Update UI on the main thread
                  setState(() {
                    _measurements = newMeasurements;
                  });

                  // Save each reading in the list
                  _saveReadings(newMeasurements);
                } catch (e) {
                  setState(() {
                    _measurements = ["Error decoding: ${value.toString()}"];
                  });
                }
              });
            }
          }
        }
      }

      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _isConnectingToDevice = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _isConnectingToDevice = false;
      });
    }
  }

  // Method to disconnect from a device
  void _disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } finally {
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _measurements = [];
      });
    }
  }

  // Save moisture reading to storage
  void _saveReadings(List<String> data) {
    // Avoid blocking the main thread for saving data
    scheduleMicrotask(() {
      try {
        // Process each measurement string in the list
        List<double> parsedValues = [];

        for (String measurement in data) {
          // Clean the data and check if it's valid
          String cleanData = measurement.trim();
          if (cleanData.isEmpty) {
            print('Empty measurement data, skipping');
            continue;
          }

          // Try to parse the measurement
          // First try to extract any numeric value from a string that might include labels
          RegExp regExp = RegExp(r'[+-]?\d+(\.\d+)?');
          Match? match = regExp.firstMatch(cleanData);

          double? moistureValue;
          if (match != null) {
            moistureValue = double.tryParse(match.group(0) ?? '');
          } else {
            // If no match, try to parse the whole string (after removing % if present)
            moistureValue = double.tryParse(cleanData.replaceAll('%', '').substring(3));
          }

          if (moistureValue == null) {
            print('Failed to parse measurement: $cleanData');
            continue;
          }

          parsedValues.add(moistureValue);
        }

        // Only save if we have at least one valid measurement
        if (parsedValues.isNotEmpty) {
          // Calculate average of all measurements
          double averageValue =
              parsedValues.reduce((a, b) => a + b) / parsedValues.length;

          final reading = MoistureReading(
            values: parsedValues,
            timestamp: DateTime.now(),
            average: averageValue,
          );

          // Save the reading
          _readingsService.saveReading(reading);
        }
      } catch (e) {
        print('Error saving reading: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Image.asset(
            AppImages.background,
            width: context.deviceWidth,
            height: context.deviceHeight,
            fit: BoxFit.fitHeight,
          ),
          Positioned(
            top: 24.h,
            right: 0,
            left: 0,
            child: Image.asset(
              AppImages.homeLogo,
              width: 160.w,
              height: 160.h,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 100.h),
                  Text(
                    'Soil Moisture Level:',
                    style: TextStyle(fontSize: 24.sp, color: Colors.white),
                  ),
                  SizedBox(height: 20.h),
                  if (!_isConnected)
                    Text(
                      "-%",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )
                  else
                    Container(
                      height: 150.h,
                      width: 300.w,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: _measurements.isEmpty
                          ? Center(child: Text("No measurements received"))
                          : ListView.builder(
                        itemCount: _measurements.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 5.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Sensor ${index + 1}:",
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _measurements[index],
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 20.h),
                  _isConnected
                      ? ElevatedButton(
                    onPressed: _disconnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                        horizontal: 30.w,
                        vertical: 10.h,
                      ),
                          ),
                    child: Text(
                      'Disconnect',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                      ),
                          ),
                  )
                      : ElevatedButton(
                    onPressed: _isScanning || _isConnectingToDevice
                        ? null
                        : () async {
                      _scanBluetoothDevices();
                      _showDevicesDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        horizontal: 30.w,
                        vertical: 10.h,
                      ),
                          ),
                    child: _isConnectingToDevice
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Connecting...',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Connect to Sensor',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.white,
                                  ),
                                ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog to show available devices
  void _showDevicesDialog(BuildContext context) {
    // Reset scanning state before showing dialog
    setState(() {
      _isScanning = false;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final devicesList = List<ScanResult>.from(_devicesList);

            return AlertDialog(
              title: Text('Select Bluetooth Device'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300.h,
                child:
                    _isScanning
                        ? const Center(child: CircularProgressIndicator())
                        : devicesList.isEmpty
                        ? const Center(child: Text('No devices found'))
                        : ListView.builder(
                          itemCount: devicesList.length,
                          itemBuilder: (context, index) {
                            final device = devicesList[index].device;
                            return ListTile(
                              title: Text(
                                device.platformName.isEmpty
                                    ? device.remoteId.toString()
                                    : device.platformName,
                              ),
                              subtitle: Text(device.remoteId.toString()),
                              onTap: () {
                                Navigator.pop(context);
                                _connectToDevice(device);
                              },
                            );
                          },
                        ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isScanning = true;
                    });
                    setDialogState(() {
                      _isScanning = true;
                    });
                    _scanBluetoothDevices().then((_) {
                      if (context.mounted) {
                        setDialogState(() {
                          _isScanning = false;
                        });
                      }
                    });
                  },
                  child: Text(_isScanning ? 'Scanning...' : 'Refresh'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
