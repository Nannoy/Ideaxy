import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabase = Supabase.instance.client;

class SupabaseAuthService {
  Future<AuthResponse> signInWithEmail({required String email, required String password}) async {
    try {
      final res = await supabase.auth.signInWithPassword(email: email, password: password);
      debugPrint('[Auth] Sign in success: userId=${res.user?.id}, hasSession=${res.session != null}');
      return res;
    } catch (e) {
      debugPrint('[Auth] Sign in error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUpWithEmail({required String email, required String password}) async {
    try {
      final res = await supabase.auth.signUp(email: email, password: password);
      debugPrint('[Auth] Sign up success: userId=${res.user?.id}, emailConfirmed=${res.user?.emailConfirmedAt != null}');
      return res;
    } catch (e) {
      debugPrint('[Auth] Sign up error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear cached profile for previously signed-in user
      // Since we don't have the user id after signOut, clear all profile_* keys
      final keys = prefs.getKeys().where((k) => k.startsWith('profile_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
      debugPrint('[Auth] Cleared cached profile keys: ${keys.length}');
    } catch (e) {
      debugPrint('[Auth] Cache clear error: $e');
    }
  }

  Session? get currentSession => supabase.auth.currentSession;
  User? get currentUser => supabase.auth.currentUser;

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('[Auth] Starting Google OAuth flow');
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );
      debugPrint('[Auth] Google OAuth initiated');
    } catch (e) {
      debugPrint('[Auth] Google OAuth error: $e');
      rethrow;
    }
  }
}

