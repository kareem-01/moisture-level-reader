class MoistureReading {
  final double value;
  final DateTime timestamp;

  MoistureReading({
    required this.value,
    required this.timestamp,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Create from Map for retrieval
  factory MoistureReading.fromMap(Map<String, dynamic> map) {
    return MoistureReading(
      value: map['value'] is int
          ? (map['value'] as int).toDouble()
          : map['value'] as double,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}