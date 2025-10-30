import 'package:cloud_firestore/cloud_firestore.dart';

class WaterIntakeModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final int milliliters;
  final String beverageType;
  final double hydrationValue;

  WaterIntakeModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.milliliters,
    required this.beverageType,
    required this.hydrationValue,
  });

  factory WaterIntakeModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return WaterIntakeModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      milliliters: data['milliliters'] ?? 0,
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
