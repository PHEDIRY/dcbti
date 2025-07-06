import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _notificationCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications');
  }

  Future<void> saveNotification(
      String notificationId, Map<String, dynamic> data) async {
    await _notificationCollection.doc(notificationId).set(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getNotification(
      String notificationId) async {
    return await _notificationCollection.doc(notificationId).get();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationCollection.doc(notificationId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream() {
    return _notificationCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
