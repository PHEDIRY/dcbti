import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _analyticsCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');
    return _firestore.collection('users').doc(user.uid).collection('analytics');
  }

  Future<void> logEvent(String eventId, Map<String, dynamic> data) async {
    await _analyticsCollection.doc(eventId).set(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getEvent(
      String eventId) async {
    return await _analyticsCollection.doc(eventId).get();
  }

  Future<void> deleteEvent(String eventId) async {
    await _analyticsCollection.doc(eventId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getEventsStream() {
    return _analyticsCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
