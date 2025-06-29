import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import 'package:flutter/foundation.dart';

/// Controller for handling authentication flows with Supabase.
class AuthDataController {
  late final SupabaseClient _client;
  
  // Developer toggle for 2FA - set to false to disable 2FA
  static const bool _enable2FA = false;
  
  // Supabase credentials - replace with your actual values
  static const String _supabaseUrl = 'https://uhrpoudutcmfwwwjcrid.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVocnBvdWR1dGNtZnd3d2pjcmlkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3ODY2NjIsImV4cCI6MjA2NjM2MjY2Mn0.eD0GzV2jihhCWbzqTkKDS18ieZhJTisqreGuFFaXyZM';
  
  // Store temporary user data after email/password login for 2FA
  AppUser? _tempUser;
  
  // Track login state
  final ValueNotifier<bool> userLoggedInNotifier = ValueNotifier(false);
  
  // Private constructor
  AuthDataController._();
  
  // Factory constructor for async initialization
  static Future<AuthDataController> create() async {
    final controller = AuthDataController._();
    await controller._initializeSupabase();
    await controller.checkPersistentLogin();
    return controller;
  }
  
  /// Initialize Supabase client with credentials
  Future<void> _initializeSupabase() async {
    // Initialize Supabase with our credentials
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    // Listen for auth state changes to keep login state in sync
    _client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      userLoggedInNotifier.value = session != null;
    });
  }
  
  AppUser? get tempUser => _tempUser;
  
  /// Check if user is currently logged in
  bool isUserLoggedIn() {
    return userLoggedInNotifier.value;
  }
  
  /// Sign up with email and password, then create a user profile in 'users' table.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? profilePictureUrl,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final authUser = response.user;
    if (authUser == null) {
      throw AuthException('Sign up failed');
    }
    // Insert into user profile table
    final profileData = {
      'id': authUser.id,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePictureUrl': profilePictureUrl,
    };
    await _client.from('users').insert(profileData);
    
    // If 2FA is enabled, don't set user as logged in yet
    if (_enable2FA) {
      _tempUser = AppUser.fromJson(profileData);
      // Send email OTP for 2FA
      await sendEmailOtp(email: email);
    } else {
      userLoggedInNotifier.value = true;
    }
    
    return AppUser.fromJson(profileData);
  }

  /// Login with email and password (first step of 2FA flow)
  Future<AppUser> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final authUser = response.user;
    if (authUser == null) {
      throw AuthException('Login failed');
    }
    
    // Fetch user profile
    final profileRes = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .single();
    
    final user = AppUser.fromJson(profileRes);
    
    // If 2FA is enabled, store temp user and don't set as logged in yet
    if (_enable2FA) {
      _tempUser = user;
      // Send email OTP for 2FA
      await sendEmailOtp(email: user.email);
    } else {
      userLoggedInNotifier.value = true;
    }
    
    return user;
  }

  /// Send OTP to phone number for sign-in or verification.
  Future<void> sendOtp({required String phone}) async {
    await _client.auth.signInWithOtp(
      phone: phone,
    );
  }

  /// Send email OTP for 2FA
  Future<void> sendEmailOtp({required String email}) async {
    await _client.auth.signInWithOtp(
      email: email,
    );
  }

  /// Verify OTP and complete phone sign-in, then fetch user profile.
  Future<AppUser> verifyOtp({
    required String phone,
    required String token,
  }) async {
    final res = await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    final authUser = res.user;
    if (authUser == null) {
      throw AuthException('OTP verification failed');
    }
    // Fetch profile
    final profileRes = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .single();
    userLoggedInNotifier.value = true;
    return AppUser.fromJson(profileRes);
  }

  /// Verify email OTP for 2FA (second step of 2FA flow)
  Future<void> verify2FAOtp({
    required String email,
    required String token,
  }) async {
    if (!_enable2FA) {
      throw AuthException('2FA is disabled');
    }
    
    if (_tempUser == null) {
      throw AuthException('No pending login session found');
    }
    
    final res = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
    
    if (res.user == null) {
      throw AuthException('OTP verification failed');
    }
    
    // OTP verified successfully, set user as logged in
    userLoggedInNotifier.value = true;
    _tempUser = null; // Clear temp user data
  }

  /// Complete login flow after OTP: alias for verifyOtp
  Future<AppUser> loginWithPhoneOtp({
    required String phone,
    required String token,
  }) async {
    return verifyOtp(phone: phone, token: token);
  }

  /// Send password reset email
  Future<void> resetPasswordEmail({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Send password reset SMS (OTP)
  Future<void> resetPasswordSms({required String phone}) async {
    await _client.auth.signInWithOtp(
      phone: phone,
    );
  }

  /// Confirm password reset after OTP
  Future<AppUser> confirmResetPassword({
    required String phone,
    required String token,
    required String newPassword,
  }) async {
    // Verify OTP and sign in temporarily
    final res = await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    final authUser = res.user;
    if (authUser == null) {
      throw AuthException('OTP verification failed');
    }
    // Update password
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    // Fetch updated profile
    final profileRes = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .single();
    userLoggedInNotifier.value = true;
    return AppUser.fromJson(profileRes);
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _client.auth.signOut();
    _tempUser = null; // Clear temp user data
    // Do NOT set userLoggedInNotifier here; let the auth state listener handle it.
  }
  
  /// Check if 2FA is enabled
  bool get is2FAEnabled => _enable2FA;
  
  /// Get current temp user (for 2FA flow)
  AppUser? get currentTempUser => _tempUser;

  /// Check for an existing session and update login state
  Future<void> checkPersistentLogin() async {
    final session = _client.auth.currentSession;
    print('Supabase session on startup: ' + session.toString());
    userLoggedInNotifier.value = session != null;
  }
}

/// Simple exception wrapper for auth errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
