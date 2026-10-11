import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:h2orbit/utils/constants.dart';

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

  const UserModel({
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

  /// "Aarav Mehta" -> "Aarav". Falls back to a friendly word for empty names.
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  int get dailyGoalMl => dailyGlassTarget * AppConstants.mlPerGlass;

  UserModel copyWith({
    String? name,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    int? heightCm,
    int? weightKg,
    int? dailyGlassTarget,
  }) {
    final dob = dateOfBirth ?? this.dateOfBirth;
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      dateOfBirth: dob,
      age: dateOfBirth == null ? age : calculateAge(dob),
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      dailyGlassTarget: dailyGlassTarget ?? this.dailyGlassTarget,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const {};
    final dob =
        (data['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime(2000, 1, 1);
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      dateOfBirth: dob,
      age: data['age'] ?? calculateAge(dob),
      gender: data['gender'] ?? '',
      heightCm: data['heightCm'] ?? 170,
      weightKg: data['weightKg'] ?? 70,
      dailyGlassTarget:
          data['dailyGlassTarget'] ?? AppConstants.defaultWaterTarget,
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

  static int calculateAge(DateTime birthDate, {DateTime? now}) {
    final today = now ?? DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
