import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssessmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _assessmentCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('assessments');
  }

  Future<void> saveAssessment(
      String assessmentId, Map<String, dynamic> data) async {
    await _assessmentCollection.doc(assessmentId).set(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getAssessment(
      String assessmentId) async {
    return await _assessmentCollection.doc(assessmentId).get();
  }

  Future<void> deleteAssessment(String assessmentId) async {
    await _assessmentCollection.doc(assessmentId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAssessmentsStream() {
    return _assessmentCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
