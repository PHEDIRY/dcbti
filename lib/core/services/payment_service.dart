import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _paymentCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');
    return _firestore.collection('users').doc(user.uid).collection('payments');
  }

  Future<void> savePayment(String paymentId, Map<String, dynamic> data) async {
    await _paymentCollection.doc(paymentId).set(data);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getPayment(
      String paymentId) async {
    return await _paymentCollection.doc(paymentId).get();
  }

  Future<void> deletePayment(String paymentId) async {
    await _paymentCollection.doc(paymentId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPaymentsStream() {
    return _paymentCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
