import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soil_moisture_app/common/extensions/context_extension.dart';
import 'package:soil_moisture_app/common/util/toast%20util.dart';
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
  double _average = 0.0;

  List<List<String>> _allMeasurements = [];

  Timer? _simulationTimer;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    // Future.delayed(Duration(seconds: 1), () {
    //   _startSimulation();
    // });
  }

  @override
  void dispose() {
    // Clean up timer when disposing
    _simulationTimer?.cancel();
    super.dispose();
  }

  // Method to start Bluetooth data simulation
  void _startSimulation() {
    if (_isSimulating) return;

    setState(() {
      _isSimulating = true;
      _isConnected = true;
      _connectedDevice = null;
      _measurements = ["0", "0", "0"]; // Initial values
    });

    // Create a timer that updates every 3 seconds
    _simulationTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!_isSimulating) {
        timer.cancel();
        return;
      }

      // Generate random moisture values (between 10 and 90)
      final random = DateTime.now().millisecondsSinceEpoch % 80 + 10;
      final random2 = (DateTime.now().millisecondsSinceEpoch ~/ 10) % 80 + 10;
      final random3 = (DateTime.now().millisecondsSinceEpoch ~/ 100) % 80 + 10;

      setState(() {
        _measurements = ["$random", "$random2", "$random3"];
        _allMeasurements.add(_measurements);
        _calculateAverage();
      });
    });
  }

  // Method to stop simulation
  void _stopSimulation() {
    _simulationTimer?.cancel();

    if (_isSimulating && _allMeasurements.isNotEmpty) {
      _saveAllReadings();
    }

    setState(() {
      _isSimulating = false;
      _isConnected = false;
      _connectedDevice = null;
      _measurements = [];
      _allMeasurements = [];
    });
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
                      _allMeasurements.add(
                        newMeasurements,
                      ); // Store the measurement
                      _calculateAverage(); // Calculate average for display only
                    });

                    // No longer save readings here - will save on disconnect
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
                    _allMeasurements.add(
                      newMeasurements,
                    ); // Store the measurement
                    _calculateAverage(); // Calculate average for display only
                  });

                  // No longer save readings here - will save on disconnect
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
    if (_isSimulating) {
      _stopSimulation();
      return;
    }

    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();

        // Now save all the collected measurements at disconnect
        if (_allMeasurements.isNotEmpty) {
          _saveAllReadings();
        }
      }
    } finally {
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _measurements = [];
        _allMeasurements = []; // Clear stored measurements
      });
    }
  }

  // Calculate and display average value (without saving)
  void _calculateAverage() {
    try {
      List<double> values = _parseValues(_measurements);
      if (values.isNotEmpty) {
        double sum = values.reduce((a, b) => a + b);
        double averageValue = sum / values.length;

        // Update the display average
        setState(() {
          _average = averageValue;
        });
      }
    } catch (e) {
      print('Error calculating average: $e');
      showErrorToast('Error calculating average: $e');
    }
  }

  void _saveAllReadings() {
    try {
      print('Saving all readings...');

      List<String> lastMeasurement = _measurements;
      List<double> parsedValues = _parseValues(lastMeasurement);

      if (parsedValues.isNotEmpty) {
        double averageValue =
            parsedValues.reduce((a, b) => a + b) / parsedValues.length;

        final reading = MoistureReading(
          values: parsedValues,
          timestamp: DateTime.now(),
          average: averageValue,
        );

        _readingsService.saveReading(reading);
      }
    } catch (e) {
      print('Error saving readings on disconnect: $e');
      showErrorToast('Error saving readings on disconnect: $e');
    }
  }

  // Helper method to parse values from string measurements
  List<double> _parseValues(List<String> data) {
    List<double> parsedValues = [];

    for (String measurement in data) {
      try {
        // The format is expected to be 'S1: 59.43%' or similar
        if (measurement.contains(':')) {
          // Split by colon and take the right part
          String valuePart = measurement.split(':')[1].trim();
          // Remove the % sign if present
          valuePart = valuePart.replaceAll('%', '');

          double? value = double.tryParse(valuePart);
          if (value != null) {
            parsedValues.add(value);
          } else {
            print('Failed to parse measurement: $measurement');
            showErrorToast('Failed to parse measurement: $measurement');
          }
        } else {
          // Try direct parsing if no colon is found
          double? value = double.tryParse(
              measurement.replaceAll('%', '').trim());
          if (value != null) {
            parsedValues.add(value);
          } else {
            print('Failed to parse measurement: $measurement');
            showErrorToast('Failed to parse measurement: $measurement');
          }
        }
      } catch (e) {
        print('Error parsing value: $measurement - $e');
        showErrorToast('Error parsing value: $measurement - $e');
      }
    }

    return parsedValues;
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
            child: Image.asset(AppImages.homeLogo, width: 160.w, height: 160.h),
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
                    Column(
                      children: [
                        // Circular gauge chart for average
                        Container(
                          width: 200.w,
                          height: 200.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Blue circular progress
                              SizedBox(
                                width: 180.w,
                                height: 180.h,
                                child: CircularProgressIndicator(
                                  value: _average / 100,
                                  // Assuming 100 is max value
                                  strokeWidth: 15.w,
                                  backgroundColor: Colors.grey.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF66D1FF), // Light blue
                                  ),
                                ),
                              ),
                              // Temperature markers
                              Positioned(
                                top: 15.h,
                                child: Text(
                                  "25°C",
                                  style: TextStyle(
                                      fontSize: 12.sp, color: Colors.grey),
                                ),
                              ),
                              Positioned(
                                left: 15.w,
                                child: Text(
                                  "50°C",
                                  style: TextStyle(
                                      fontSize: 12.sp, color: Colors.grey),
                                ),
                              ),
                              Positioned(
                                right: 15.w,
                                child: Text(
                                  "10°C",
                                  style: TextStyle(
                                      fontSize: 12.sp, color: Colors.grey),
                                ),
                              ),
                              // Center value
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${_average.toStringAsFixed(0)}%",
                                    style: TextStyle(
                                      fontSize: 36.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "Average",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                        // Measurement cards
                        if (_measurements.isNotEmpty)
                          SizedBox(
                            height: 120.h,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _measurements.length,
                              itemBuilder: (context, index) {
                                // Define different colors for the cards
                                List<Color> cardColors = [
                                  Color(0xFF6E5FF8), // Purple
                                  Color(0xFF1FBBB4), // Teal
                                  Color(0xFFFF5D7D), // Pink
                                ];

                                // Define icons for each sensor
                                List<IconData> sensorIcons = [
                                  Icons.water_drop,
                                  Icons.landscape,
                                  Icons.thermostat,
                                ];

                                return Container(
                                  width: 100.w,
                                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                                  decoration: BoxDecoration(
                                    color: cardColors[index %
                                        cardColors.length],
                                    borderRadius: BorderRadius.circular(15.r),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Switch toggle in top-right
                                      Positioned(
                                        top: 10.h,
                                        right: 10.w,
                                        child: Container(
                                          width: 20.w,
                                          height: 10.h,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                                5.r),
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Container(
                                              width: 10.w,
                                              height: 10.h,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Icon in top-left
                                      Positioned(
                                        top: 10.h,
                                        left: 10.w,
                                        child: Icon(
                                          sensorIcons[index %
                                              sensorIcons.length],
                                          color: Colors.white,
                                          size: 20.sp,
                                        ),
                                      ),
                                      // Content
                                      Padding(
                                        padding: EdgeInsets.all(10.w),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          mainAxisAlignment: MainAxisAlignment
                                              .end,
                                          children: [
                                            Text(
                                              _measurements[index],
                                              style: TextStyle(
                                                fontSize: 24.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              "Sensor ${index + 1}",
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.white.withOpacity(
                                                    0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
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
                          _isSimulating ? 'Stop Simulation' : 'Disconnect',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                      )
                      : ElevatedButton(
                        onPressed:
                            _isScanning || _isConnectingToDevice
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
                        child:
                            _isConnectingToDevice
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
