import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soil_moisture_app/common/extensions/context_extension.dart';
import 'package:soil_moisture_app/constants/AppImages.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:soil_moisture_app/models/moisture_reading.dart';
import 'package:soil_moisture_app/services/readings_service.dart';
import 'dart:convert';
import 'dart:async';

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
  BluetoothCharacteristic? _dataCharacteristic;
  bool _isConnected = false;
  bool _isScanning = false;
  String _sensorData = "No data";
  late StreamSubscription<List<ScanResult>> _scanSubscription;
  final ReadingsService _readingsService = ReadingsService();

  @override
  void initState() {
    super.initState();
    // Setup Bluetooth scan results listener
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _devicesList = results;
        _isScanning = false;
      });
    });
  }

  @override
  void dispose() {
    _scanSubscription.cancel();
    super.dispose();
  }

  // Method to scan for Bluetooth devices
  void _startScan() async {
    setState(() {
      _isScanning = true;
      _devicesList = [];
    });

    try {
      // Check if Bluetooth is on
      if (await FlutterBluePlus.adapterState.first ==
          BluetoothAdapterState.off) {
        // Request to turn on Bluetooth
        FlutterBluePlus.turnOn();
        return;
      }

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // Method to connect to a device
  void _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        _isScanning = true;
      });

      // Connect to the device
      await device.connect();

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Look for a service with a characteristic for data
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service
            .characteristics) {
          if (characteristic.properties.notify ||
              characteristic.properties.read) {
            _dataCharacteristic = characteristic;

            // If the characteristic supports notifications, subscribe to them
            if (characteristic.properties.notify) {
              await characteristic.setNotifyValue(true);
              characteristic.lastValueStream.listen((value) {
                setState(() {
                  try {
                    _sensorData = utf8.decode(value);
                    // Save the reading when we get valid data
                    _saveReading(_sensorData);
                  } catch (e) {
                    _sensorData = "Error decoding: ${value.toString()}";
                  }
                });
              });
            }

            // If the characteristic is readable, read the initial value
            if (characteristic.properties.read) {
              final value = await characteristic.read();
              setState(() {
                try {
                  _sensorData = utf8.decode(value);
                  // Save the reading when we get valid data
                  _saveReading(_sensorData);
                } catch (e) {
                  _sensorData = "Error decoding: ${value.toString()}";
                }
              });
            }
          }
        }
      }

      setState(() {
        _connectedDevice = device;
        _isConnected = true;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _isScanning = false;
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
        _dataCharacteristic = null;
      });
    }
  }

  // Save moisture reading to storage
  void _saveReading(String data) {
    try {
      // Parse the moisture value from the sensor data
      final double moistureValue = double.parse(data.replaceAll('%', ''));

      // Create a reading object
      final reading = MoistureReading(
        value: moistureValue,
        timestamp: DateTime.now(),
      );

      // Save the reading
      _readingsService.saveReading(reading);
    } catch (e) {
      print('Error saving reading: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          AppImages.background,
          width: context.deviceWidth,
          height: context.deviceHeight,
          fit: BoxFit.fitHeight,
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Image.asset(
            AppImages.agrCultureEngineeringImage,
            width: 56.w,
            height: 56.h,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Image.asset(
            AppImages.facultyOfAgriculture,
            width: 56.w,
            height: 56.h,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            children: [
              SizedBox(height: 100.h),
              Text(
                'Soil Moisture Level:',
                style: TextStyle(fontSize: 24.sp, color: Colors.black),
              ),
              SizedBox(height: 20.h),
              Text(
                _isConnected ? _sensorData : "-%",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 10.h),
              _isConnected
                  ? ElevatedButton(
                onPressed: _disconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(
                      horizontal: 30.w, vertical: 10.h),
                ),
                child: Text(
                  'Disconnect',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
              )
                  : ElevatedButton(
                onPressed: _isScanning ? null : () =>
                    _showDevicesDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                      horizontal: 30.w, vertical: 10.h),
                ),
                child: Text(
                  'Connect to Sensor',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Dialog to show available devices
  void _showDevicesDialog(BuildContext context) {
    _startScan();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Bluetooth Device'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300.h,
                child: _isScanning
                    ? const Center(child: CircularProgressIndicator())
                    : _devicesList.isEmpty
                    ? const Center(child: Text('No devices found'))
                    : ListView.builder(
                  itemCount: _devicesList.length,
                  itemBuilder: (context, index) {
                    final device = _devicesList[index].device;
                    return ListTile(
                      title: Text(device.platformName.isEmpty
                          ? device.remoteId.toString()
                          : device.platformName),
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
                    _startScan();
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