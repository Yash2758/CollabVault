import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  AppUser? _user;
  
  // Track login state
  final ValueNotifier<bool> userLoggedInNotifier = ValueNotifier(false);
  
  // Private constructor
  AuthDataController._();
  
  // Factory constructor for async initialization
  static Future<AuthDataController> create() async {
    final controller = AuthDataController._();
    await controller._initializeSupabase();
    final isLoggedIn = await controller.checkPersistentLogin();
    controller.userLoggedInNotifier.value = isLoggedIn;
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
  }
  
  AppUser? get tempUser => _tempUser;
  AppUser? get user => _user;
  
  /// Check if user is currently logged in
  bool isUserLoggedIn() {
    return userLoggedInNotifier.value;
  }
  
  /// Store session tokens in local storage
  Future<void> _storeSessionTokens(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', session.accessToken);
    await prefs.setString('refresh_token', session.refreshToken ?? '');
  }

  /// Remove session tokens from local storage
  Future<void> _removeSessionTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
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

    if (response.session != null) {
      await _storeSessionTokens(response.session!);
    }
    userLoggedInNotifier.value = true;
    _user = AppUser.fromJson(profileData);
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
    
    if (_enable2FA) {
      userLoggedInNotifier.value = false;
      _tempUser = user;
      await sendEmailOtp(email: user.email);
    } else {
      if (response.session != null) {
        await _storeSessionTokens(response.session!);
      }
      _user = user;
      userLoggedInNotifier.value = !_enable2FA;
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
    _user = AppUser.fromJson(profileRes);
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
    if (res.session != null) {
      await _storeSessionTokens(res.session!);
    }
    userLoggedInNotifier.value = true;
    print('userLoggedInNotifier set to true after 2FA');
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
    await _removeSessionTokens();
    _tempUser = null; // Clear temp user data
    _user = null;
    userLoggedInNotifier.value = false;
  }
  
  /// Check if 2FA is enabled
  bool get is2FAEnabled => _enable2FA;
  
  /// Get current temp user (for 2FA flow)
  AppUser? get currentTempUser => _tempUser;

  /// Check for an existing session and return if user is persistently logged in (with 2FA if enabled)
  Future<bool> checkPersistentLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');
    if (accessToken != null && accessToken.isNotEmpty && refreshToken != null && refreshToken.isNotEmpty) {
      final response = await _client.auth.setSession(refreshToken);
      final session = response.session;
      final userId = session?.user.id;
      if (userId != null) {
        // Fetch user profile for temp user info (optional)
        final profileRes = await _client.from('users').select().eq('id', userId).single();
        _user = AppUser.fromJson(profileRes);
        return true;
      }
    }
    return false;
  }
}

/// Simple exception wrapper for auth errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
