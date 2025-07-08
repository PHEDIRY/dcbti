import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        // Create a profile for the new anonymous user
        await _userService.createOrUpdateProfile(
          displayName: '匿名使用者',
        );
        print('[AuthService] Created profile for anonymous user: ${user.uid}');
      }

      return user;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmail(
      String email, String password, String displayName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName);

        // Create a profile for the new user
        await _userService.createOrUpdateProfile(
          displayName: displayName,
        );
        print('[AuthService] Created profile for new user: ${user.uid}');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Error signing up with email: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        // Update last login time
        await _userService.updateLastLoginTime();
        print('[AuthService] Updated last login time for user: ${user.uid}');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Error signing in with email: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
