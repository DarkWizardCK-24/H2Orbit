import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final DateTime dateOfBirth;
  final int age;
  final String gender;
  final int heightCm;
  final int weightKg;
  final int dailyGlassTarget;
  
  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.dateOfBirth,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.dailyGlassTarget,
  });
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      heightCm: data['heightCm'] ?? 170,
      weightKg: data['weightKg'] ?? 70,
      dailyGlassTarget: data['dailyGlassTarget'] ?? 8,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'dailyGlassTarget': dailyGlassTarget,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
  
  static int calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}