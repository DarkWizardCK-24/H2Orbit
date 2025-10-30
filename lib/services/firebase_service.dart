import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:h2orbit/models/user_model.dart';
import 'package:h2orbit/models/water_intake_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> saveUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Water intake operations
  Future<void> addWaterIntake(WaterIntakeModel intake) async {
    await _firestore.collection('water_intake').add(intake.toMap());
  }

  Future<void> deleteWaterIntake(String id) async {
    await _firestore.collection('water_intake').doc(id).delete();
  }

  Stream<List<WaterIntakeModel>> getTodayIntakeStream(String userId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _firestore
        .collection('water_intake')
        .where('userId', isEqualTo: userId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => WaterIntakeModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<List<WaterIntakeModel>> getIntakeByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _firestore
        .collection('water_intake')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => WaterIntakeModel.fromFirestore(doc))
        .toList();
  }

  // Analytics
  Future<Map<String, int>> getWeeklyStats(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartMidnight = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    final snapshot = await _firestore
        .collection('water_intake')
        .where('userId', isEqualTo: userId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartMidnight),
        )
        .get();

    final Map<String, int> weeklyData = {};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (var day in days) {
      weeklyData[day] = 0;
    }

    for (var doc in snapshot.docs) {
      final intake = WaterIntakeModel.fromFirestore(doc);
      final dayIndex = intake.timestamp.weekday - 1;
      weeklyData[days[dayIndex]] =
          (weeklyData[days[dayIndex]] ?? 0) + intake.milliliters;
    }

    return weeklyData;
  }

  Future<int> getMonthlyTotal(String userId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final snapshot = await _firestore
        .collection('water_intake')
        .where('userId', isEqualTo: userId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
        )
        .get();

    int total = 0;
    for (var doc in snapshot.docs) {
      final intake = WaterIntakeModel.fromFirestore(doc);
      total += intake.milliliters;
    }

    return total;
  }

  Future<int> getCurrentStreak(String userId) async {
    final now = DateTime.now();
    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    while (true) {
      final startOfDay = DateTime(
        checkDate.year,
        checkDate.month,
        checkDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('water_intake')
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        break;
      }

      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
