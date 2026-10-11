import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:h2orbit/models/user_model.dart';
import 'package:h2orbit/models/water_intake_model.dart';

/// Lifetime totals for a user.
class IntakeTotals {
  final int count;
  final int milliliters;

  const IntakeTotals({required this.count, required this.milliliters});

  static const IntakeTotals zero = IntakeTotals(count: 0, milliliters: 0);
}

/// Storage contract for users and their drinks. The screens only know this
/// interface, so they can run against an in-memory fake in tests.
abstract class HydrationRepository {
  Future<UserModel?> getUser(String uid);

  /// Creates or updates the profile (existing fields are merged).
  Future<void> saveUser(UserModel user);

  /// Saves [intake] and returns it with its generated id.
  Future<WaterIntakeModel> addIntake(WaterIntakeModel intake);

  Future<void> deleteIntake(String id);

  /// Drinks logged on the calendar day of [day], oldest first, live.
  Stream<List<WaterIntakeModel>> watchDay(String userId, DateTime day);

  /// Drinks between [start] (inclusive) and [end] (exclusive), oldest first.
  Future<List<WaterIntakeModel>> getIntakeBetween(
    String userId,
    DateTime start,
    DateTime end,
  );

  Future<IntakeTotals> getTotals(String userId);

  /// Removes the profile and every drink of [userId].
  Future<void> deleteAllUserData(String userId);
}

class FirestoreHydrationRepository implements HydrationRepository {
  FirestoreHydrationRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _intake =>
      _db.collection('water_intake');

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  @override
  Future<void> saveUser(UserModel user) =>
      _users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));

  /// Firestore completes a write only once the server confirms it, which never
  /// happens while offline. The write is queued locally either way (and shows
  /// up in [watchDay] straight away), so don't make the UI wait for the server.
  static const Duration _serverWait = Duration(seconds: 3);

  @override
  Future<WaterIntakeModel> addIntake(WaterIntakeModel intake) async {
    final ref = intake.id.isEmpty ? _intake.doc() : _intake.doc(intake.id);
    await ref.set(intake.toMap()).timeout(_serverWait, onTimeout: () {});
    return intake.copyWith(id: ref.id);
  }

  @override
  Future<void> deleteIntake(String id) =>
      _intake.doc(id).delete().timeout(_serverWait, onTimeout: () {});

  // These queries match the composite index "userId (asc) + timestamp (asc)".
  Query<Map<String, dynamic>> _range(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return _intake
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp');
  }

  @override
  Stream<List<WaterIntakeModel>> watchDay(String userId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    return _range(userId, start, end).snapshots().map(
      (snap) => snap.docs.map(WaterIntakeModel.fromFirestore).toList(),
    );
  }

  @override
  Future<List<WaterIntakeModel>> getIntakeBetween(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final snap = await _range(userId, start, end).get();
    return snap.docs.map(WaterIntakeModel.fromFirestore).toList();
  }

  @override
  Future<IntakeTotals> getTotals(String userId) async {
    final snap = await _intake
        .where('userId', isEqualTo: userId)
        .aggregate(count(), sum('milliliters'))
        .get();
    return IntakeTotals(
      count: snap.count ?? 0,
      milliliters: (snap.getSum('milliliters') ?? 0).round(),
    );
  }

  @override
  Future<void> deleteAllUserData(String userId) async {
    // Batches are limited to 500 writes, so delete in pages.
    while (true) {
      final page = await _intake
          .where('userId', isEqualTo: userId)
          .limit(400)
          .get();
      if (page.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _users.doc(userId).delete();
  }
}
