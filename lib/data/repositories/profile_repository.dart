import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import '../models/profile.dart';

class ProfileRepository {
  const ProfileRepository();

  Future<Map<String, dynamic>?> fetchName(String uid) async {
    return await supabase.from('profiles').select('first_name, display_name').eq('id', uid).maybeSingle();
  }

  Future<Profile?> fetchFull(String uid) async {
    final row = await supabase
        .from('profiles')
        .select('id, first_name, middle_name, last_name, display_name, avatar_url, plan')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(row);
  }

  Future<void> updateNames(String uid, {String? firstName, String? middleName, String? lastName, String? displayName}) async {
    await supabase.from('profiles').update({
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'display_name': displayName,
    }).eq('id', uid);
  }

  Future<void> updateAvatarPath(String uid, String path) async {
    await supabase.from('profiles').update({'avatar_url': path}).eq('id', uid);
  }

  Future<String> uploadAvatar(String uid, Uint8List bytes, String ext, String contentType) async {
    final path = '$uid/avatar-${DateTime.now().millisecondsSinceEpoch}.$ext';
    await supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return path;
  }

  Future<void> removeAvatar(String path) async {
    try {
      await supabase.storage.from('avatars').remove([path]);
    } catch (_) {
      // best-effort cleanup — mirrors the .catch(() => {}) in the React app
    }
  }

  Future<String?> signedAvatarUrl(String path, {int expiresInSeconds = 60 * 60 * 24}) async {
    final res = await supabase.storage.from('avatars').createSignedUrl(path, expiresInSeconds);
    return res;
  }

  Future<Map<String, dynamic>?> exportProfile(String uid) async {
    return await supabase.from('profiles').select().eq('id', uid).maybeSingle();
  }
}
