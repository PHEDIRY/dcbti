import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sleep_diary_entry.dart';

class SleepDiaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save a sleep diary entry for the current user
  Future<void> saveEntry(SleepDiaryEntry entry) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');
    final ref = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sleep_diary')
        .doc(entry.id);
    await ref.set(entry.toMap());
  }

  /// Get all sleep diary entries for the current user
  Future<List<SleepDiaryEntry>> getEntries() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sleep_diary')
        .orderBy('entryDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => SleepDiaryEntry.fromMap(doc.data()))
        .toList();
  }

  /// Get a specific sleep diary entry by ID
  Future<SleepDiaryEntry?> getEntryById(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sleep_diary')
        .doc(id)
        .get();

    if (doc.exists) {
      return SleepDiaryEntry.fromMap(doc.data()!);
    }

    return null;
  }

  /// Delete a sleep diary entry
  Future<void> deleteEntry(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sleep_diary')
        .doc(id)
        .delete();
  }
}
