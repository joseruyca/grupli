import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import '../../shared/utils/safe_values.dart';

class ProfileSummary {
  final Map<String, dynamic> profile;
  final int groupsCount;
  final double balanceTotal;
  final int attendanceTotal;
  final int attendanceYes;

  const ProfileSummary({
    required this.profile,
    required this.groupsCount,
    required this.balanceTotal,
    required this.attendanceTotal,
    required this.attendanceYes,
  });

  double get attendanceRate => attendanceTotal == 0 ? 0 : attendanceYes / attendanceTotal;
}

class ProfileRepository {
  SupabaseClient get _db => SupabaseService.client;
  String get _userId => _db.auth.currentUser!.id;

  Future<Map<String, dynamic>?> profile() async {
    final row = await _db.from('profiles').select().eq('id', _userId).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<ProfileSummary> summary() async {
    final user = _db.auth.currentUser;
    final profileRow = await _ensureProfile();

    var groupsCount = 0;
    var balanceTotal = 0.0;

    try {
      final rows = await _db.rpc('get_my_groups');
      final groups = List<Map<String, dynamic>>.from(rows as List);
      groupsCount = groups.length;
      balanceTotal = groups.fold<double>(0, (sum, group) => sum + SafeValue.toDouble(group['balance']));
    } catch (_) {
      groupsCount = 0;
      balanceTotal = 0;
    }

    var attendanceTotal = 0;
    var attendanceYes = 0;

    try {
      final rows = await _db
          .from('event_attendance')
          .select('status')
          .eq('user_id', _userId);

      for (final row in List<Map<String, dynamic>>.from(rows as List)) {
        final status = (row['status'] ?? 'pending').toString();
        if (status == 'yes' || status == 'maybe' || status == 'no' || status == 'pending') {
          attendanceTotal++;
        }
        if (status == 'yes') attendanceYes++;
      }
    } catch (_) {
      attendanceTotal = 0;
      attendanceYes = 0;
    }

    return ProfileSummary(
      profile: {
        ...profileRow,
        'email': profileRow['email'] ?? user?.email,
      },
      groupsCount: groupsCount,
      balanceTotal: balanceTotal,
      attendanceTotal: attendanceTotal,
      attendanceYes: attendanceYes,
    );
  }

  Future<Map<String, dynamic>> _ensureProfile() async {
    final user = _db.auth.currentUser!;
    final existing = await profile();
    if (existing != null) return existing;

    final fallbackName = user.email?.split('@').first ?? 'Usuario';
    await _db.from('profiles').upsert({
      'id': _userId,
      'email': user.email,
      'full_name': fallbackName,
      'updated_at': DateTime.now().toIso8601String(),
    });

    final created = await profile();
    return created ?? {
      'id': _userId,
      'email': user.email,
      'full_name': fallbackName,
      'avatar_url': null,
    };
  }

  Future<void> updateName(String name) async {
    final clean = name.trim();
    if (clean.length < 2) {
      throw Exception('El nombre debe tener al menos 2 caracteres.');
    }

    await _db.from('profiles').upsert({
      'id': _userId,
      'email': _db.auth.currentUser?.email,
      'full_name': clean,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<String> uploadAvatar(XFile file) async {
    final bytes = await file.readAsBytes();
    final path = '$_userId/avatar.jpg';
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );

    final publicUrl = _db.storage.from('avatars').getPublicUrl(path);
    final url = '$publicUrl?v=$now';

    await _db.from('profiles').update({
      'avatar_url': url,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId);

    return url;
  }

  Future<void> removeAvatar() async {
    final path = '$_userId/avatar.jpg';

    try {
      await _db.storage.from('avatars').remove([path]);
    } catch (_) {
      // Si el archivo no existe, igualmente limpiamos el perfil.
    }

    await _db.from('profiles').update({
      'avatar_url': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', _userId);
  }
}
