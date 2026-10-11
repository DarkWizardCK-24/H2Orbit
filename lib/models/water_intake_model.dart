import 'package:cloud_firestore/cloud_firestore.dart';

class WaterIntakeModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final int milliliters;
  final String beverageType;

  /// Volume weighted by how hydrating the drink is (e.g. coffee counts less).
  final double hydrationValue;

  const WaterIntakeModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.milliliters,
    required this.beverageType,
    required this.hydrationValue,
  });

  WaterIntakeModel copyWith({String? id}) => WaterIntakeModel(
    id: id ?? this.id,
    userId: userId,
    timestamp: timestamp,
    milliliters: milliliters,
    beverageType: beverageType,
    hydrationValue: hydrationValue,
  );

  factory WaterIntakeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WaterIntakeModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      milliliters: (data['milliliters'] ?? 0) as int,
      beverageType: data['beverageType'] ?? 'water',
      hydrationValue: (data['hydrationValue'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'milliliters': milliliters,
      'beverageType': beverageType,
      'hydrationValue': hydrationValue,
    };
  }
}
