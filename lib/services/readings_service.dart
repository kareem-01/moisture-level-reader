import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soil_moisture_app/models/moisture_reading.dart';

class ReadingsService {
  static const String _storageKey = 'moisture_readings';

  // Save a new reading
  Future<void> saveReading(MoistureReading reading) async {
    final prefs = await SharedPreferences.getInstance();

    // Get current readings
    List<MoistureReading> readings = await getReadings();
    readings.add(reading);

    // Limit to the last 100 readings if needed
    if (readings.length > 100) {
      readings = readings.sublist(readings.length - 100);
    }

    // Convert to list of maps and save
    List<Map<String, dynamic>> maps = readings.map((r) => r.toMap()).toList();
    String json = jsonEncode(maps);
    await prefs.setString(_storageKey, json);
  }

  // Get all readings
  Future<List<MoistureReading>> getReadings() async {
    final prefs = await SharedPreferences.getInstance();
    String? json = prefs.getString(_storageKey);

    if (json == null || json.isEmpty) {
      return [];
    }

    List<dynamic> list = jsonDecode(json);
    return list
        .map((map) => MoistureReading.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  // Clear all readings
  Future<void> clearReadings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}