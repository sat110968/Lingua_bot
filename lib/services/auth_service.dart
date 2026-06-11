import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Authentication service handling Supabase Auth operations
class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize auth service and restore session if available
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _isAuthenticated = true;
        await _fetchUserProfile(session.user.id);
      }
    } catch (e) {
      debugPrint('❌ Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate inputs
      _validateEmail(email);
      _validatePassword(password);
      if (displayName.trim().isEmpty) {
        throw ValidationException.emptyField('Display Name');
      }

      // Sign up
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw AuthenticationException(
          message: 'Failed to create account. Please try again.',
          code: 'SIGNUP_FAILED',
        );
      }

      // Create user profile
      await _createUserProfile(
        userId: response.user!.id,
        email: email.trim(),
        displayName: displayName.trim(),
      );

      _isAuthenticated = true;
      await _fetchUserProfile(response.user!.id);

      debugPrint('✅ Account created successfully');
    } on LinguaBotException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthenticationException(
        message: _mapAuthError(e.message),
        code: 'SIGNUP_ERROR',
        originalException: e,
      );
    } catch (e) {
      throw UnknownException(
        message: 'Failed to sign up',
        originalException: e is Exception ? e : null,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _validateEmail(email);
      _validatePassword(password);

      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw AuthenticationException.invalidCredentials();
      }

      _isAuthenticated = true;
      await _fetchUserProfile(response.user!.id);

      // Store tokens securely
      if (response.session != null) {
        await _secureStorage.write(
          key: _tokenKey,
          value: response.session!.accessToken,
        );
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: response.session!.refreshToken ?? '',
        );
      }

      debugPrint('✅ Signed in successfully');
    } on LinguaBotException {
      rethrow;
    } on AuthException catch (e) {
      _error = _mapAuthError(e.message);
      throw AuthenticationException(
        message: _error!,
        code: 'SIGNIN_ERROR',
        originalException: e,
      );
    } catch (e) {
      _error = 'Sign in failed';
      throw UnknownException(
        message: _error!,
        originalException: e is Exception ? e : null,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signOut();
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);

      _currentUser = null;
      _isAuthenticated = false;
      _error = null;

      debugPrint('✅ Signed out successfully');
    } catch (e) {
      _error = 'Failed to sign out';
      throw UnknownException(
        message: _error!,
        originalException: e is Exception ? e : null,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request password reset email
  Future<void> resetPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _validateEmail(email);

      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'com.linguabot://reset-password',
      );

      debugPrint('✅ Password reset email sent');
    } on LinguaBotException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthenticationException(
        message: 'Failed to send reset email',
        code: 'RESET_PASSWORD_ERROR',
        originalException: e,
      );
    } catch (e) {
      throw UnknownException(
        message: 'Password reset failed',
        originalException: e is Exception ? e : null,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user email
  Future<void> updateEmail({required String newEmail}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _validateEmail(newEmail);

      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail.trim()),
      );

      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(email: newEmail.trim());
      }

      debugPrint('✅ Email updated successfully');
    } on LinguaBotException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthenticationException(
        message: 'Failed to update email',
        code: 'UPDATE_EMAIL_ERROR',
        originalException: e,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user password
  Future<void> updatePassword({required String newPassword}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _validatePassword(newPassword);

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      debugPrint('✅ Password updated successfully');
    } on LinguaBotException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthenticationException(
        message: 'Failed to update password',
        code: 'UPDATE_PASSWORD_ERROR',
        originalException: e,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      _validateEmail(email);

      final response = await _supabase
          .from('users')
          .select('id')
          .eq('email', email.trim())
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking email: $e');
      return false;
    }
  }

  /// Private helper to fetch user profile
  Future<void> _fetchUserProfile(String userId) async {
    try {
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = UserModel.fromJson(userData);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      // Profile might not exist yet
    }
  }

  /// Private helper to create user profile in custom users table
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    try {
      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'display_name': displayName,
        'created_at': DateTime.now().toIso8601String(),
      });

      _currentUser = UserModel(
        id: userId,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      // Non-critical if profile creation fails
    }
  }

  /// Validate email format
  void _validateEmail(String email) {
    if (email.trim().isEmpty) {
      throw ValidationException.emptyField('Email');
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email.trim())) {
      throw ValidationException.invalidEmail();
    }
  }

  /// Validate password strength
  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw ValidationException.emptyField('Password');
    }

    if (password.length < 6) {
      throw ValidationException(
        message: 'Password must be at least 6 characters long.',
        code: 'WEAK_PASSWORD',
      );
    }
  }

  /// Map Supabase auth errors to user-friendly messages
  String _mapAuthError(String authError) {
    if (authError.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (authError.contains('Email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (authError.contains('already registered')) {
      return 'This email is already registered.';
    }
    if (authError.contains('weak')) {
      return 'Password is too weak. Please use a stronger password.';
    }
    return authError;
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
