import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String? email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String preferredLanguage;
  final NotificationSettings notificationSettings;
  final SubscriptionStatus subscription;
  final bool isAnonymous;

  UserProfile({
    required this.userId,
    this.email,
    this.displayName,
    required this.createdAt,
    required this.lastLoginAt,
    this.preferredLanguage = 'zh-TW',
    required this.notificationSettings,
    required this.subscription,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'preferredLanguage': preferredLanguage,
      'notificationSettings': notificationSettings.toMap(),
      'subscription': subscription.toMap(),
      'isAnonymous': isAnonymous,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'],
      email: map['email'],
      displayName: map['displayName'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp).toDate(),
      preferredLanguage: map['preferredLanguage'] ?? 'zh-TW',
      notificationSettings:
          NotificationSettings.fromMap(map['notificationSettings'] ?? {}),
      subscription: SubscriptionStatus.fromMap(map['subscription'] ?? {}),
      isAnonymous: map['isAnonymous'] ?? false,
    );
  }
}

class NotificationSettings {
  final bool sleepDiaryReminder;
  final DateTime? reminderTime;
  final bool pushEnabled;

  NotificationSettings({
    this.sleepDiaryReminder = true,
    this.reminderTime,
    this.pushEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'sleepDiaryReminder': sleepDiaryReminder,
      'reminderTime':
          reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      'pushEnabled': pushEnabled,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      sleepDiaryReminder: map['sleepDiaryReminder'] ?? true,
      reminderTime: map['reminderTime'] != null
          ? (map['reminderTime'] as Timestamp).toDate()
          : null,
      pushEnabled: map['pushEnabled'] ?? true,
    );
  }
}

class SubscriptionStatus {
  final String status; // free/premium
  final DateTime? validUntil;
  final String? stripeCustomerId;

  SubscriptionStatus({
    this.status = 'free',
    this.validUntil,
    this.stripeCustomerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'stripeCustomerId': stripeCustomerId,
    };
  }

  factory SubscriptionStatus.fromMap(Map<String, dynamic> map) {
    return SubscriptionStatus(
      status: map['status'] ?? 'free',
      validUntil: map['validUntil'] != null
          ? (map['validUntil'] as Timestamp).toDate()
          : null,
      stripeCustomerId: map['stripeCustomerId'],
    );
  }
}
