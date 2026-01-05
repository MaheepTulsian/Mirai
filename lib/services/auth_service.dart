import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Get FCM token
      final fcmToken = await _notificationService.getToken();

      // Create or update user document with basic info
      if (userCredential.user != null) {
        await _createOrUpdateUserDocument(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          displayName: userCredential.user!.displayName,
          photoURL: userCredential.user!.photoURL,
          fcmToken: fcmToken,
        );
      }

      return userCredential;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Create or update user document
  Future<void> _createOrUpdateUserDocument({
    required String uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? fcmToken,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      final docSnapshot = await userDoc.get();
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;

      if (docSnapshot.exists) {
        // Update existing user - preserve creation date, update login info
        await userDoc.update({
          'email': email,
          'displayName': displayName,
          'photoURL': photoURL,
          'fcmToken': fcmToken,
          'lastLoginAt': timestamp,
          'lastLoginDate': now.toIso8601String(),
          'updatedAt': timestamp,
        });
      } else {
        // Create new user with comprehensive initial data
        await userDoc.set({
          'email': email,
          'displayName': displayName,
          'photoURL': photoURL,
          'fcmToken': fcmToken,
          'createdAt': timestamp,
          'createdDate': now.toIso8601String(),
          'lastLoginAt': timestamp,
          'lastLoginDate': now.toIso8601String(),
          'updatedAt': timestamp,
          'isActive': true,
          'accountStatus': 'active',
        });
      }
    } catch (e) {
      throw Exception('Failed to create/update user document: $e');
    }
  }

  // Check if user profile exists in Firestore
  Future<bool> hasProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists && doc.data()?['profile'] != null;
    } catch (e) {
      return false;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['profile'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // Create user profile
  Future<void> createUserProfile({
    required String uid,
    required String graduatingYear,
    required String collegeName,
    required String collegeId,
    required String state,
    required String city,
  }) async {
    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;

      await _firestore.collection('users').doc(uid).set({
        'profile': {
          'graduatingYear': graduatingYear,
          'collegeName': collegeName,
          'collegeId': collegeId,
          'state': state,
          'city': city,
          'profileCompletedAt': timestamp,
          'profileCompletedDate': now.toIso8601String(),
        },
        'updatedAt': timestamp,
        'hasCompletedOnboarding': true,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Update FCM token
  Future<void> updateFCMToken(String uid) async {
    try {
      final fcmToken = await _notificationService.getToken();
      if (fcmToken != null) {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': fcmToken,
          'tokenUpdatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
