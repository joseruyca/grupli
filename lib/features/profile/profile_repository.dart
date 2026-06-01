import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class ProfileRepository {
  SupabaseClient get _db => SupabaseService.client;
  String get _userId => _db.auth.currentUser!.id;

  Future<Map<String, dynamic>?> profile() async {
    final row = await _db.from('profiles').select().eq('id', _userId).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<void> updateName(String name) async {
    await _db.from('profiles').update({'full_name': name.trim(), 'updated_at': DateTime.now().toIso8601String()}).eq('id', _userId);
  }

  Future<String> uploadAvatar(XFile file) async {
    final bytes = await file.readAsBytes();
    final path = '$_userId/avatar.jpg';
    await _db.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
    final url = _db.storage.from('avatars').getPublicUrl(path);
    await _db.from('profiles').update({'avatar_url': url, 'updated_at': DateTime.now().toIso8601String()}).eq('id', _userId);
    return url;
  }

  Future<void> removeAvatar() async {
    final path = '$_userId/avatar.jpg';
    await _db.storage.from('avatars').remove([path]);
    await _db.from('profiles').update({'avatar_url': null, 'updated_at': DateTime.now().toIso8601String()}).eq('id', _userId);
  }
}
