import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get Firebase Auth instance
  FirebaseAuth get auth => _auth;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register user
  Future<UserCredential> registerUser({
    required String email,
    required String password,
    required String displayName,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    Map<String, dynamic>? otherDetails,
  }) async {
    try {
      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user!.updateDisplayName(displayName);

      // Create user document in Firestore
      final userModel = UserModel(
        id: userCredential.user!.uid,
        displayName: displayName,
        email: email,
        gender: gender,
        dateOfBirth: dateOfBirth,
        height: height,
        otherDetails: otherDetails,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      // Save user session locally
      await saveUserSession(userCredential.user!.uid);

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Login user
  Future<UserCredential> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Use workaround method to handle PigeonUserDetails errors
      final UserCredential userCredential = await _loginWithWorkaround(
        email,
        password,
      );
      
      // Verify the user credential is valid
      if (userCredential.user == null) {
        throw Exception('Login failed: No user returned from authentication');
      }
      
      // Save user session locally
      await saveUserSession(userCredential.user!.uid);
      
      return userCredential;
    } catch (e) {
      print('Auth service login error: $e');
      throw _handleAuthError(e);
    }
  }

  // Workaround for PigeonUserDetails error
  Future<UserCredential> _loginWithWorkaround(String email, String password) async {
    try {
      // First try normal login
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // If we get PigeonUserDetails error, try alternative approach
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('List<Object?>')) {
        print('PigeonUserDetails error detected, trying workaround...');
        
        // Try to get user by email first
        try {
          final methods = await _auth.fetchSignInMethodsForEmail(email);
          if (methods.isNotEmpty) {
            // User exists, try to sign in with a different approach
            await _auth.signOut(); // Clear any existing state
            
            // Wait a moment and try again
            await Future.delayed(const Duration(milliseconds: 500));
            
            return await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          }
        } catch (workaroundError) {
          print('Workaround failed: $workaroundError');
        }
      }
      
      // Re-throw the original error if workaround fails
      throw e;
    }
  }

  // Logout user
  Future<void> logoutUser() async {
    try {
      await _auth.signOut();
      await clearUserSession();
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, UserModel updatedUser) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(updatedUser.toMap());
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') != null;
  }

  // Get stored user ID
  Future<String?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Save user session locally
  Future<void> saveUserSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setBool('isLoggedIn', true);
  }

  // Clear user session locally
  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('isLoggedIn');
  }

  // Handle authentication errors
  String _handleAuthError(dynamic error) {
    print('Handling auth error: $error');
    
    // Handle PigeonUserDetails error specifically
    if (error.toString().contains('PigeonUserDetails')) {
      return 'Authentication service error. Please try again or restart the app.';
    }
    
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    
    // Handle other types of errors
    if (error is Exception) {
      return 'Authentication error: ${error.toString()}';
    }
    
    return 'An unexpected error occurred: $error';
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      await currentUser!.updatePassword(newPassword);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Test Firestore access (for debugging)
  Future<bool> testFirestoreAccess() async {
    try {
      // Try to access a test collection to verify Firestore is working
      await _firestore.collection('test').doc('test').get();
      return true;
    } catch (e) {
      print('Firestore access test failed: $e');
      return false;
    }
  }
}
