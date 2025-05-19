class MoistureReading {
  final List<double> values;
  final DateTime timestamp;
  final double average;

  MoistureReading({
    required this.values,
    required this.timestamp,
    required this.average,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'values': values,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'average': average,
    };
  }

  // Create from Map for retrieval
  factory MoistureReading.fromMap(Map<String, dynamic> map) {
    return MoistureReading(
      values: (map['values'] as List).map((e) => e is int ? e.toDouble() : e as double).toList(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      average: map['average'] is int
          ? (map['average'] as int).toDouble()
          : map['average'] as double,
    );
  }
}