import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabase = Supabase.instance.client;

class ProfileService {
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('profile_$userId');
    Map<String, dynamic>? parsed = cached != null
        ? (jsonDecode(cached) as Map<String, dynamic>)
        : null;
    try {
      final res = await supabase.from('profiles').select().eq('user_id', userId).maybeSingle();
      final asMap = (res is Map<String, dynamic>) ? res : null;
      if (asMap != null) {
        await prefs.setString('profile_$userId', jsonEncode(asMap));
        return asMap;
      }
      return parsed;
    } catch (_) {
      return parsed; // fallback to cache
    }
  }

  Future<void> upsertNiches(List<String> niches) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final payload = {
      'user_id': user.id,
      'niches': niches,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await supabase.from('profiles').upsert(payload, onConflict: 'user_id');
    final prefs = await SharedPreferences.getInstance();
    final key = 'profile_${user.id}';
    final existing = prefs.getString(key);
    final map = existing != null ? (jsonDecode(existing) as Map<String, dynamic>) : <String, dynamic>{};
    map['user_id'] = user.id;
    map['niches'] = niches;
    map['updated_at'] = payload['updated_at'];
    await prefs.setString(key, jsonEncode(map));
    debugPrint('[Profile] niches saved: ${niches.length}');
  }

  Future<void> upsertPlatforms(List<String> platforms) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final payload = {
      'user_id': user.id,
      'platforms': platforms,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await supabase.from('profiles').upsert(payload, onConflict: 'user_id');
    final prefs = await SharedPreferences.getInstance();
    final key = 'profile_${user.id}';
    final existing = prefs.getString(key);
    final map = existing != null ? (jsonDecode(existing) as Map<String, dynamic>) : <String, dynamic>{};
    map['user_id'] = user.id;
    map['platforms'] = platforms;
    map['updated_at'] = payload['updated_at'];
    await prefs.setString(key, jsonEncode(map));
    debugPrint('[Profile] platforms saved: ${platforms.length}');
  }

  Future<bool> isProfileComplete(String userId) async {
    final p = await fetchProfile(userId);
    if (p == null) return false;
    final niches = (p['niches'] as List?)?.cast<dynamic>() ?? const [];
    final platforms = (p['platforms'] as List?)?.cast<dynamic>() ?? const [];
    return niches.isNotEmpty && platforms.isNotEmpty;
  }
}


