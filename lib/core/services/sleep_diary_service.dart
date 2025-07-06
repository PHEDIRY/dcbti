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
}
