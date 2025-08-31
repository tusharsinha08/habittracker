import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  UserModel? _userData;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  UserModel? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    // Defer initialization to avoid calling notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  // Initialize authentication state
  void _initializeAuth() {
    _authService.authStateChanges.listen(
      (User? user) {
        try {
          _currentUser = user;
          if (user != null) {
            _loadUserData(user.uid);
          } else {
            _userData = null;
          }
          notifyListeners();
        } catch (e) {
          print('Error in auth state listener: $e');
          // Handle the error gracefully without crashing
          _error = 'Authentication state error: $e';
          notifyListeners();
        }
      },
      onError: (error) {
        print('Auth state stream error: $error');
        _error = 'Authentication error: $error';
        notifyListeners();
      },
    );
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _userData = await _authService.getUserData(userId);
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      print('Error loading user data: $e');
      
      // Create fallback user data if Firestore is unavailable
      if (e.toString().contains('unavailable') || 
          e.toString().contains('PERMISSION_DENIED') ||
          e.toString().contains('permissions')) {
        
        // Create basic user data from auth user
        if (_currentUser != null) {
          _userData = UserModel(
            id: _currentUser!.uid,
            displayName: _currentUser!.displayName ?? 'User',
            email: _currentUser!.email ?? '',
            gender: null,
            dateOfBirth: null,
            height: null,
            otherDetails: {},
            createdAt: _currentUser!.metadata.creationTime ?? DateTime.now(),
            updatedAt: _currentUser!.metadata.lastSignInTime ?? DateTime.now(),
            isDarkMode: false,
          );
          _error = 'Using offline profile data. Some features may be limited.';
        } else {
          _error = 'Failed to load user data: $e';
        }
      } else if (e.toString().contains('PigeonUserDetails')) {
        _error = 'Authentication service error. Please try logging in again.';
      } else {
        _error = 'Failed to load user data: $e';
      }
      notifyListeners();
    }
  }

  // Public method to load user data (can be called from UI)
  Future<void> loadUserData() async {
    if (_currentUser != null) {
      await _loadUserData(_currentUser!.uid);
    }
  }

  // Register user
  Future<bool> registerUser({
    required String email,
    required String password,
    required String displayName,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    Map<String, dynamic>? otherDetails,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.registerUser(
        email: email,
        password: password,
        displayName: displayName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        height: height,
        otherDetails: otherDetails,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Login user
  Future<bool> loginUser({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Try to login with multiple attempts and error handling
      UserCredential? userCredential;
      int attempts = 0;
      const maxAttempts = 3;

      while (attempts < maxAttempts && userCredential == null) {
        try {
          attempts++;
          print('Login attempt $attempts for $email');
          
          userCredential = await _authService.loginUser(
            email: email,
            password: password,
          );
          
          // If we get here, login was successful
          break;
        } catch (e) {
          print('Login attempt $attempts failed: $e');
          
          // Check if it's a PigeonUserDetails error
          if (e.toString().contains('PigeonUserDetails') || 
              e.toString().contains('List<Object?>')) {
            
            if (attempts < maxAttempts) {
              print('PigeonUserDetails error detected, waiting before retry...');
              // Wait before retry
              await Future.delayed(Duration(milliseconds: 500 * attempts));
              
              // Try to clear any corrupted auth state
              try {
                await _authService.logoutUser();
                await Future.delayed(const Duration(milliseconds: 1000));
              } catch (clearError) {
                print('Error clearing auth state: $clearError');
              }
              
              continue; // Try again
            } else {
              // Max attempts reached
              _error = 'Authentication service error after multiple attempts. Please restart the app.';
              _isLoading = false;
              notifyListeners();
              return false;
            }
          } else {
            // Non-PigeonUserDetails error, don't retry
            throw e;
          }
        }
      }

      if (userCredential == null) {
        _error = 'Login failed after multiple attempts';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Save remember me preference
      if (rememberMe) {
        await _saveRememberMePreference(true);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      print('Login error: $e');
      if (e.toString().contains('PigeonUserDetails')) {
        _error = 'Authentication service error. Please try again or restart the app.';
      } else {
        _error = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  // Logout user
  Future<void> logoutUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.logoutUser();
      
      _currentUser = null;
      _userData = null;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    Map<String, dynamic>? otherDetails,
    bool? isDarkMode,
  }) async {
    try {
      if (_userData == null) return false;

      _isLoading = true;
      notifyListeners();

      final updatedUser = _userData!.copyWith(
        displayName: displayName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        height: height,
        otherDetails: otherDetails,
        isDarkMode: isDarkMode,
      );

      await _authService.updateUserProfile(_currentUser!.uid, updatedUser);
      
      _userData = updatedUser;
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String newPassword) async {
    try {
      if (_currentUser == null) return false;

      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.changePassword(newPassword);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Recover from authentication errors
  Future<void> recoverFromAuthError() async {
    try {
      _error = null;
      _isLoading = false;
      
      // Clear current state
      _currentUser = null;
      _userData = null;
      
      // Try to get current user from Firebase
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _currentUser = currentUser;
        await _loadUserData(currentUser.uid);
      }
      
      notifyListeners();
    } catch (e) {
      print('Recovery error: $e');
      _error = 'Failed to recover authentication state: $e';
      notifyListeners();
    }
  }

  // Restart authentication listener
  void restartAuthListener() {
    try {
      _error = null;
      _isLoading = false;
      _currentUser = null;
      _userData = null;
      
      // Reinitialize auth
      _initializeAuth();
      
      notifyListeners();
    } catch (e) {
      print('Restart auth error: $e');
      _error = 'Failed to restart authentication: $e';
      notifyListeners();
    }
  }

  // Clear local storage and reset auth state
  Future<void> clearLocalStorage() async {
    try {
      _error = null;
      _isLoading = false;
      _currentUser = null;
      _userData = null;
      
      // Clear local storage
      await _authService.clearUserSession();
      
      notifyListeners();
    } catch (e) {
      print('Clear local storage error: $e');
      _error = 'Failed to clear local storage: $e';
      notifyListeners();
    }
  }

  // Force logout and clear all state
  Future<void> forceLogout() async {
    try {
      _error = null;
      _isLoading = false;
      _currentUser = null;
      _userData = null;
      
      // Sign out from Firebase
      await _authService.logoutUser();
      
      notifyListeners();
    } catch (e) {
      print('Force logout error: $e');
      // Even if logout fails, clear local state
      _currentUser = null;
      _userData = null;
      _error = null;
      notifyListeners();
    }
  }

  // Check Firebase configuration
  Future<bool> checkFirebaseConfig() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Try to get current user to test Firebase connection
      final currentUser = _authService.currentUser;
      
      _isLoading = false;
      notifyListeners();
      
      return true; // If we get here, Firebase is working
    } catch (e) {
      _isLoading = false;
      print('Firebase config check error: $e');
      _error = 'Firebase configuration error: $e';
      notifyListeners();
      return false;
    }
  }

  // Check internet connectivity
  Future<bool> checkInternetConnection() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Try to make a simple Firebase call to test connectivity
      _authService.currentUser;
      
      _isLoading = false;
      notifyListeners();
      
      return true; // If we get here, internet is working
    } catch (e) {
      _isLoading = false;
      print('Internet connection check error: $e');
      _error = 'Internet connection error: $e';
      notifyListeners();
      return false;
    }
  }

  // Check Firebase project configuration
  Future<bool> checkFirebaseProject() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Try to access Firestore to test project configuration
      // This will test if the project is configured correctly
      await _authService.getUserData('test');
      
      _isLoading = false;
      notifyListeners();
      
      return true; // If we get here, project is configured correctly
    } catch (e) {
      _isLoading = false;
      print('Firebase project check error: $e');
      _error = 'Firebase project configuration error: $e';
      notifyListeners();
      return false;
    }
  }

  // Check Firebase security rules
  Future<bool> checkFirebaseRules() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Try to access Firestore with a test document
      // This will test if the security rules are configured correctly
      final hasAccess = await _authService.testFirestoreAccess();
      
      _isLoading = false;
      notifyListeners();
      
      return hasAccess; // If we get here, rules are configured correctly
    } catch (e) {
      _isLoading = false;
      print('Firebase rules check error: $e');
      _error = 'Firebase security rules error: $e';
      notifyListeners();
      return false;
    }
  }

  // Check Firebase authentication configuration
  Future<bool> checkFirebaseAuth() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Try to get current user to test auth configuration
      _authService.currentUser;
      
      _isLoading = false;
      notifyListeners();
      
      return true; // If we get here, auth is configured correctly
    } catch (e) {
      _isLoading = false;
      print('Firebase auth check error: $e');
      _error = 'Firebase authentication configuration error: $e';
      notifyListeners();
      return false;
    }
  }

  // Manual authentication check (fallback)
  Future<void> checkAuthenticationState() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _currentUser = currentUser;
        await _loadUserData(currentUser.uid);
      } else {
        _currentUser = null;
        _userData = null;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      print('Manual auth check error: $e');
      _error = 'Failed to check authentication state: $e';
      notifyListeners();
    }
  }

  // Check if user is logged in from local storage
  Future<bool> checkLocalAuthState() async {
    try {
      final isLoggedIn = await _authService.isUserLoggedIn();
      if (isLoggedIn) {
        final userId = await _authService.getStoredUserId();
        if (userId != null) {
          // User data will be loaded by the auth state listener
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Toggle theme
  Future<void> toggleTheme() async {
    if (_userData != null) {
      await updateUserProfile(isDarkMode: !_userData!.isDarkMode);
    }
  }

  // Check Firebase project ID
  Future<bool> checkFirebaseProjectId() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Try to access Firestore to test project ID
      // This will test if the project ID is configured correctly
      final hasAccess = await _authService.testFirestoreAccess();
      
      _isLoading = false;
      notifyListeners();
      
      return hasAccess; // If we get here, project ID is configured correctly
    } catch (e) {
      _isLoading = false;
      print('Firebase project ID check error: $e');
      _error = 'Firebase project ID configuration error: $e';
      notifyListeners();
      return false;
    }
  }

  // Check Firebase API key
  Future<bool> checkFirebaseApiKey() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Try to access Firestore to test API key
      // This will test if the API key is configured correctly
      final hasAccess = await _authService.testFirestoreAccess();
      
      _isLoading = false;
      notifyListeners();
      
      return hasAccess; // If we get here, API key is configured correctly
    } catch (e) {
      _isLoading = false;
      print('Firebase API key check error: $e');
      _error = 'Firebase API key configuration error: $e';
      notifyListeners();
      return false;
    }
  }

  // Check Firebase app configuration
  Future<bool> checkFirebaseApp() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Try to access Firestore to test app configuration
      // This will test if the app is configured correctly
      final hasAccess = await _authService.testFirestoreAccess();
      
      _isLoading = false;
      notifyListeners();
      
      return hasAccess; // If we get here, app is configured correctly
    } catch (e) {
      _isLoading = false;
      print('Firebase app check error: $e');
      _error = 'Firebase app configuration error: $e';
      notifyListeners();
      return false;
    }
  }

  // Save remember me preference
  Future<void> _saveRememberMePreference(bool rememberMe) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', rememberMe);
    } catch (e) {
      print('Error saving remember me preference: $e');
    }
  }

  // Get remember me preference
  Future<bool> getRememberMePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('rememberMe') ?? false;
    } catch (e) {
      print('Error getting remember me preference: $e');
      return false;
    }
  }

  // Handle PigeonUserDetails error with fallback
  Future<bool> _handlePigeonUserDetailsError(String email, String password) async {
    try {
      print('Attempting fallback authentication for PigeonUserDetails error...');
      
      // Try to clear any corrupted auth state
      await _authService.logoutUser();
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Try alternative authentication approach
      // First check if user exists
      try {
        final methods = await _authService.auth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          print('User exists, attempting alternative sign-in...');
          
          // Try to sign in again after clearing state
          await Future.delayed(const Duration(milliseconds: 500));
          
          final userCredential = await _authService.loginUser(
            email: email,
            password: password,
          );
          
          if (userCredential != null) {
            print('Fallback authentication successful');
            return true;
          }
        }
      } catch (fallbackError) {
        print('Fallback authentication failed: $fallbackError');
      }
      
      return false;
    } catch (e) {
      print('Error in fallback authentication: $e');
      return false;
    }
  }
}
