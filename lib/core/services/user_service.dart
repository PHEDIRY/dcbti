import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get reference to the user's profile document
  DocumentReference<Map<String, dynamic>> get _userProfileRef => _firestore
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('profile')
      .doc('info');

  // Create or update user profile
  Future<void> createOrUpdateProfile({String? displayName}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final now = DateTime.now();
    final profile = UserProfile(
      userId: user.uid,
      email: user.email ?? '',
      displayName: displayName ?? user.displayName,
      createdAt: now,
      lastLoginAt: now,
      notificationSettings: NotificationSettings(),
      subscription: SubscriptionStatus(),
      isAnonymous: user.isAnonymous,
    );

    try {
      await _userProfileRef.set(profile.toMap(), SetOptions(merge: true));
      print('[UserService] Profile created/updated for user: ${user.uid}');
    } catch (e) {
      print('[UserService] Error creating/updating profile: $e');
      rethrow;
    }
  }

  // Get user profile
  Stream<UserProfile?> getProfile() {
    return _userProfileRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserProfile.fromMap(snapshot.data()!);
    });
  }

  // Update notification settings
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      await _userProfileRef.update({'notificationSettings': settings.toMap()});
      print('[UserService] Notification settings updated');
    } catch (e) {
      print('[UserService] Error updating notification settings: $e');
      rethrow;
    }
  }

  // Update subscription status
  Future<void> updateSubscription(SubscriptionStatus subscription) async {
    try {
      await _userProfileRef.update({'subscription': subscription.toMap()});
      print('[UserService] Subscription status updated');
    } catch (e) {
      print('[UserService] Error updating subscription: $e');
      rethrow;
    }
  }

  // Update last login time
  Future<void> updateLastLoginTime() async {
    try {
      await _userProfileRef.update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
      print('[UserService] Last login time updated');
    } catch (e) {
      print('[UserService] Error updating last login time: $e');
      rethrow;
    }
  }

  // Update preferred language
  Future<void> updatePreferredLanguage(String language) async {
    try {
      await _userProfileRef.update({'preferredLanguage': language});
      print('[UserService] Preferred language updated to: $language');
    } catch (e) {
      print('[UserService] Error updating preferred language: $e');
      rethrow;
    }
  }
}
