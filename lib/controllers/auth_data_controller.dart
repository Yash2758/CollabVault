import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

/// Controller for handling authentication flows with Supabase.
class AuthDataController {
  /// Supabase client instance
  final SupabaseClient _client;

  bool _userLoggedIn = false;
  bool get userLoggedIn => _userLoggedIn;

  AuthDataController({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Sign up with email and password, then create a user profile in 'users' table.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
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
      'profilePictureUrl': profilePictureUrl,
    };
    await _client.from('users').insert(profileData);
    _userLoggedIn = true;
    return AppUser.fromJson(profileData);
  }

  /// Send OTP to phone number for sign-in or verification.
  Future<void> sendOtp({required String phone}) async {
    await _client.auth.signInWithOtp(
      phone: phone,
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
    _userLoggedIn = true;
    return AppUser.fromJson(profileRes);
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
    _userLoggedIn = true;
    return AppUser.fromJson(profileRes);
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _client.auth.signOut();
    _userLoggedIn = false;
  }
}

/// Simple exception wrapper for auth errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
